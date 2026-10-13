; Dedicated follower graphics constants.
; Include after the standard sprite/species/palette constants.

DEF FOLLOWER_SPRITE_TILES      EQU 12
DEF FOLLOWER_GFX_HALVES        EQU 2
DEF FOLLOWER_GFX_BYTES         EQU FOLLOWER_SPRITE_TILES * TILE_SIZE * FOLLOWER_GFX_HALVES
DEF FOLLOWER_GFX_ENTRY_SIZE    EQU 4 ; bank, pointer, overworld palette

; Reserve the last 12 tile numbers in VRAM bank 1 exclusively for the follower.
; Normal sprites can still use 244 tile numbers across the two sprite tables.
DEF FOLLOWER_VTILE             EQU $80 - FOLLOWER_SPRITE_TILES ; $74
DEF FOLLOWER_VTILE_END         EQU FOLLOWER_VTILE + FOLLOWER_SPRITE_TILES
assert FOLLOWER_VTILE_END == $80

; The override marker makes old saves/padding harmless. A missing marker means
; "follow the first valid Pokémon in the party".
DEF FOLLOWER_OVERRIDE_MAGIC    EQU $a5

; Additional graphics IDs begin after Celebi. IDs are 16-bit at runtime.
DEF FOLLOWER_GFX_CUSTOM_BASE   EQU NUM_POKEMON + 1
