# Releasing

This checklist is for maintainers. Following it prepares a release; no step is
automatic, and the repository's npm package is private development tooling that
must not be published.

## Prepare the candidate

1. Start from an up-to-date `main` with all required CI checks passing.
2. Choose a semantic version for the current Vim-first line. Historical `v1.x`
   and `v2.x` tags belong to the retired implementation and are not part of the
   current version sequence.
3. Synchronize the version in:

   - `g:chopsticks_version` in `.vimrc`;
   - `version` in `package.json`;
   - the root package versions in `package-lock.json`.

4. Move the relevant `CHANGELOG.md` entries from `Unreleased` to a versioned,
   ISO-dated section and add a fresh `Unreleased` section.
5. Regenerate `.github/demo.gif` with `npm run demo` when the visible workflow
   changed. Review the animation for private paths or terminal history.
6. Review every dependency-pin change and confirm that its upstream commit
   still exists.

## Verify

From a clean dependency install, run:

```sh
npm ci --ignore-scripts
npm run lint
npm test
git diff --check
```

Wait for CI to pass the minimum Vim, native Windows smoke, and full-plugin
integration jobs. For changes involving filesystem paths, terminal behavior,
or the clipboard, also test the affected operating system manually.

Before tagging, verify a clean install in a temporary user profile: install the
documented, checksum-verified vim-plug bootstrap, run `:PlugInstall`, restart
Vim, and inspect `:ChopsticksHealth`. Exercise the dashboard, file search,
explorer fallback, Markdown setup, and session save/load paths relevant to the
release.

## Tag and announce

1. Merge the prepared candidate and verify the exact commit on `main`.
2. Create an annotated `vX.Y.Z` tag. Sign it when the maintainer's signing setup
   is available.
3. Push the tag without rewriting or moving an existing release tag.
4. Create a GitHub release whose notes match the versioned changelog section.
5. Re-run the README installation path against the tag, not a working tree.

Do not run `npm publish`; `package.json` exists only to provide reproducible
development commands.

If a release is faulty, preserve its tag and publish a patch release. Moving or
deleting a public tag makes installations and audits irreproducible.
