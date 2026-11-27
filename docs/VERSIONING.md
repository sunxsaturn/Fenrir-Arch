# Fenrir versioning and release policy

Fenrir components are versioned independently. Each repository has one authoritative version source and a monotonic release sequence; component version numbers do not need to match.

## Number format and incremental rollover

Use a monotonic numeric sequence with Git tags prefixed by `v`. Canonical release files use three components: `MAJOR.MINOR.PATCH`. The top-level Fenrir-Arch stable milestone is commonly abbreviated in prose as `1.0`; its canonical version is `1.0.0`.

The sequence advances by hierarchical rollover, not by treating the version as a decimal:

- A feature milestone advances **MINOR** and resets **PATCH**. For example, after `0.0.9`, the next minor line is `0.1.0`.
- The stable milestone after the `0.9` development line is **1.0** (canonical `1.0.0`), not `0.10`.
- Maintenance fixes advance **PATCH** within the current line. Published documentation-only fixes also advance PATCH.
- **MAJOR** advances for a stable compatibility milestone or a deliberate compatibility break with migration guidance.

Existing historical versions such as `0.15.0` and `0.37.0` remain unchanged; they are never renumbered to fit the new policy. Each component advances monotonically from its own published version. Never reset, reuse or move a released version backwards. Do not derive versions from dates or commit counts.

## Authoritative version sources

| Repository | Source of truth | Alignment checks |
|---|---|---|
| Fenrir-Arch | Root `VERSION` | README, release tag, pinned component versions and full commit SHAs |
| Fenrir-Dots | Root `VERSION` | README and release tag |
| Wallpaper Catalog | `pyproject.toml` | `src/fenrir_catalog/__init__.py`, database `PROJECT_VERSION`, README and release tag |

The Catalog SQLite schema version is independent of the Python package version. Increment schema only with a forward-only migration; a package release alone does not change the database schema.

## Companion pin update sequence

1. Complete and test the companion repository.
2. Publish its version and record the exact merged commit SHA.
3. Update Fenrir-Arch's SHA, expected version and required-file contract.
4. Run installer CI against the exact pinned source.
5. Publish the Arch release only after integration checks pass.

A documentation-only commit that is not released does not change the component version. A published documentation fix advances PATCH.
