# Performance

Performance is a compatibility contract for Chopsticks, not a one-off score.
The target is an offline Vim session on old, low-power hardware with bounded
startup work and no background polling while idle.

## Run the benchmark

The harness uses only Python 3.8+'s standard library, Vim's `--startuptime`
clock, and the recognized macOS or GNU `/usr/bin/time` dialect when available.
The zero-dependency npm launcher selects the native Python command on Windows
or POSIX. The benchmark creates an isolated temporary home by default, never
installs plugins, and never accesses the network.

```sh
npm run benchmark -- --samples 21 \
  --json /tmp/chopsticks-performance.json
```

That command measures the core configuration. To measure the complete setup,
point it at a home where the pinned plugins are already installed:

```sh
npm run benchmark -- --samples 21 \
  --home "$HOME" \
  --check \
  --json /tmp/chopsticks-performance-full.json
```

With `--check`, a provided home is incomplete when vim-plug or any declared
plugin directory is missing, its Git HEAD cannot be verified, or its commit
differs from the 40-character pin. Tracked/index changes and untracked files
also fail the profile; vim-plug's generated `doc/tags` file is the sole
exception. The report records every expected and installed revision and
distinguishes these failures from the intentionally plugin-free
`isolated-core` profile.

`--check` exits nonzero when a regression redline is crossed. When an explicit
cold-cache command is supplied, it also enforces the 500 ms cold no-file
startup redline; override that independently with
`--cold-startup-p95-budget-ms`. Other cold workloads remain informational. The
JSON report records the commit and dirty state, Vim and Python versions, CPU
architecture, logical CPU count, memory, individual samples, nearest-rank
p50/p95/p99, wall time, peak RSS where the platform exposes it, and exclusive
plugin source times. It also records whether each optional external tool is
available, because a language server or linter can change the measured startup
path. Machine-specific local Vim configuration is disabled during a run.

The environment profile is fixed to a local truecolor terminal with icons on,
manual linting, an opaque balanced UI, and system clipboard integration off.
SSH, display, and terminal-vendor variables inherited from the calling shell
cannot silently select a different startup path.

## Workloads

Every warm workload receives one unmeasured priming run. The generated files
are exactly 1 MiB.

| Workload               | Contract                                                   |
| ---------------------- | ---------------------------------------------------------- |
| `startup`              | No-file startup through all `VimEnter` handlers            |
| `markdown_1mib`        | Representative prose, lists, links, and sparse fenced code |
| `markdown_long_line`   | One pathological 1 MiB line with Markdown syntax           |
| `markdown_many_fences` | Thousands of fenced blocks; nonlinear syntax stress case   |

The representative fixture intentionally keeps one fenced block per roughly
80 lines. Treating thousands of code fences as an ordinary document would
hide regressions behind an unrealistic input; the dense form remains a
separate, explicitly named stress workload.

## Budgets

The ideal targets describe the intended experience. Redlines are failure
thresholds when the corresponding metric is collected, not targets to optimize
up to; hosted CI enforces the warm automated subset described below.

| Metric                         |      Ideal | Regression redline |
| ------------------------------ | ---------: | -----------------: |
| No-file cold startup p95       |  <= 100 ms |           > 500 ms |
| No-file warm startup p95       |   <= 50 ms |           > 250 ms |
| Open representative 1 MiB file |  <= 150 ms |           > 900 ms |
| Open 1 MiB long line           |  <= 150 ms |           > 900 ms |
| Dense-fence stress case        |  <= 500 ms |          > 1800 ms |
| Normal key to redraw p99       | <= 16.7 ms |            > 33 ms |
| Idle CPU                       |         0% |             > 0.5% |
| Startup network requests       |          0 |                > 0 |
| Runtime configuration          |   <= 1 MiB |            > 2 MiB |

CI installs the pinned plugin graph, collects 21 warm samples per workload,
enforces the startup, file-open, plugin-share, and runtime-size redlines, and
uploads the complete JSON report for 14 days. Twenty-one samples make
nearest-rank p95 the twentieth result instead of making one outlier identical
to p95. Hosted runners are noisy, so compare the artifact with earlier runs
before changing a budget.

The redlines sit near twice the slowest hosted measurement on purpose. Those
runners differ by more than 1.6x between hosts: three consecutive runs of one
commit reported 105 ms of warm no-file startup where an earlier run of the
same commit reported 64 ms, and two attempts of a single run disagreed by more
than half on the long-line workload. A redline tight enough to fail on the
slower host reports the machine rather than the code. The ideal column is what
a quiet local machine should reach, and is the number worth optimizing toward.

Formatting, preview, and lint commands must remain user-initiated. Startup
must stay offline, and a missing plugin or external tool must not prevent Vim
from becoming usable. No plugin may consume more than 20% of measured startup
at p50 without an explanation and a recovery plan.

## Cold filesystem cache

Clearing the operating system's filesystem cache is privileged and
platform-specific, so the harness never pretends that a fresh temporary home
is a cold disk. Without an explicit command, the report records cold-cache
measurements as not collected.

On a dedicated benchmark machine, pass a reviewed cache command. For example:

```sh
# macOS; run only on a dedicated benchmark machine
npm run benchmark -- --samples 21 --cold-samples 5 \
  --cold-cache-command 'sudo purge' --home "$HOME"

# Linux; run only on a dedicated benchmark machine
npm run benchmark -- --samples 21 --cold-samples 5 \
  --cold-cache-command "sudo sh -c 'sync; echo 3 > /proc/sys/vm/drop_caches'" \
  --home "$HOME"
```

The command is parsed as an argument vector rather than evaluated by a shell.
It runs before every recorded cold sample. Review it carefully: the harness
cannot determine whether a supplied command really evicts the relevant cache.

## Baseline

The latest per-commit full-plugin baseline is the `chopsticks-performance`
artifact attached to the `check` workflow. This keeps raw samples and hardware
metadata next to the exact code that produced them instead of presenting a
hosted-runner number as a universal claim.

Before opening a performance pull request, include both the before and after
JSON reports, the workload that changed, and the relevant top contributors.
If a redline must temporarily move, document the measurement, cause, user
impact, and a concrete recovery plan in the pull request.

Cold-cache latency, input-to-redraw latency, and idle CPU remain manual lab
measurements because hosted CI cannot collect them honestly. Record those
results with the machine model, storage, Vim build, terminal, sample count,
and cache procedure.
