# Slot-safety audit

Source audited: `follower_system_source.txt` supplied by the user.

## Existing conflicts found

- `SPRITE_FOLLOWER` was allocated as variable sprite `$fd`.
- `AddFollowerObject` mapped that variable to `SPRITE_FAIRY`.
- `NewBarkGroupSprites` contained `FOLLOWER_SPRITE` in the position used by `SPRITE_MONSTER` in the adjacent matching outdoor list.
- Outdoor maps load a fixed `MAX_OUTDOOR_SPRITES` count, so deleting that entry without restoring the displaced sprite would read into the next table.

## Dedicated layout

| Region | Owner | Capacity |
|---|---|---:|
| OBJ VRAM bank 1, tile IDs `$00-$73` | normal first sprite table | 116 tiles |
| OBJ VRAM bank 1, tile IDs `$74-$7f` | follower only | 12 tiles |
| OBJ VRAM bank 0, tile IDs `$80-$ff` | normal second sprite table | 128 tiles |

Normal map sprites retain 244 allocatable tile IDs. The follower's two 12-tile graphic halves occupy the same dedicated tile-number range in `vTiles0` and `vTiles1`, matching Crystal's `WALKING_SPRITE` layout.

## Capacity result

The supplied outdoor tables contain 23 entries per standard group. Parsing their sprite lengths and including the 12-tile player gives a worst-case normal allocation of **240 tiles**. After reserving the follower range, normal capacity is **244 tiles**, leaving a four-tile margin. The follower adds 12 dedicated tiles, so worst total physical use is 252 of 256 available tile IDs.

## Required invariants

- No outdoor group contains `SPRITE_FOLLOWER` or `FOLLOWER_SPRITE`.
- `NewBarkGroupSprites` restores `SPRITE_MONSTER`, preserving 23 entries.
- `AddSpriteGFX` ignores the follower ID.
- `GetSpriteVTile` returns `$74` directly for the follower.
- `ArrangeUsedSprites` changes its first-table boundary from `$80` to `$74`.
- Every follower sheet is exactly 384 bytes: two halves × 12 tiles × 16 bytes.
- Core table entries remain contiguous from Bulbasaur 1 through Celebi 251; custom entries append afterward.
