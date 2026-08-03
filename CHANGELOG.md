# Changelog

All notable changes to this project are documented in this file. The project
uses [Semantic Versioning](https://semver.org/) and follows the structure of
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.3.2] - 2026-08-04

### Added

- Stable palette-file reads with configurable retries when a pywal-compatible
  producer rewrites or atomically replaces its cache during loading.
- Replacement-sensitive source caching using modification and status-change
  times, size, inode, and device metadata instead of modification time alone.
- Successful retry paths retain the final accepted file signature rather than
  the pre-replacement signature.
- Focused package-lint coverage for the core, Doom, Spacemacs, and Evil package
  entrypoints, available locally and enforced in every hosted CI job.
- Package artifact smoke testing that verifies bundled palettes are present and
  loadable from the extracted tarball.
- Regression fixtures for malformed JSON, incomplete cache structures, minimal
  compatible palettes, and concurrent cache replacement.

### Changed

- GitHub Actions now use immutable commit revisions for checkout and Emacs
  setup rather than mutable tags or branches.
- The complete local `check` command now includes package-boundary linting in
  addition to tests, strict compilation, Checkdoc, Relint, and package artifact
  validation.

### Fixed

- Malformed or structurally incomplete external palette files now fall back to
  the configured built-in palette instead of silently producing a synthetic
  mostly black-and-white theme.
- Palette validation now requires valid background and foreground colors plus
  at least one ANSI color while remaining compatible with partial palettes and
  optional cursor values.
- Generated package tarballs now include bundled palettes, the README, license,
  and changelog; installed built-in fallback no longer points at missing files.

## [0.3.1] - 2026-08-03

### Fixed

- Kept Transient prefix macros out of generated autoload files and dispatched
  the optional palette and contrast panels through `call-interactively`, which
  restores warnings-as-errors compilation on Emacs 29.4.
- Added forward declarations and regression tests for optional Transient
  command boundaries.
- Started the full-integration CI matrix at Emacs 28.1, matching the current
  Transient development dependency, while retaining the documented Emacs 25.1
  core compatibility target.
- Upgraded checkout to `actions/checkout@v5` and limited push CI to `master`,
  avoiding the Node.js 20 deprecation warning and duplicate tag-push runs.

## [0.3.0] - 2026-08-03

### Added

- Display-independent hexadecimal color parsing and WCAG contrast utilities.
- Contrast-safe semantic palette roles for foregrounds, comments, cursors, and
  highlights.
- Contrast-aware Doom, Spacemacs, Evil cursor, and mode-line adaptors.
- Dynamic Doom theme generation, palette auditing, interactive contrast tools,
  and optional Transient panels.
- More than 250 bundled dark and light pywal-compatible palettes.
- An Eldev test, compile, and lint workflow with comprehensive ERT release and
  behavior checks.
- GitHub Actions coverage for Emacs 27.2, 29.4, and 30.2.
- A canonical `VERSION` file, package version consistency checks, a roadmap,
  and machine-readable release evidence.
- Automatic fallback from the traditional pywal cache to the colrz
  pywal-compatible cache.

### Changed

- Resolved bundled palettes relative to the installed library rather than a
  user-specific Emacs directory.
- Separated optional Doom, Spacemacs, Evil, and Transient dependencies from the
  dependency-light core palette loader.
- Made color loading lazy, cache-aware, and explicitly reloadable.
- Hardened generated themes against foreground/background collisions and weak
  text contrast.
- Modernized project documentation and development commands.
- Adopted repository release version `0.3.0`; the independently versioned
  `ewal-evil-cursors` package advances from `1.0` to `1.1.0`.

### Fixed

- Headless and daemon startup no longer depend on terminal color capabilities
  when parsing hexadecimal colors.
- Comments now follow the ordinary-text contrast threshold instead of the
  weaker non-text UI threshold.
- Doom theme names remain stable and runtime theme entrypoints load in an
  isolated package environment.
- Spacemacs border, line-number, and accent roles are checked against the
  correct backgrounds.

### Removed

- Generated `ewal-autoloads.el` from version control; Eldev and package managers
  regenerate autoloads when needed.
- Obsolete migration copies `cc.el`, `update-1.el`, and `update-2.el`, whose
  useful behavior is already incorporated in maintained modules.

## [0.2.1] - 2020-03-01

### Changed

- Raised the Emacs dependency to 25.1 and improved package commentary and Doom
  theme compatibility.

## [0.2.0] - 2019-09-11

### Added

- Initial tagged release of the pywal-driven Emacs theme packages.

[Unreleased]: https://github.com/fkr-0/ewal/compare/v0.3.2...HEAD
[0.3.2]: https://github.com/fkr-0/ewal/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/fkr-0/ewal/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/fkr-0/ewal/releases/tag/v0.3.0
[0.2.1]: https://github.com/cyruseuros/ewal/releases/tag/v0.2.1
[0.2.0]: https://github.com/cyruseuros/ewal/releases/tag/v0.2
