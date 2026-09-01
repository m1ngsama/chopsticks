#!/usr/bin/env python3
"""Reproducible, offline performance benchmark for chopsticks.

The benchmark uses Vim's own ``--startuptime`` clock for startup latency and
the platform ``time`` utility, when available, for peak resident memory.  It
has no third-party Python dependencies and never installs plugins or accesses
the network.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import math
import os
import platform
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import Any, Dict, List, Optional, Sequence, Tuple


ROOT = Path(__file__).resolve().parent.parent
VIMRC = ROOT / ".vimrc"
FIXTURE_BYTES = 1024 * 1024
DEFAULT_SAMPLES = 21
MINIMUM_SAMPLES = 20
OPTIONAL_TOOLS = (
    "fd",
    "fzf",
    "git",
    "glow",
    "lazygit",
    "markdownlint",
    "marksman",
    "pandoc",
    "pngpaste",
    "prettier",
    "rg",
)


class BenchmarkError(RuntimeError):
    """Raised when a sample cannot be measured reliably."""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Measure chopsticks startup and Markdown-open latency."
    )
    parser.add_argument(
        "--vim",
        default=os.environ.get("CHOPSTICKS_TEST_VIM", "vim"),
        help="Vim executable (default: CHOPSTICKS_TEST_VIM or vim)",
    )
    parser.add_argument(
        "--home",
        type=Path,
        help="HOME containing an existing vim-plug installation; the default is isolated",
    )
    parser.add_argument(
        "--samples",
        type=int,
        default=DEFAULT_SAMPLES,
        help=(
            f"warm samples per workload (default: {DEFAULT_SAMPLES}, "
            f"minimum: {MINIMUM_SAMPLES})"
        ),
    )
    parser.add_argument(
        "--cold-samples",
        type=int,
        default=3,
        help="cold samples per workload when --cold-cache-command is set (default: 3)",
    )
    parser.add_argument(
        "--cold-cache-command",
        help="explicit command run before every cold sample, parsed with shell-like quoting",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=30.0,
        help="timeout for one Vim invocation in seconds (default: 30)",
    )
    parser.add_argument(
        "--json",
        dest="json_path",
        type=Path,
        help="write the complete machine-readable report to this path",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="exit non-zero when a regression budget is exceeded",
    )
    # Redlines carry roughly twice the slowest measurement observed on hosted
    # runners, because those runners differ by more than 1.6x between hosts:
    # three consecutive runs of one commit read 105 ms of warm no-file startup
    # where an earlier run of the same commit read 64 ms. Budgets tight enough
    # to fail on the slower host cannot tell a regression from the machine.
    # They stay tight enough for what they are for: the long-line regression
    # this suite caught overshot its redline by a factor of 65.
    parser.add_argument(
        "--startup-p95-budget-ms",
        type=float,
        default=250.0,
        help="warm no-file startup p95 redline (default: 250 ms)",
    )
    parser.add_argument(
        "--cold-startup-p95-budget-ms",
        type=float,
        default=500.0,
        help="cold no-file startup p95 redline (default: 500 ms)",
    )
    parser.add_argument(
        "--markdown-p95-budget-ms",
        type=float,
        default=900.0,
        help="warm Markdown-open p95 redline (default: 900 ms)",
    )
    parser.add_argument(
        "--pathological-p95-budget-ms",
        type=float,
        default=1800.0,
        help="many-fence Markdown p95 redline (default: 1800 ms)",
    )
    parser.add_argument(
        "--runtime-bytes-budget",
        type=int,
        default=2 * 1024 * 1024,
        help="tracked runtime configuration redline (default: 2 MiB)",
    )
    args = parser.parse_args()

    if args.samples < MINIMUM_SAMPLES:
        parser.error(f"--samples must be at least {MINIMUM_SAMPLES}")
    if args.cold_samples < 1:
        parser.error("--cold-samples must be positive")
    if not math.isfinite(args.timeout) or args.timeout <= 0:
        parser.error("--timeout must be positive")
    for name in (
        "startup_p95_budget_ms",
        "cold_startup_p95_budget_ms",
        "markdown_p95_budget_ms",
        "pathological_p95_budget_ms",
    ):
        value = getattr(args, name)
        if not math.isfinite(value) or value <= 0:
            parser.error("budget values must be positive")
    if args.runtime_bytes_budget <= 0:
        parser.error("budget values must be positive")
    return args


def run_text(command: Sequence[str], cwd: Path = ROOT) -> str:
    completed = subprocess.run(
        list(command),
        cwd=str(cwd),
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    return completed.stdout.strip()


def git_metadata() -> Dict[str, Any]:
    try:
        commit = run_text(["git", "rev-parse", "HEAD"])
        dirty = bool(run_text(["git", "status", "--porcelain"]))
    except (FileNotFoundError, subprocess.CalledProcessError):
        commit = "unknown"
        dirty = None
    return {"commit": commit, "dirty": dirty}


def cpu_model() -> str:
    if sys.platform == "darwin":
        try:
            return run_text(["sysctl", "-n", "machdep.cpu.brand_string"])
        except (FileNotFoundError, subprocess.CalledProcessError):
            pass
    cpuinfo = Path("/proc/cpuinfo")
    if cpuinfo.is_file():
        for line in cpuinfo.read_text(encoding="utf-8", errors="replace").splitlines():
            if line.lower().startswith("model name") and ":" in line:
                return line.split(":", 1)[1].strip()
    return platform.processor() or "unknown"


def total_memory_mib() -> Optional[int]:
    try:
        pages = os.sysconf("SC_PHYS_PAGES")
        page_size = os.sysconf("SC_PAGE_SIZE")
    except (AttributeError, OSError, ValueError):
        return None
    if not isinstance(pages, int) or not isinstance(page_size, int):
        return None
    return round(pages * page_size / (1024 * 1024))


def system_metadata(vim: str) -> Dict[str, Any]:
    try:
        version_lines = run_text([vim, "--version"]).splitlines()
    except (FileNotFoundError, subprocess.CalledProcessError) as error:
        raise BenchmarkError(f"cannot execute Vim: {vim}: {error}") from error
    if not version_lines:
        raise BenchmarkError(f"{vim} --version returned no output")
    executable = str(Path(shutil.which(vim) or vim).resolve())
    user_home = str(Path.home().resolve())
    if executable == user_home or executable.startswith(user_home + os.sep):
        executable = "$HOME" + executable[len(user_home) :]
    return {
        "os": platform.platform(),
        "architecture": platform.machine() or "unknown",
        "cpu": cpu_model(),
        "logical_cpus": os.cpu_count(),
        "memory_mib": total_memory_mib(),
        "python": platform.python_version(),
        "vim": version_lines[0],
        "vim_executable": executable,
        "tools": {tool: shutil.which(tool) is not None for tool in OPTIONAL_TOOLS},
    }


def runtime_configuration_bytes() -> Tuple[int, List[Dict[str, Any]]]:
    runtime_paths = [VIMRC]
    entries = []
    for path in runtime_paths:
        size = path.stat().st_size
        entries.append({"path": str(path.relative_to(ROOT)), "bytes": size})
    return sum(entry["bytes"] for entry in entries), entries


def write_repeated_fixture(path: Path, prefix: bytes, pattern: bytes) -> None:
    remaining = FIXTURE_BYTES - len(prefix)
    if remaining < 0:
        raise BenchmarkError("fixture prefix exceeds requested size")
    repeats, tail = divmod(remaining, len(pattern))
    path.write_bytes(prefix + pattern * repeats + pattern[:tail])


def create_fixtures(directory: Path) -> Dict[str, Optional[Path]]:
    markdown = directory / "one-mib.md"
    long_line = directory / "long-line.md"
    many_fences = directory / "many-fences.md"
    prose = (
        b"A representative prose line explains one idea with enough words to "
        b"exercise wrapping, spelling, links, and ordinary Markdown syntax.\n"
    )
    list_item = (
        b"- [ ] A realistic task links to [documentation](https://example.invalid/) "
        b"and includes `inline code`.\n"
    )
    write_repeated_fixture(
        markdown,
        b"# One MiB Markdown performance fixture\n\n",
        (
            b"## Representative section\n\n"
            + prose * 72
            + b"\n"
            + list_item * 8
            + b"\n"
            b"```vim\nlet g:fixture = 'syntax highlighting remains enabled'\n```\n\n"
        ),
    )
    write_repeated_fixture(
        long_line,
        b"# Pathological long line\n\n",
        b"word-with-markdown-*syntax*-and-`code` ",
    )
    # Replace every newline after the heading so the payload is one long line.
    data = long_line.read_bytes()
    heading_end = data.find(b"\n\n") + 2
    long_line.write_bytes(data[:heading_end] + data[heading_end:].replace(b"\n", b" "))
    # Preserve the original high-density syntax stress case separately: it is
    # useful for catching nonlinear fenced-language behavior, but is not a
    # representative one-MiB document and therefore has its own budget.
    write_repeated_fixture(
        many_fences,
        b"# Pathological fenced-code density\n\n",
        (
            b"## Section\n\n"
            b"- [ ] prose with `inline code`, **emphasis**, and a link.\n\n"
            b"```vim\nlet g:fixture = 'thousands of fenced blocks'\n```\n\n"
        ),
    )
    return {
        "startup": None,
        "markdown_1mib": markdown,
        "markdown_long_line": long_line,
        "markdown_many_fences": many_fences,
    }


def percentile(values: Sequence[float], percentage: float) -> float:
    ordered = sorted(values)
    index = max(0, math.ceil(percentage * len(ordered)) - 1)
    return ordered[index]


def summarize(values: Sequence[float]) -> Dict[str, Any]:
    if not values:
        raise BenchmarkError("cannot summarize an empty sample set")
    return {
        "samples": len(values),
        "min": round(min(values), 3),
        "p50": round(percentile(values, 0.50), 3),
        "p95": round(percentile(values, 0.95), 3),
        "p99": round(percentile(values, 0.99), 3),
        "max": round(max(values), 3),
        "values": [round(value, 3) for value in values],
    }


def parse_startuptime(path: Path) -> float:
    last_total = None
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        match = re.match(r"^\s*(\d+(?:\.\d+)?)\s+.*:", line)
        if match:
            last_total = float(match.group(1))
    if last_total is None:
        raise BenchmarkError(f"Vim produced no timing rows in {path}")
    return last_total


def vim_data_dir(home: Path, platform_name: Optional[str] = None) -> Path:
    """Return Vim's native per-user runtime root for the current platform."""
    platform_name = os.name if platform_name is None else platform_name
    return home / ("vimfiles" if platform_name == "nt" else ".vim")


def parse_plugin_self_times(path: Path, home: Path) -> Dict[str, float]:
    """Return exclusive source time grouped by vim-plug directory."""
    plugin_root = str(vim_data_dir(home) / "plugged") + os.sep
    timings: Dict[str, float] = {}
    pattern = re.compile(
        r"^\s*\d+(?:\.\d+)?\s+"
        r"(\d+(?:\.\d+)?)"
        r"(?:\s+(\d+(?:\.\d+)?))?:\s+sourcing\s+(.+)$"
    )
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        match = pattern.match(line)
        if not match:
            continue
        source = match.group(3)
        if not source.startswith(plugin_root):
            continue
        relative = source[len(plugin_root) :]
        plugin = relative.split(os.sep, 1)[0]
        if not plugin:
            continue
        # Vim emits inclusive and exclusive durations for nested sources. Use
        # exclusive time so a child script is never counted twice.
        duration = float(match.group(2) or match.group(1))
        timings[plugin] = timings.get(plugin, 0.0) + duration
    return timings


def timed_command(
    command: Sequence[str],
    platform_name: Optional[str] = None,
    time_binary: Path = Path("/usr/bin/time"),
) -> Tuple[List[str], str]:
    platform_name = sys.platform if platform_name is None else platform_name
    if not time_binary.is_file():
        return list(command), "none"
    if platform_name == "darwin":
        return [str(time_binary), "-l", *command], "darwin"
    if platform_name.startswith(("linux", "cygwin")):
        return [
            str(time_binary),
            "-f",
            "__CHOPSTICKS_RSS_KIB__=%M",
            *command,
        ], "gnu"
    # BSD and other time implementations use incompatible flags. Latency is
    # still valid without wrapping Vim; only peak RSS is omitted.
    return list(command), "none"


def parse_peak_rss_kib(stderr: str, time_format: str) -> Optional[float]:
    if time_format == "darwin":
        match = re.search(r"(?m)^\s*(\d+)\s+maximum resident set size\s*$", stderr)
        return round(int(match.group(1)) / 1024, 3) if match else None
    if time_format == "gnu":
        match = re.search(r"(?m)^__CHOPSTICKS_RSS_KIB__=(\d+)\s*$", stderr)
        return float(match.group(1)) if match else None
    return None


def benchmark_environment(home: Path) -> Dict[str, str]:
    environment = os.environ.copy()
    environment.update(
        {
            "HOME": str(home),
            "USERPROFILE": str(home),
            "XDG_CACHE_HOME": str(home / ".cache"),
            "XDG_CONFIG_HOME": str(home / ".config"),
            "XDG_DATA_HOME": str(home / ".local" / "share"),
            "XDG_STATE_HOME": str(home / ".local" / "state"),
            "TERM": "xterm-256color",
            "COLORTERM": "truecolor",
            "TERM_PROGRAM": "WezTerm",
        }
    )
    for name in (
        "DISPLAY",
        "EXINIT",
        "GHOSTTY_RESOURCES_DIR",
        "GVIMINIT",
        "KITTY_WINDOW_ID",
        "SSH_CLIENT",
        "SSH_CONNECTION",
        "SSH_TTY",
        "VIMINIT",
        "WAYLAND_DISPLAY",
        "WEZTERM_PANE",
        "WT_SESSION",
    ):
        environment.pop(name, None)
    return environment


def run_sample(
    vim: str,
    home: Path,
    target: Optional[Path],
    run_directory: Path,
    label: str,
    timeout: float,
) -> Dict[str, Any]:
    timing_path = run_directory / f"{label}.startuptime"
    command = [
        vim,
        "-Nu",
        str(VIMRC),
        "-i",
        "NONE",
        "-n",
        "-es",
        "--cmd",
        "let g:chopsticks_local_config = ''",
        "--cmd",
        "let g:chopsticks_auto_lint = 0",
        "--cmd",
        "let g:chopsticks_icons = 1",
        "--cmd",
        "let g:chopsticks_system_clipboard = 0",
        "--cmd",
        "let g:chopsticks_transparent_background = 0",
        "--cmd",
        "let g:chopsticks_ui_density = 'balanced'",
        "--startuptime",
        str(timing_path),
    ]
    if target is not None:
        command.append(str(target))
    # A zero-delay timer quits after every VimEnter handler has completed, so
    # the measurement includes dashboard/plugin startup without user input.
    command.extend(
        ["-c", "autocmd VimEnter * ++once call timer_start(0, {-> execute('qall!')})"]
    )
    measured_command, time_format = timed_command(command)
    started = time.perf_counter()
    try:
        completed = subprocess.run(
            measured_command,
            cwd=str(ROOT),
            env=benchmark_environment(home),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=timeout,
            check=False,
        )
    except subprocess.TimeoutExpired as error:
        raise BenchmarkError(f"Vim sample timed out after {timeout:g}s: {label}") from error
    wall_ms = (time.perf_counter() - started) * 1000
    if completed.returncode != 0:
        details = (completed.stderr or completed.stdout).strip()
        raise BenchmarkError(
            f"Vim sample failed ({completed.returncode}): {label}"
            + (f"\n{details}" if details else "")
        )
    return {
        "startup_ms": parse_startuptime(timing_path),
        "wall_ms": wall_ms,
        "peak_rss_kib": parse_peak_rss_kib(completed.stderr, time_format),
        "plugin_self_ms": parse_plugin_self_times(timing_path, home),
    }


def run_cache_command(command: str, timeout: float) -> None:
    try:
        arguments = shlex.split(command)
    except ValueError as error:
        raise BenchmarkError(f"cannot parse cold-cache command: {error}") from error
    if not arguments:
        raise BenchmarkError("--cold-cache-command is empty")
    try:
        completed = subprocess.run(
            arguments,
            cwd=str(ROOT),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=timeout,
            check=False,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired) as error:
        raise BenchmarkError(f"cold-cache command failed: {error}") from error
    if completed.returncode != 0:
        details = (completed.stderr or completed.stdout).strip()
        raise BenchmarkError(
            f"cold-cache command exited {completed.returncode}"
            + (f": {details}" if details else "")
        )


def collect_workload(
    name: str,
    target: Optional[Path],
    samples: int,
    vim: str,
    home: Path,
    run_directory: Path,
    timeout: float,
    cold_cache_command: Optional[str] = None,
) -> Dict[str, Any]:
    startup_values: List[float] = []
    wall_values: List[float] = []
    rss_values: List[float] = []
    plugin_values: Dict[str, List[float]] = {}
    for index in range(samples):
        if cold_cache_command:
            run_cache_command(cold_cache_command, timeout)
        sample = run_sample(
            vim, home, target, run_directory, f"{name}-{index + 1}", timeout
        )
        startup_values.append(float(sample["startup_ms"]))
        wall_values.append(float(sample["wall_ms"]))
        if sample["peak_rss_kib"] is not None:
            rss_values.append(float(sample["peak_rss_kib"]))
        sample_plugins = sample["plugin_self_ms"]
        for plugin in set(plugin_values) | set(sample_plugins):
            plugin_values.setdefault(plugin, [0.0] * index)
            plugin_values[plugin].append(float(sample_plugins.get(plugin, 0.0)))

    startup_summary = summarize(startup_values)
    plugin_profile = []
    for plugin, values in plugin_values.items():
        timing = summarize(values)
        shares = [
            (plugin_ms / startup_ms * 100) if startup_ms else 0.0
            for plugin_ms, startup_ms in zip(values, startup_values)
        ]
        plugin_profile.append(
            {
                "plugin": plugin,
                "self_ms": timing,
                "share_of_startup_pct": summarize(shares),
            }
        )
    plugin_profile.sort(
        key=lambda item: (-item["self_ms"]["p50"], item["plugin"])
    )
    return {
        "startup_ms": startup_summary,
        "wall_ms": summarize(wall_values),
        "peak_rss_kib": summarize(rss_values) if rss_values else None,
        "plugin_profile": plugin_profile,
    }


def declared_plugin_pins() -> Dict[str, str]:
    """Return vim-plug directory names and their declared commit pins."""
    pins = {}
    pattern = re.compile(
        r"^\s*Plug\s+'([^']+)'.*'commit'\s*:\s*'([0-9a-f]{40})'"
    )
    for line in VIMRC.read_text(encoding="utf-8").splitlines():
        match = pattern.match(line)
        if not match:
            continue
        name = re.split(r"[/\\]", match.group(1).rstrip("/\\"))[-1]
        name = re.sub(r"\.git$", "", name)
        if name in pins:
            raise BenchmarkError(
                f"duplicate vim-plug directory name in .vimrc: {name}"
            )
        pins[name] = match.group(2)
    return pins


def profile_metadata(home: Path, isolated: bool) -> Dict[str, Any]:
    data_dir = vim_data_dir(home)
    plugin_root = data_dir / "plugged"
    installed_plugins = (
        sorted(path.name for path in plugin_root.iterdir() if path.is_dir())
        if plugin_root.is_dir()
        else []
    )
    declared_plugins = declared_plugin_pins()
    declared_names = set(declared_plugins)
    installed_names = set(installed_plugins)
    missing_plugins = sorted(declared_names - installed_names)
    unverifiable_plugins = []
    mismatched_plugins = []
    dirty_plugins = []
    plugin_revisions = []
    for plugin in sorted(declared_plugins):
        expected = declared_plugins[plugin]
        installed_commit = None
        if plugin in missing_plugins:
            state = "missing"
        else:
            try:
                installed_commit = run_text(
                    ["git", "-C", str(plugin_root / plugin), "rev-parse", "HEAD"]
                )
            except (FileNotFoundError, subprocess.CalledProcessError):
                state = "unverifiable"
                unverifiable_plugins.append(plugin)
            else:
                if not re.fullmatch(r"[0-9a-f]{40}", installed_commit):
                    state = "unverifiable"
                    unverifiable_plugins.append(plugin)
                else:
                    try:
                        worktree_status = run_text(
                            [
                                "git",
                                "-C",
                                str(plugin_root / plugin),
                                "status",
                                "--porcelain=v1",
                                "--untracked-files=all",
                                "--ignore-submodules=none",
                            ]
                        )
                    except (FileNotFoundError, subprocess.CalledProcessError):
                        state = "unverifiable"
                        unverifiable_plugins.append(plugin)
                    else:
                        # vim-plug's post-install helptags step generates this
                        # harmless, deterministic file in plugins that do not
                        # commit one. Every tracked/index change and every
                        # other untracked path still makes the profile dirty.
                        dirty = any(
                            line != "?? doc/tags"
                            for line in worktree_status.splitlines()
                        )
                        if dirty:
                            dirty_plugins.append(plugin)
                        if installed_commit != expected:
                            state = "mismatched-dirty" if dirty else "mismatched"
                            mismatched_plugins.append(
                                {
                                    "plugin": plugin,
                                    "expected_commit": expected,
                                    "installed_commit": installed_commit,
                                }
                            )
                        else:
                            state = "dirty" if dirty else "matched"
        plugin_revisions.append(
            {
                "plugin": plugin,
                "expected_commit": expected,
                "installed_commit": installed_commit,
                "state": state,
            }
        )
    vim_plug = (data_dir / "autoload" / "plug.vim").is_file()
    return {
        "name": "isolated-core" if isolated else "provided-home",
        "home": "temporary" if isolated else "provided",
        "vim_plug": vim_plug,
        "declared_plugins": len(declared_plugins),
        "installed_declared_plugins": len(declared_names & installed_names),
        "installed_plugin_directories": len(installed_plugins),
        "missing_plugins": missing_plugins,
        "unverifiable_plugins": unverifiable_plugins,
        "mismatched_plugins": mismatched_plugins,
        "dirty_plugins": dirty_plugins,
        "plugin_revisions": plugin_revisions,
        "profile_complete": isolated
        or (
            vim_plug
            and not missing_plugins
            and not unverifiable_plugins
            and not mismatched_plugins
            and not dirty_plugins
        ),
        "network_access": "not used",
        "local_config": "disabled",
    }


def workload_budget(name: str, args: argparse.Namespace) -> float:
    if name == "startup":
        return args.startup_p95_budget_ms
    if name == "markdown_many_fences":
        return args.pathological_p95_budget_ms
    return args.markdown_p95_budget_ms


def violations_for(report: Dict[str, Any], args: argparse.Namespace) -> List[str]:
    violations = []
    profile = report["profile"]
    if profile["name"] == "provided-home":
        if not profile["vim_plug"]:
            violations.append("provided home is missing vim-plug")
        if profile["missing_plugins"]:
            missing = ", ".join(profile["missing_plugins"])
            violations.append(
                f"provided home is missing {len(profile['missing_plugins'])} "
                f"declared plugin(s): {missing}"
            )
        if profile["unverifiable_plugins"]:
            unverifiable = ", ".join(profile["unverifiable_plugins"])
            violations.append(
                "provided home has unverifiable plugin revision(s): "
                f"{unverifiable}"
            )
        if profile["dirty_plugins"]:
            dirty = ", ".join(profile["dirty_plugins"])
            violations.append(
                f"provided home has dirty plugin worktree(s): {dirty}"
            )
        for mismatch in profile["mismatched_plugins"]:
            violations.append(
                f"provided home plugin {mismatch['plugin']} is at "
                f"{mismatch['installed_commit']}, expected "
                f"{mismatch['expected_commit']}"
            )
    for name, result in report["workloads"]["warm"].items():
        actual = result["startup_ms"]["p95"]
        budget = workload_budget(name, args)
        if actual > budget:
            violations.append(
                f"{name} warm startup p95 {actual:.3f} ms exceeds {budget:.3f} ms"
            )
        for plugin in result["plugin_profile"]:
            share = plugin["share_of_startup_pct"]["p50"]
            if share > 20:
                violations.append(
                    f"{name} plugin {plugin['plugin']} uses {share:.1f}% of "
                    "warm startup at p50 (budget: 20%)"
                )
    cold = report["workloads"].get("cold")
    if cold:
        actual = cold["startup"]["startup_ms"]["p95"]
        budget = args.cold_startup_p95_budget_ms
        if actual > budget:
            violations.append(
                f"cold startup p95 {actual:.3f} ms exceeds "
                f"{budget:.3f} ms"
            )
    runtime_bytes = report["runtime_configuration"]["bytes"]
    if runtime_bytes > args.runtime_bytes_budget:
        violations.append(
            f"runtime configuration {runtime_bytes} bytes exceeds "
            f"{args.runtime_bytes_budget} bytes"
        )
    return violations


def print_report(report: Dict[str, Any]) -> None:
    print(
        f"chopsticks performance — {report['git']['commit'][:12]}"
        f"{' (dirty)' if report['git']['dirty'] else ''}"
    )
    print(
        f"profile: {report['profile']['name']}, "
        f"plugins: {report['profile']['declared_plugins']} declared / "
        f"{report['profile']['installed_declared_plugins']} installed, "
        f"complete: {'yes' if report['profile']['profile_complete'] else 'no'}, "
        f"Vim: {report['system']['vim']}"
    )
    print()
    print("cache  workload              n     p50     p95     p99   peak RSS   budget")
    print("-----  --------------------  --  ------  ------  ------  ---------  -------")
    for cache_name in ("warm", "cold"):
        workloads = report["workloads"].get(cache_name)
        if not workloads:
            continue
        for name, result in workloads.items():
            timing = result["startup_ms"]
            rss = result["peak_rss_kib"]
            rss_text = f"{rss['max'] / 1024:7.1f} M" if rss else "      n/a"
            if cache_name == "cold":
                budget_text = (
                    f"{report['budgets']['cold_startup']:5.0f} ms"
                    if name == "startup"
                    else "    n/a"
                )
            else:
                budget_text = f"{report['budgets'][name]:5.0f} ms"
            print(
                f"{cache_name:5}  {name:20}  {timing['samples']:2d}  "
                f"{timing['p50']:6.1f}  {timing['p95']:6.1f}  "
                f"{timing['p99']:6.1f}  {rss_text}  {budget_text}"
            )
            dominant = [
                plugin
                for plugin in result["plugin_profile"]
                if plugin["share_of_startup_pct"]["p50"] > 20
            ]
            for plugin in dominant:
                print(
                    "       ↳ "
                    f"{plugin['plugin']} "
                    f"{plugin['self_ms']['p50']:.1f} ms / "
                    f"{plugin['share_of_startup_pct']['p50']:.1f}%"
                )
    if report["workloads"].get("cold") is None:
        print("\ncold cache: not collected (pass --cold-cache-command explicitly)")
    print(
        f"runtime configuration: {report['runtime_configuration']['bytes']} bytes"
    )
    if report["violations"]:
        print("\nregressions:")
        for violation in report["violations"]:
            print(f"  - {violation}")
    else:
        print("\nregression budgets: PASS")


def write_json(path: Path, report: Dict[str, Any]) -> None:
    # Keep the final path lexical: resolving it would follow a pre-existing
    # symlink and could overwrite its target when the documented /tmp path is
    # used on a shared machine.  os.replace() should replace the directory
    # entry itself instead.
    path = Path(os.path.abspath(os.fspath(path.expanduser())))
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary: Optional[Path] = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            dir=str(path.parent),
            prefix=f".{path.name}.tmp-",
            delete=False,
        ) as output:
            temporary = Path(output.name)
            json.dump(report, output, indent=2, sort_keys=True)
            output.write("\n")
            output.flush()
            os.fsync(output.fileno())
        os.replace(temporary, path)
    except BaseException:
        if temporary is not None:
            try:
                temporary.unlink()
            except FileNotFoundError:
                pass
        raise
    print(f"machine report: {path}")


def main() -> int:
    args = parse_args()
    if not VIMRC.is_file():
        raise BenchmarkError(f"missing runtime configuration: {VIMRC}")

    with tempfile.TemporaryDirectory(prefix="chopsticks-benchmark-") as temporary:
        temp_root = Path(temporary)
        isolated = args.home is None
        if args.home:
            home = args.home.expanduser().resolve()
            if not home.is_dir():
                raise BenchmarkError(f"--home is not an existing directory: {home}")
        else:
            home = temp_root / "home"
            home.mkdir(parents=True)
        fixtures = create_fixtures(temp_root)
        run_directory = temp_root / "runs"
        run_directory.mkdir()

        # Populate filesystem caches without including the priming process in
        # warm statistics. Cold measurements, when requested, evict caches
        # again before every recorded sample.
        for name, target in fixtures.items():
            run_sample(
                args.vim,
                home,
                target,
                run_directory,
                f"prime-{name}",
                args.timeout,
            )

        warm = {
            name: collect_workload(
                name,
                target,
                args.samples,
                args.vim,
                home,
                run_directory,
                args.timeout,
            )
            for name, target in fixtures.items()
        }
        cold = None
        if args.cold_cache_command:
            cold = {
                name: collect_workload(
                    f"cold-{name}",
                    target,
                    args.cold_samples,
                    args.vim,
                    home,
                    run_directory,
                    args.timeout,
                    args.cold_cache_command,
                )
                for name, target in fixtures.items()
            }

        runtime_bytes, runtime_entries = runtime_configuration_bytes()
        report: Dict[str, Any] = {
            "schema_version": 1,
            "generated_at": dt.datetime.now(dt.timezone.utc).isoformat(),
            "git": git_metadata(),
            "system": system_metadata(args.vim),
            "profile": profile_metadata(home, isolated),
            "method": {
                "clock": "Vim --startuptime, including VimEnter autocommands",
                "environment_profile": (
                    "local truecolor terminal, icons on, clipboard off, "
                    "manual lint, opaque balanced UI"
                ),
                "percentile": "nearest-rank",
                "warmup_samples_per_workload": 1,
                "warm_samples_per_workload": args.samples,
                "cold_samples_per_workload": (
                    args.cold_samples if args.cold_cache_command else 0
                ),
                "cold_cache_command": args.cold_cache_command,
                "fixture_bytes": FIXTURE_BYTES,
            },
            "budgets": {
                "startup": args.startup_p95_budget_ms,
                "cold_startup": args.cold_startup_p95_budget_ms,
                "markdown_1mib": args.markdown_p95_budget_ms,
                "markdown_long_line": args.markdown_p95_budget_ms,
                "markdown_many_fences": args.pathological_p95_budget_ms,
                "runtime_configuration_bytes": args.runtime_bytes_budget,
            },
            "runtime_configuration": {
                "bytes": runtime_bytes,
                "files": runtime_entries,
            },
            "workloads": {"warm": warm, "cold": cold},
            "violations": [],
        }
        report["violations"] = violations_for(report, args)
        print_report(report)
        if args.json_path:
            write_json(args.json_path, report)
        return 1 if args.check and report["violations"] else 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (BenchmarkError, OSError) as error:
        print(f"benchmark error: {error}", file=sys.stderr)
        raise SystemExit(2) from error
