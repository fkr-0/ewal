# Ewal roadmap

This roadmap describes direction rather than a promise of dates. Work should
preserve the small dependency-free core, keep palette behavior inspectable, and
ship only with headless tests and reproducible contrast evidence.

## Current baseline: 0.3

- Pywal-compatible JSON and bundled palette loading.
- Automatic fallback to the colrz cache format.
- Display-independent color normalization and WCAG contrast measurement.
- Doom, Spacemacs, Evil cursor, and mode-line integrations.
- Dynamic theme generation, palette audits, and interactive contrast repair.
- Eldev tests, warnings-as-errors compilation, linting, and a multi-version CI
  matrix.

## 0.3.x — hardening and packaging

- Add focused package-lint jobs for each MELPA package boundary.
- Pin third-party GitHub Actions to immutable commit hashes.
- Exercise the declared Emacs 25.1 floor in a reproducible container, while
  retaining the faster 27/29/30 hosted matrix.
- Add malformed, partial, and concurrently replaced cache-file fixtures.
- Validate every generated theme against a stable set of representative faces.
- Document installation recipes for package-vc, straight.el, and Doom Emacs.

## 0.4.0 — palette providers and live updates

- Introduce a provider protocol for pywal, colrz, Base16, and direct palette
  objects without coupling the core to any external command.
- Add file-notify based palette refresh with debounce, rollback, and visible
  diagnostics.
- Expose source precedence and the active palette source through an inspectable
  status command.
- Make palette normalization preserve provenance and report every repaired
  semantic role.
- Add stable machine-readable audit output for CI and editor integrations.

## 0.5.0 — composable theme profiles

- Separate semantic color roles from face-family profiles.
- Support reusable typography, spacing, modeline, cursor, and accessibility
  profiles that can be combined without copying complete themes.
- Add preview buffers for comparing candidate palettes and profiles side by
  side.
- Expand Transient interfaces while keeping all core operations callable as
  ordinary noninteractive functions.

## 1.0.0 criteria

- A documented stable public API for loading, querying, transforming, and
  auditing palettes.
- Clear compatibility guarantees for package boundaries and generated themes.
- Reproducible tests across the supported Emacs range and both graphical and
  headless execution.
- No silent contrast repair: every adjustment can be inspected, reproduced,
  disabled, or overridden.
- Migration notes for every breaking change and a maintained changelog.

## Non-goals

- Reimplementing wallpaper analysis or terminal theme generators inside Emacs.
- Requiring Doom, Spacemacs, Evil, or Transient for basic palette access.
- Mutating user theme files automatically without an explicit command and a
  reviewable preview.
