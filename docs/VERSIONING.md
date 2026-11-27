# Versioning and releases

Fenrir uses numeric `MAJOR.MINOR.PATCH` versions with a strictly increasing sequence inside each repository.

## Rules

- **MAJOR** changes identify an incompatible release line or a deliberate reset of public compatibility.
- **MINOR** increases for a new backward-compatible capability or a substantial milestone.
- **PATCH** increases one step for fixes, documentation corrections and maintenance releases.
- Never reuse a released number, decrease a component's version or skip numbers without a documented release reason.
- Use a `-rc.N` suffix for a release candidate; publish the final numeric version only after its checks pass.
- Git tags use the `v` prefix, for example `v0.14.2`.

These rules are intentionally simple and monotonic, similar to the kernel's easy-to-follow numeric release progression. They do not require different Fenrir components to share the same number.

## Version sources

| Repository | Source of truth | Required consistency |
|---|---|---|
| Fenrir-Arch | Root `VERSION` | Release tag and source archive use the same value |
| Fenrir-Dots | Root `VERSION` | Release tag, source archive and Doctor release display use the same value |
| Fenrir Wallpaper Catalog | `pyproject.toml` | `src/fenrir_catalog/__init__.py`, built package metadata and release tag must match |

Do not invent a second version field in documentation. Documentation may state an exact compatibility pin, but the version source above remains authoritative.

## Component pins

Fenrir-Arch is the integration repository. It pins exact Fenrir-Dots and private Catalog commit SHAs and validates each pinned checkout against its expected version and required file set. A pin is a compatibility decision, not a request to use the newest branch.

To update a pin:

1. Finish and test the change in the component repository.
2. Merge that component change and confirm its release tag and exact commit.
3. Update the SHA, expected version and required-file contract in Fenrir-Arch.
4. Update the integration tests to assert the same SHA/version pair.
5. Run the installer CI against the pinned source before releasing Fenrir-Arch.

Keep each repository's release sequence independent. A documentation-only component release does not require an installer pin change when the pinned source remains compatible.

## Release automation

The Arch and Dots release workflows validate the source, create a versioned source archive and publish a `vX.Y.Z` release when the version file changes on `main`. The Catalog package version is declared in `pyproject.toml`; keep its Python package version in sync and run its full test suite before publishing.

The release commit must include the matching changelog entry. Never create a release tag for an unmerged branch.
