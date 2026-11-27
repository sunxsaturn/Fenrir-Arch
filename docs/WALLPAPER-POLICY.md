# Fenrir public wallpaper library v2

## Fixed target and categories

The public target is 5,000 globally unique wallpapers. Eleven categories make exact equal division impossible. The deterministic balanced allocation is six categories with 455 images and five with 454:

- Nordic Landscapes
- Medieval Landscapes
- Fantasy
- Epic Battles
- Mountains
- Astronomy
- Planets
- Knights in Battle
- Swords
- Magic
- Nordic Mythology

The ordered category registry records the six 455-image quotas first and the five 454-image quotas second. The Catalog and desktop client independently validate the distribution.

## Rights

Only verified Public Domain or CC0 assets may be published. An asset must have a source page, creator, license identifier, current source-terms evidence, image-specific rights evidence and an explicit publication approval. A free download, general provider label, catalog acceptance, or local use permission is not enough.

The private Catalog retains acquisition and review state. Public image files and public manifests belong only in the dedicated gallery repositories. The private database, quarantine, credentials and review documents never enter public Git.

## Legacy exclusion

The retired 1,871 public images are represented by their 1,871 unique SHA-256 hashes in the private Catalog exclusion file. Hashes are exclusion-only; old image bytes are not used as new assets.

## Color and image validation

Preferred families: blue, red, purple, black and violet. Green/neutral/white are tolerated. Yellow, brown, orange and pink are excluded using decoded pixels, never query wording or filenames. Public gallery image dimensions must be at least 2560×1440 and landscape. SHA-256, exact byte size and decoded image format are verified at intake and again by desktop sync.

## Repository boundaries

The public hub owns the canonical registry and Volume 01. The other numbered repositories contain image-only volumes and their manifests. Public galleries must not contain application code, private Catalog assets, local databases or secrets.

The public generation remains `building` until all 5,000 records pass validation. The desktop installer refuses incomplete generations.
