RunMapSetupScript::
	ldh a, [hMapEntryMethod]
	and $f
	dec a
	ld c, a
	ld b, 0
	ld hl, MapSetupScripts
	add hl, bc
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call ReadMapSetupScript
	ret

INCLUDE "data/maps/setup_scripts.asm"

ReadMapSetupScript:
.loop
	ld a, [hli]
	cp -1 ; end?
	ret z

	push hl

	ld c, a
	ld b, 0
	ld hl, MapSetupCommands
	add hl, bc
	add hl, bc
	add hl, bc

	; bank
	ld b, [hl]
	inc hl

	; address
	ld a, [hli]
	ld h, [hl]
	ld l, a

	; Bit 7 of the bank indicates a parameter.
	; This is left unused.
	bit MAPSETUPSCRIPT_HAS_PARAM_F, b
	jr z, .go

	pop de
	ld a, [de]
	ld c, a
	inc de
	push de

.go
	ld a, b
	and $7f
	rst FarCall

	pop hl
	jr .loop

INCLUDE "data/maps/setup_script_pointers.asm"

EnableTextAcceleration:
	xor a
	ld [wDisableTextAcceleration], a
	ret

ActivateMapAnims:
	ld a, TRUE
	ldh [hMapAnims], a
	ret

SuspendMapAnims:
	xor a ; FALSE
	ldh [hMapAnims], a
	ret

LoadMapObjects:
	ld a, MAPCALLBACK_OBJECTS
	call RunMapCallback
	farcall LoadObjectMasks
	farcall PlaceFollowerObject
	farcall InitializeVisibleSprites
	farcall StartFollowerObject
	call UpdatePlayerSprite
	ret

MapSetup_DummyFunction: ; unreferenced
	ret

ResetPlayerObjectAction:
	ld hl, wPlayerSpriteSetupFlags
	set PLAYERSPRITESETUP_RESET_ACTION_F, [hl]
	ret

SkipUpdateMapSprites:
	ld hl, wPlayerSpriteSetupFlags
	set PLAYERSPRITESETUP_SKIP_RELOAD_GFX_F, [hl]
	ret

CheckUpdatePlayerSprite:
	nop
	call .CheckForcedBiking
	jr c, .ok
	call .CheckSurfing
	jr c, .ok
	call .ResetSurfingOrBikingState
	jr c, .ok
	ret

.ok
	call UpdatePlayerSprite
	ret

.CheckForcedBiking:
	and a
	ld hl, wBikeFlags
	bit BIKEFLAGS_ALWAYS_ON_BIKE_F, [hl]
	ret z
	ld a, PLAYER_BIKE
	ld [wPlayerState], a
	scf
	ret

.ResetSurfingOrBikingState:
	ld a, [wPlayerState]
	cp PLAYER_NORMAL
	jr z, .nope
	cp PLAYER_SKATE
	jr z, .nope
	cp PLAYER_SURF
	jr z, .surfing
	cp PLAYER_SURF_PIKA
	jr z, .surfing
	call GetMapEnvironment
	cp INDOOR
	jr z, .no_biking
	cp ENVIRONMENT_5
	jr z, .no_biking
	cp DUNGEON
	jr z, .no_biking
	jr .nope
.no_biking
	ld a, [wPlayerState]
	cp PLAYER_BIKE
	jr nz, .nope
.surfing
	ld a, PLAYER_NORMAL
	ld [wPlayerState], a
	scf
	ret

.nope
	and a
	ret

.CheckSurfing:
	call CheckOnWater
	jr nz, .nope2
	ld a, [wPlayerState]
	cp PLAYER_SURF
	jr z, .is_surfing
	cp PLAYER_SURF_PIKA
	jr z, .is_surfing
	ld a, PLAYER_SURF
	ld [wPlayerState], a
.is_surfing
	scf
	ret

.nope2
	and a
	ret

FadeOutMapMusic:
	ld a, 6
	call SkipMusic
	ret

ApplyMapPalettes:
	farcall _UpdateTimePals
	ret

FadeMapMusicAndPalettes:
	ld e, LOW(MUSIC_NONE)
	ld a, [wMusicFadeID]
	ld d, HIGH(MUSIC_NONE)
	ld a, [wMusicFadeID + 1]
	ld a, $4
	ld [wMusicFade], a
	call RotateThreePalettesRight
	ret

ForceMapMusic:
	ld a, [wPlayerState]
	cp PLAYER_BIKE
	jr nz, .notbiking
	call MinVolume
	ld a, $88
	ld [wMusicFade], a
.notbiking
	call TryRestartMapMusic
	ret

PUSHS
SECTION "Follower", ROMX

FollowerObjectTemplate:
    object_event 0, 0, FOLLOWER_SPRITE, SPRITEMOVEDATA_STILL, 0, 0, -1, -1, 0, OBJECTTYPE_SCRIPT, 0, FollowerDummyScript, -1

AddFollowerObject::
	ld a, SPRITE_FAIRY
	ld [wVariableSprites + SPRITE_FOLLOWER - SPRITE_VARS], a
    ld a, [wCurMapObjectEventCount]
    cp NUM_OBJECTS - 1
    ret nc
    ld hl, wMap1Object
    and a
    jr z, .found
    ld de, MAPOBJECT_LENGTH
.next
    add hl, de
    dec a
    jr nz, .next
.found
    ld a, $ff
    ld [hli], a
    ld de, FollowerObjectTemplate
    ld b, OBJECT_EVENT_SIZE
.copy
    ld a, [de]
    inc de
    ld [hli], a
    dec b
    jr nz, .copy
    ld hl, wCurMapObjectEventCount
    inc [hl]
    ret

FindFollowerSlot:
    ld a, [wCurMapObjectEventCount]
    and a
    jr z, .none
    dec a
    ld hl, wMap1Object
    jr z, .check
    ld de, MAPOBJECT_LENGTH
.next
    add hl, de
    dec a
    jr nz, .next
.check
    push hl
    ld de, 1 + OBJECT_EVENT_SIZE - 4
    add hl, de
    ld de, FollowerObjectTemplate + OBJECT_EVENT_SIZE - 4
    ld b, 4
.compare
    ld a, [de]
    inc de
    cp [hl]
    jr nz, .mismatch
    inc hl
    dec b
    jr nz, .compare
    pop hl
    and a
    ret
.mismatch
    pop hl
.none
    scf
    ret

PlaceFollowerObject::
    call FindFollowerSlot
    ret c
    push hl
    ld de, MAPOBJECT_Y_COORD
    add hl, de
    ld a, [wYCoord]
    add 4
    ld [hl], a
    pop hl
    ld de, MAPOBJECT_X_COORD
    add hl, de
    ld a, [wXCoord]
    add 4
    ld [hl], a
    ret

StartFollowerObject::
    call FindFollowerSlot
    ret c
    ld a, [wCurMapObjectEventCount]
    ld c, a
    ld b, 0
    farcall StartFollow
    ret

RespawnFollowerObject::
    call FindFollowerSlot
    ret c
    ld a, [wCurMapObjectEventCount]
    ldh [hMapObjectIndex], a
    call DeleteObjectStruct
    call PlaceFollowerObject
    ld a, [wCurMapObjectEventCount]
    call UnmaskCopyMapObjectStruct
    jp StartFollowerObject
POPS

PUSHS
SECTION "Follower Dummy Script", ROM0
FollowerDummyScript::
    end
POPS
