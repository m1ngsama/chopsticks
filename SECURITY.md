# Security policy

## Supported versions

Security fixes are made on `main` and, when practical, on the latest tagged
Vim-first release. The repository was rebooted at `v0.1.0`; older `v1.x` and
`v2.x` tags belong to the retired implementation and are unsupported.

| Version                         | Supported |
| ------------------------------- | --------- |
| `main`                          | Yes       |
| Latest Vim-first release        | Yes       |
| Earlier and historical releases | No        |

Windows users must run Vim 9.1.1947 or newer because older builds are affected
by the upstream executable search-path vulnerability
[GHSA-g77q-xrww-p834](https://github.com/vim/vim/security/advisories/GHSA-g77q-xrww-p834).

## Reporting a vulnerability

Email `contact@m1ng.space` with a short request for a secure reporting channel.
Do not include exploit details, secrets, sensitive attachments, or a complete
proof of concept in that first message. Do not open a public issue for a
vulnerability or include vulnerability details in a public discussion. The
maintainer will reply with a suitable private channel for the full report.

After a private channel is established, include as much of the following as
possible:

- the chopsticks version or commit;
- operating system, Vim version, and relevant terminal or SSH context;
- minimal reproduction steps or a proof of concept;
- the expected security impact and affected trust boundary;
- any known workaround or mitigation.

Reports will be acknowledged as soon as reasonably possible. The maintainer
will coordinate validation, remediation, and disclosure with the reporter;
timing depends on severity and upstream dependencies.

## Trust model

Chopsticks is configuration code that runs with the same permissions as Vim.
Its startup path does not access the network, but several inputs remain trusted
code or data:

- The optional local configuration is sourced from the user Vim data directory
  (`~/.vim/chopsticks.local.vim` on Unix and
  `~/vimfiles/chopsticks.local.vim` on Windows) and can execute arbitrary
  Vimscript. Only create or copy that file from a trusted source.
- Chopsticks sets `noexrc` and `nomodeline`; opening a project does not source a
  project-local vimrc or execute buffer modelines. Commands, formatters,
  language servers, and other tools you launch explicitly still cross the
  project trust boundary.
- Plugins execute inside Vim after an explicit `:PlugInstall`. Declarations are
  pinned to full commits to prevent silent drift, but plugins are not sandboxed.
- `:ChopsticksSessionLoad` sources a native Vim session file. Chopsticks rejects
  a session root that is not a real directory and a session path that is not a
  regular file. On platforms with meaningful POSIX modes, it also creates
  private session directories and files and refuses group- or world-writable
  sessions. Vim does not expose reliable Windows ACL ownership; Windows
  therefore relies on the per-user profile ACL as its authority boundary. Do
  not import a session or point `g:chopsticks_session_dir` at an untrusted
  directory.
- External tools, formatters, language servers, previews, and shell commands run
  with the current user's permissions. Review project content and tool-specific
  configuration before using them in an untrusted repository.

Network access occurs only through explicit installation or update actions such
as `:PlugInstall` and `:PlugUpdate`.
