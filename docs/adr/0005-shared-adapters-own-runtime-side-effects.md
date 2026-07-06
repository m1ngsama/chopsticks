# Shared Adapters Own Runtime Side Effects

Chopsticks keeps low-level Vim runtime side effects behind small shared
adapters in `modules/env.vim`. Runtime feature checks, managed local-file
writes, and temporary nofile scratch buffers are common enough that repeating
them in each module makes behavior drift likely and tests less direct.

## Decision

- Use `ChopsticksRuntimeFeatureSpec()` and
  `ChopsticksRuntimeFeatureAvailable()` for Vim feature and platform checks.
- Use `ChopsticksEnsureDir()`, `ChopsticksEnsureParentDir()`,
  `ChopsticksEnsureManagedFile()`, `ChopsticksAppendManagedFile()`, and
  `ChopsticksOpenManagedFile()` for Chopsticks-owned local files.
- Use `ChopsticksOpenScratchBuffer()` for Chopsticks-owned nofile reference,
  status, health, and audit views.

## Consequences

- Modules describe intent at the adapter interface instead of assembling
  repeated `has()`, `mkdir()`, `writefile()`, `:edit`, `:new`, `:resize`,
  `setlocal`, and buffer-local mapping details.
- Adapter interfaces become the main test surface for side-effect policy.
- New modules should not add raw Vim feature checks, managed-file creation, or
  scratch-buffer opening unless the shared adapter cannot express the required
  behavior.
- This does not create a Neovim compatibility layer. The adapters remain pure
  Vimscript and continue to obey ADR-0001.
