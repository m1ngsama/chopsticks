"""Unit tests for the dependency-free Vim benchmark harness."""

from __future__ import annotations

import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parent.parent
BENCHMARK_PATH = ROOT / "scripts" / "benchmark-vim.py"
SPEC = importlib.util.spec_from_file_location("chopsticks_benchmark", BENCHMARK_PATH)
if SPEC is None or SPEC.loader is None:  # pragma: no cover - importlib invariant
    raise RuntimeError(f"cannot load benchmark module from {BENCHMARK_PATH}")
benchmark = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(benchmark)


class StatisticsTests(unittest.TestCase):
    """Verify the benchmark's published summary semantics."""

    def test_percentile_uses_nearest_rank(self) -> None:
        """Nearest-rank percentiles select deterministic observed values."""
        values = list(range(20, 0, -1))

        self.assertEqual(10, benchmark.percentile(values, 0.50))
        self.assertEqual(19, benchmark.percentile(values, 0.95))
        self.assertEqual(20, benchmark.percentile(values, 0.99))

        # With seven samples nearest-rank p95 is deliberately the maximum.
        self.assertEqual(13, benchmark.percentile([7, 8, 9, 10, 11, 12, 13], 0.95))

    def test_summarize_rejects_an_empty_sample(self) -> None:
        """An empty run cannot silently produce a misleading report."""
        with self.assertRaises(benchmark.BenchmarkError):
            benchmark.summarize([])

    def test_summarize_uses_nearest_rank_for_every_percentile(self) -> None:
        """Even sample counts do not interpolate p50 differently from p95."""
        summary = benchmark.summarize(list(range(1, 21)))

        self.assertEqual(10, summary["p50"])
        self.assertEqual(19, summary["p95"])
        self.assertEqual(20, summary["p99"])


class ArgumentTests(unittest.TestCase):
    """Keep documented command-line budgets wired to report semantics."""

    def test_cold_startup_budget_has_a_default_and_an_override(self) -> None:
        """The cold redline is independently configurable from warm startup."""
        with mock.patch.object(sys, "argv", ["benchmark-vim.py", "--samples", "20"]):
            defaults = benchmark.parse_args()
        with mock.patch.object(
            sys,
            "argv",
            [
                "benchmark-vim.py",
                "--samples",
                "20",
                "--cold-startup-p95-budget-ms",
                "275.5",
            ],
        ):
            overridden = benchmark.parse_args()

        self.assertEqual(500.0, defaults.cold_startup_p95_budget_ms)
        self.assertEqual(275.5, overridden.cold_startup_p95_budget_ms)

    def test_collected_cold_startup_can_violate_its_redline(self) -> None:
        """A slow explicit cold run makes --check fail instead of staying advisory."""
        report = {
            "profile": {"name": "isolated-core"},
            "workloads": {
                "warm": {},
                "cold": {"startup": {"startup_ms": {"p95": 201.0}}},
            },
            "runtime_configuration": {"bytes": 1},
        }
        args = mock.Mock(
            cold_startup_p95_budget_ms=200.0,
            runtime_bytes_budget=2,
        )

        violations = benchmark.violations_for(report, args)

        self.assertEqual(
            ["cold startup p95 201.000 ms exceeds 200.000 ms"], violations
        )

    def test_non_finite_timeout_and_budgets_are_rejected(self) -> None:
        """NaN and infinity cannot disable checks or produce invalid JSON."""
        cases = [
            ["--timeout", "nan"],
            ["--startup-p95-budget-ms", "inf"],
            ["--cold-startup-p95-budget-ms", "-inf"],
        ]
        for arguments in cases:
            with self.subTest(arguments=arguments), mock.patch.object(
                sys, "argv", ["benchmark-vim.py", "--samples", "20", *arguments]
            ), mock.patch("sys.stderr"):
                with self.assertRaises(SystemExit):
                    benchmark.parse_args()


class CacheCommandTests(unittest.TestCase):
    """Give malformed manual cache commands a concise benchmark error."""

    def test_unbalanced_quoting_is_rejected_without_a_traceback(self) -> None:
        """shlex parse errors use the harness's normal failure path."""
        with self.assertRaisesRegex(
            benchmark.BenchmarkError, "cannot parse cold-cache command"
        ):
            benchmark.run_cache_command("'unterminated", 1.0)


class FixtureTests(unittest.TestCase):
    """Verify benchmark inputs stay comparable across revisions."""

    def test_markdown_fixtures_are_exact_and_distinct(self) -> None:
        """All fixtures are 1 MiB and model intentionally different shapes."""
        with tempfile.TemporaryDirectory() as temporary:
            fixtures = benchmark.create_fixtures(Path(temporary))

            self.assertIsNone(fixtures["startup"])
            paths = {name: path for name, path in fixtures.items() if path is not None}
            self.assertEqual(
                {
                    "markdown_1mib",
                    "markdown_long_line",
                    "markdown_many_fences",
                },
                set(paths),
            )
            for path in paths.values():
                self.assertEqual(benchmark.FIXTURE_BYTES, path.stat().st_size)

            representative = paths["markdown_1mib"].read_bytes()
            many_fences = paths["markdown_many_fences"].read_bytes()
            representative_fences = representative.count(b"```vim")
            pathological_fences = many_fences.count(b"```vim")

            self.assertGreater(representative_fences, 0)
            self.assertGreater(pathological_fences, representative_fences * 20)
            self.assertGreater(representative.count(b"representative prose line"), 100)

            long_line = paths["markdown_long_line"].read_bytes()
            heading, payload = long_line.split(b"\n\n", 1)
            self.assertEqual(b"# Pathological long line", heading)
            self.assertNotIn(b"\n", payload)


class StartuptimeParsingTests(unittest.TestCase):
    """Exercise parsing against representative Vim timing rows."""

    def test_parse_startuptime_returns_the_last_clock_value(self) -> None:
        """The final timing row is the end-to-end startup measurement."""
        content = """\
times in msec
 clock   self+sourced   self:  sourced script
000.003  000.003: --- VIM STARTING ---
012.500  004.000  003.000: sourcing /tmp/example.vim
019.875  007.375: VimEnter autocommands
not a timing row: ignored
"""
        with tempfile.TemporaryDirectory() as temporary:
            timing = Path(temporary) / "startup.log"
            timing.write_text(content, encoding="utf-8")
            self.assertEqual(19.875, benchmark.parse_startuptime(timing))

    def test_parse_startuptime_rejects_a_log_without_rows(self) -> None:
        """Truncated or malformed Vim output fails closed."""
        with tempfile.TemporaryDirectory() as temporary:
            timing = Path(temporary) / "startup.log"
            timing.write_text("times in msec\nno measurements\n", encoding="utf-8")
            with self.assertRaises(benchmark.BenchmarkError):
                benchmark.parse_startuptime(timing)

    def test_plugin_parser_aggregates_exclusive_time_by_plugin(self) -> None:
        """Plugin totals use exclusive time and ignore paths outside vim-plug."""
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            home = root / "home with spaces"
            # The parser resolves the plugin root from Vim's native data
            # directory, which is ~/vimfiles on Windows and ~/.vim elsewhere.
            plugin_root = benchmark.vim_data_dir(home) / "plugged"
            alpha_plugin = plugin_root / "alpha" / "plugin" / "alpha.vim"
            alpha_autoload = plugin_root / "alpha" / "autoload" / "alpha.vim"
            beta_plugin = plugin_root / "beta" / "plugin" / "beta.vim"
            outside = root / "outside.vim"
            timing = root / "startup.log"
            timing.write_text(
                "\n".join(
                    [
                        f"001.000  000.500  000.125: sourcing {alpha_plugin}",
                        f"002.000  000.250: sourcing {alpha_autoload}",
                        f"003.000  001.000  000.750: sourcing {beta_plugin}",
                        f"004.000  003.000  002.000: sourcing {outside}",
                        "005.000  001.000: opening buffers",
                    ]
                )
                + "\n",
                encoding="utf-8",
            )

            result = benchmark.parse_plugin_self_times(timing, home)

            self.assertEqual({"alpha", "beta"}, set(result))
            self.assertAlmostEqual(0.375, result["alpha"])
            self.assertAlmostEqual(0.750, result["beta"])


class EnvironmentTests(unittest.TestCase):
    """Protect the benchmark's documented environment profile."""

    def test_vim_data_dir_uses_the_native_platform_convention(self) -> None:
        """Windows profiles use vimfiles while Unix profiles use .vim."""
        home = Path("/benchmark-home")

        self.assertEqual(home / ".vim", benchmark.vim_data_dir(home, "posix"))
        self.assertEqual(home / "vimfiles", benchmark.vim_data_dir(home, "nt"))

    def test_benchmark_environment_is_normalized_and_isolated(self) -> None:
        """Host terminal, SSH, display, and Vim init state cannot leak in."""
        contaminated = {
            "COLORTERM": "host-value",
            "DISPLAY": ":99",
            "EXINIT": "set insecure-option",
            "GHOSTTY_RESOURCES_DIR": "/host/ghostty",
            "GVIMINIT": "set insecure-option",
            "KITTY_WINDOW_ID": "42",
            "SSH_CLIENT": "host-client",
            "SSH_CONNECTION": "host-connection",
            "SSH_TTY": "/dev/pts/1",
            "TERM": "dumb",
            "TERM_PROGRAM": "HostTerminal",
            "VIMINIT": "set insecure-option",
            "WAYLAND_DISPLAY": "wayland-9",
            "WEZTERM_PANE": "pane-id",
            "WT_SESSION": "session-id",
        }
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary) / "benchmark-home"
            with mock.patch.dict(os.environ, contaminated, clear=False):
                environment = benchmark.benchmark_environment(home)

                self.assertEqual("dumb", os.environ["TERM"])
                self.assertEqual("xterm-256color", environment["TERM"])
                self.assertEqual("truecolor", environment["COLORTERM"])
                self.assertEqual("WezTerm", environment["TERM_PROGRAM"])
                self.assertEqual(str(home), environment["HOME"])
                self.assertEqual(str(home), environment["USERPROFILE"])
                self.assertEqual(str(home / ".cache"), environment["XDG_CACHE_HOME"])
                self.assertEqual(str(home / ".config"), environment["XDG_CONFIG_HOME"])
                self.assertEqual(
                    str(home / ".local" / "share"), environment["XDG_DATA_HOME"]
                )
                self.assertEqual(
                    str(home / ".local" / "state"), environment["XDG_STATE_HOME"]
                )
                for name in contaminated:
                    if name not in {"COLORTERM", "TERM", "TERM_PROGRAM"}:
                        self.assertNotIn(name, environment)

    def test_time_wrapper_uses_only_known_platform_dialects(self) -> None:
        """An unknown /usr/bin/time cannot break otherwise valid samples."""
        with tempfile.TemporaryDirectory() as temporary:
            time_binary = Path(temporary) / "time"
            time_binary.touch()
            command = ["vim", "--version"]

            self.assertEqual(
                ([str(time_binary), "-l", *command], "darwin"),
                benchmark.timed_command(command, "darwin", time_binary),
            )
            self.assertEqual(
                (
                    [
                        str(time_binary),
                        "-f",
                        "__CHOPSTICKS_RSS_KIB__=%M",
                        *command,
                    ],
                    "gnu",
                ),
                benchmark.timed_command(command, "linux", time_binary),
            )
            self.assertEqual(
                (command, "none"),
                benchmark.timed_command(command, "freebsd", time_binary),
            )


class ReportWritingTests(unittest.TestCase):
    """Keep machine reports atomic and safe in shared output directories."""

    def test_write_json_replaces_a_leaf_symlink_not_its_target(self) -> None:
        """A predictable output name cannot be used to clobber another file."""
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            victim = directory / "victim"
            output = directory / "report.json"
            victim.write_text("keep me\n", encoding="utf-8")
            try:
                output.symlink_to(victim)
            except OSError as error:  # pragma: no cover - restricted Windows host
                self.skipTest(f"cannot create a symlink: {error}")

            with mock.patch("builtins.print"):
                benchmark.write_json(output, {"status": "ok"})

            self.assertEqual("keep me\n", victim.read_text(encoding="utf-8"))
            self.assertFalse(output.is_symlink())
            self.assertEqual(
                {"status": "ok"}, json.loads(output.read_text(encoding="utf-8"))
            )

    def test_write_json_fsyncs_before_atomic_replace(self) -> None:
        """The complete temporary report is durable before it becomes visible."""
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            output = directory / "report.json"
            output.write_text("old report\n", encoding="utf-8")
            expected = {"nested": {"value": 7}, "status": "ok"}
            events = []
            real_fsync = os.fsync
            real_replace = os.replace

            def recording_fsync(file_descriptor: int) -> None:
                events.append("fsync")
                real_fsync(file_descriptor)

            def recording_replace(source: object, destination: object) -> None:
                source_path = Path(source)
                self.assertEqual(directory, source_path.parent)
                self.assertTrue(source_path.name.startswith(".report.json.tmp-"))
                self.assertEqual(
                    expected, json.loads(source_path.read_text(encoding="utf-8"))
                )
                events.append("replace")
                real_replace(source, destination)

            with mock.patch.object(benchmark.os, "fsync", recording_fsync):
                with mock.patch.object(benchmark.os, "replace", recording_replace):
                    with mock.patch("builtins.print"):
                        benchmark.write_json(output, expected)

            self.assertEqual(["fsync", "replace"], events)
            self.assertEqual(
                expected, json.loads(output.read_text(encoding="utf-8"))
            )
            self.assertEqual([], list(directory.glob(".report.json.tmp-*")))


class ProfileValidationTests(unittest.TestCase):
    """Prevent an incomplete provided home from producing a faster green run."""

    @staticmethod
    def report_for(profile: object) -> object:
        """Build the minimum report shape consumed by violations_for()."""
        return {
            "profile": profile,
            "workloads": {"warm": {}},
            "runtime_configuration": {"bytes": 1},
        }

    def test_duplicate_plugin_directory_names_are_rejected(self) -> None:
        """Two repositories cannot silently overwrite one basename pin."""
        with tempfile.TemporaryDirectory() as temporary:
            vimrc = Path(temporary) / ".vimrc"
            vimrc.write_text(
                "\n".join(
                    [
                        f"Plug 'first/alpha', {{'commit': '{'a' * 40}'}}",
                        f"Plug 'second/alpha.git', {{'commit': '{'b' * 40}'}}",
                    ]
                ),
                encoding="utf-8",
            )
            with mock.patch.object(benchmark, "VIMRC", vimrc):
                with self.assertRaisesRegex(
                    benchmark.BenchmarkError, "duplicate vim-plug directory name"
                ):
                    benchmark.declared_plugin_pins()

    def test_empty_provided_home_is_incomplete_and_violates_check(self) -> None:
        """An empty --home cannot masquerade as a complete plugin profile."""
        with tempfile.TemporaryDirectory() as temporary:
            pins = {"alpha": "a" * 40, "beta": "b" * 40}
            with mock.patch.object(benchmark, "declared_plugin_pins", return_value=pins):
                profile = benchmark.profile_metadata(Path(temporary), isolated=False)
            violations = benchmark.violations_for(
                self.report_for(profile), mock.Mock(runtime_bytes_budget=2)
            )

        self.assertFalse(profile["profile_complete"])
        self.assertFalse(profile["vim_plug"])
        self.assertEqual(profile["declared_plugins"], len(profile["missing_plugins"]))
        self.assertIn("provided home is missing vim-plug", violations)
        self.assertTrue(any("declared plugin(s)" in item for item in violations))

    def test_one_missing_declared_plugin_is_reported_by_name(self) -> None:
        """Extra directories cannot hide one absent declared dependency."""
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary)
            data_dir = benchmark.vim_data_dir(home)
            (data_dir / "autoload").mkdir(parents=True)
            (data_dir / "autoload" / "plug.vim").touch()
            pins = {"alpha": "a" * 40, "beta": "b" * 40}
            missing = "beta"
            plugin_root = data_dir / "plugged"
            (plugin_root / "alpha").mkdir(parents=True)
            (plugin_root / "unrelated-extra-directory").mkdir()

            with mock.patch.object(
                benchmark, "declared_plugin_pins", return_value=pins
            ), mock.patch.object(
                benchmark, "run_text", side_effect=["a" * 40, ""]
            ):
                profile = benchmark.profile_metadata(home, isolated=False)
            violations = benchmark.violations_for(
                self.report_for(profile), mock.Mock(runtime_bytes_budget=2)
            )

        self.assertFalse(profile["profile_complete"])
        self.assertEqual([missing], profile["missing_plugins"])
        self.assertEqual(
            profile["declared_plugins"] - 1, profile["installed_declared_plugins"]
        )
        self.assertTrue(any(missing in item for item in violations))

    def test_plugin_heads_are_matched_and_classified_with_local_git(self) -> None:
        """A real local HEAD is matched, mismatched, or marked unverifiable."""
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary)
            data_dir = benchmark.vim_data_dir(home)
            (data_dir / "autoload").mkdir(parents=True)
            (data_dir / "autoload" / "plug.vim").touch()
            plugin_root = data_dir / "plugged"
            alpha = plugin_root / "alpha"
            alpha.mkdir(parents=True)
            (alpha / "fixture.txt").write_text("fixture\n", encoding="utf-8")
            subprocess.run(["git", "init", "-q", str(alpha)], check=True)
            subprocess.run(["git", "-C", str(alpha), "add", "fixture.txt"], check=True)
            subprocess.run(
                [
                    "git",
                    "-C",
                    str(alpha),
                    "-c",
                    "user.name=Chopsticks Test",
                    "-c",
                    "user.email=test@example.invalid",
                    "commit",
                    "-q",
                    "-m",
                    "fixture",
                ],
                check=True,
            )
            actual = subprocess.run(
                ["git", "-C", str(alpha), "rev-parse", "HEAD"],
                check=True,
                stdout=subprocess.PIPE,
                text=True,
                encoding="utf-8",
            ).stdout.strip()
            (plugin_root / "not-a-repository").mkdir()

            with mock.patch.object(
                benchmark,
                "declared_plugin_pins",
                return_value={"alpha": actual},
            ):
                matched = benchmark.profile_metadata(home, isolated=False)
                (alpha / "fixture.txt").write_text("changed\n", encoding="utf-8")
                tracked_dirty = benchmark.profile_metadata(home, isolated=False)
                (alpha / "fixture.txt").write_text("fixture\n", encoding="utf-8")
                (alpha / "doc").mkdir()
                (alpha / "doc" / "tags").write_text("generated\n", encoding="utf-8")
                generated_tags = benchmark.profile_metadata(home, isolated=False)
                (alpha / "untracked.txt").write_text("untracked\n", encoding="utf-8")
                untracked_dirty = benchmark.profile_metadata(home, isolated=False)
                (alpha / "untracked.txt").unlink()
            with mock.patch.object(
                benchmark,
                "declared_plugin_pins",
                return_value={
                    "alpha": "0" * 40,
                    "not-a-repository": "1" * 40,
                },
            ):
                incomplete = benchmark.profile_metadata(home, isolated=False)

        self.assertTrue(matched["profile_complete"])
        self.assertEqual("matched", matched["plugin_revisions"][0]["state"])
        self.assertTrue(generated_tags["profile_complete"])
        self.assertEqual([], generated_tags["dirty_plugins"])
        for dirty in (tracked_dirty, untracked_dirty):
            self.assertFalse(dirty["profile_complete"])
            self.assertEqual(["alpha"], dirty["dirty_plugins"])
            self.assertEqual("dirty", dirty["plugin_revisions"][0]["state"])
            self.assertIn(
                "provided home has dirty plugin worktree(s): alpha",
                benchmark.violations_for(
                    self.report_for(dirty), mock.Mock(runtime_bytes_budget=2)
                ),
            )
        self.assertFalse(incomplete["profile_complete"])
        self.assertEqual(["not-a-repository"], incomplete["unverifiable_plugins"])
        self.assertEqual(
            [
                {
                    "plugin": "alpha",
                    "expected_commit": "0" * 40,
                    "installed_commit": actual,
                }
            ],
            incomplete["mismatched_plugins"],
        )


if __name__ == "__main__":
    unittest.main()
