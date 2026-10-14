# Changelog

## 0.2.3

### Fixed
- In the expression form of `@↓`, the constants `nothing`, `missing`, `π`,
  `ℯ`, `im`, `Inf`, `NaN` are left alone, and so are `begin`/`end` inside
  indexing: `@↓ x ← u[end] = s` now reads `s.u[end]`.
- Malformed entries in a field list (`@↓ a, 1 = s`), a literal right of `←`
  in `@↓` (`@↓ x ← 1 = s`) and a non-name left of `←` in `@↑` now raise an
  error at expansion; before, the first two were silently dropped.

### Changed
- Supported Julia: `1.10` and later (was `1.6`).
- Sources, tests and examples follow the repository JuliaFormatter
  configuration (Blue style), checked in CI.
- The rewrite helper has one loop for all expression heads; the two macros
  share their entry parsing and build their output as a flat block.

### Added
- Tests for plain renames (`@↓ x ← b = s`), constants, indexing bounds,
  expression operands in chained comparisons, and the new error paths.
- The rewrite rules in the README and docs now list the constants and the
  `begin`/`end` rule, and state that names bound inside the expression are
  not supported.

## 0.2.2

### Fixed
- `@↓ x ← f(a; digits=1) = s` and `@↓ x ← (0 < a < 2) = s` no longer error:
  keyword names are left alone and only the operands of a chained comparison
  are rewritten as fields.

### Changed
- Supported Julia: `1.6` and later (was declared `1`, i.e. 1.0, untested).
  Verified on 1.6–1.13.
- Docs build with Documenter 1 and `checkdocs = :exports`; API page.

### Added
- Docstrings for both macros and the rewrite helpers, stating the rewrite
  rules; Aqua in the test suite.
