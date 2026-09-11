# Changelog

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
