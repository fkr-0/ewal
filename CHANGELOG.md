# Changelog

All notable changes to this project are documented in this file. The project
uses [Semantic Versioning](https://semver.org/) and follows the structure of
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

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

[Unreleased]: https://github.com/fkr-0/ewal/compare/v0.3.1...HEAD
[0.3.1]: https://github.com/fkr-0/ewal/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/fkr-0/ewal/releases/tag/v0.3.0
[0.2.1]: https://github.com/cyruseuros/ewal/releases/tag/v0.2.1
[0.2.0]: https://github.com/cyruseuros/ewal/releases/tag/v0.2
