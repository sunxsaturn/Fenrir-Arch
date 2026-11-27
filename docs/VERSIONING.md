# Fenrir versioning and release policy

Fenrir components are versioned independently. Each repository has one authoritative version source and a monotonic release sequence; component version numbers do not need to match.

## Number format

Use `MAJOR.MINOR.PATCH` and prefix Git tags with `v` (for example, package `0.36.0`, tag `v0.36.0`). This is a Linux-kernel-inspired steadily advancing sequence:

- **MINOR** advances for a feature milestone or backward-compatible capability expansion. Reset PATCH to zero.
- **PATCH** advances for fixes, maintenance, packaging corrections and documentation-only releases that are intentionally published.
- **MAJOR** advances only for a deliberate compatibility break to a public contract, configuration, installer interface or data format, with migration guidance.

Never reset, reuse or move a released version backwards. Do not derive versions from dates, commit counts or another repository's release number.

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
