; Dedicated follower graphics loader for Pokémon Crystal.
; One logical sprite ID, one fixed VRAM tile range, unlimited banked ROM assets.
; This module must be included after constants/follower_constants.asm.

SECTION "Dedicated Follower Graphics", ROMX

MACRO follower_gfx_entry
	db BANK(\1)
	dw \1
	db \2
ENDM

FollowerGFXTable:
	table_width FOLLOWER_GFX_ENTRY_SIZE
INCLUDE "data/followers/follower_gfx_table.asm"
	assert_table_length NUM_POKEMON
; Additions are appended here and therefore never renumber the 251 core entries.
INCLUDE "data/followers/custom_follower_gfx_entries.asm"
FollowerGFXTableEnd:
DEF NUM_FOLLOWER_GFX EQU (FollowerGFXTableEnd - FollowerGFXTable) / FOLLOWER_GFX_ENTRY_SIZE
assert NUM_FOLLOWER_GFX >= NUM_POKEMON
assert NUM_FOLLOWER_GFX < $10000

; Return carry clear when DE is a valid 1-based follower graphics ID.
ValidateFollowerGFXID::
	ld a, d
	or e
	jr z, .invalid
	ld a, d
	cp HIGH(NUM_FOLLOWER_GFX + 1)
	jr c, .valid
	jr nz, .invalid
	ld a, e
	cp LOW(NUM_FOLLOWER_GFX + 1)
	jr c, .valid
.invalid
	scf
	ret
.valid
	and a
	ret

; Select an asset. A valid explicit override wins; otherwise use the first
; real species in the party. Eggs/invalid party bytes are skipped.
; Success: carry clear; B:DE = source; C = 12 tiles; palette cached in WRAM.
; Failure: carry set (no party Pokémon and no valid override).
PrepareFollowerGFX::
	ld a, [wFollowerOverrideMagic]
	cp FOLLOWER_OVERRIDE_MAGIC
	jr nz, .party
	ld a, [wFollowerOverrideGFXID]
	ld e, a
	ld a, [wFollowerOverrideGFXID + 1]
	ld d, a
	call ValidateFollowerGFXID
	jr nc, .selected
	; Invalid stale/custom data must never index past the table.
	xor a
	ld [wFollowerOverrideMagic], a

.party
	ld a, [wPartyCount]
	and a
	jr z, .none
	ld c, a
	ld hl, wPartySpecies
.party_loop
	ld a, [hli]
	and a
	jr z, .next_party_mon
	cp NUM_POKEMON + 1
	jr nc, .next_party_mon ; skip EGG and non-species bytes
	ld e, a
	ld d, 0
	jr .selected
.next_party_mon
	dec c
	jr nz, .party_loop
.none
	scf
	ret

.selected
	ld a, e
	ld [wFollowerResolvedGFXID], a
	ld a, d
	ld [wFollowerResolvedGFXID + 1], a
	jp GetFollowerGFXDataByID

; Read a four-byte table entry selected by 1-based DE.
; Success: B = source bank, DE = source pointer, C = half length in tiles,
; A and wFollowerPalette = existing overworld palette, carry clear.
GetFollowerGFXDataByID::
	call ValidateFollowerGFXID
	ret c
	dec de
	ld h, d
	ld l, e
	add hl, hl
	add hl, hl ; * FOLLOWER_GFX_ENTRY_SIZE
	ld de, FollowerGFXTable
	add hl, de
	ld b, [hl]
	inc hl
	ld e, [hl]
	inc hl
	ld d, [hl]
	inc hl
	ld a, [hl]
	ld [wFollowerPalette], a
	ld c, FOLLOWER_SPRITE_TILES
	and a
	ret

; GetSprite-compatible data for SPRITE_FOLLOWER.
; Returns the same core registers as a 12-tile walking OverworldSprites entry.
GetFollowerSpriteData::
	call PrepareFollowerGFX
	ret c
	ld h, b
	ld l, WALKING_SPRITE
	scf
	ret

; Copy both 12-tile halves into the fixed bank-1 follower range.
; The general allocator is patched to avoid $74-$7f, so this cannot overwrite
; map sprites, trainers, fruit trees, or outdoor sprite graphics.
LoadFollowerGFX::
	call PrepareFollowerGFX
	ret c
	ldh a, [rVBK]
	push af
	xor a
	ldh [rVBK], a

	push de
	push bc
	ld hl, vTiles0 + FOLLOWER_VRAM_TILE * TILE_SIZE
	call Get2bpp
	pop bc
	pop de

	ld hl, FOLLOWER_SPRITE_TILES * TILE_SIZE
	add hl, de
	ld d, h
	ld e, l
	ld c, FOLLOWER_SPRITE_TILES
	ld hl, vTiles1 + FOLLOWER_VRAM_TILE * TILE_SIZE
	call Get2bpp

	pop af
	ldh [rVBK], a
	and a
	ret

; DE = 1-based graphics ID. Supports core IDs 1..251 and appended custom IDs.
SetFollowerGFXOverride::
	call ValidateFollowerGFXID
	ret c
	ld a, e
	ld [wFollowerOverrideGFXID], a
	ld a, d
	ld [wFollowerOverrideGFXID + 1], a
	ld a, FOLLOWER_OVERRIDE_MAGIC
	ld [wFollowerOverrideMagic], a
	jp RefreshFollowerGFX

ClearFollowerGFXOverride::
	xor a
	ld [wFollowerOverrideMagic], a
	ld [wFollowerOverrideGFXID], a
	ld [wFollowerOverrideGFXID + 1], a
	jp RefreshFollowerGFX

; Call after changing party order or changing a custom override on the same map.
RefreshFollowerGFX::
	call LoadFollowerGFX
	ret c
	ld a, [wObjectFollow_Follower]
	cp -1
	ret z
	call GetObjectStruct
	ld hl, OBJECT_PALETTE
	add hl, bc
	ld a, [hl]
	and ~OAM_PALETTE
	ld d, a
	ld a, [wFollowerPalette]
	and OAM_PALETTE
	or d
	ld [hl], a
	and a
	ret

