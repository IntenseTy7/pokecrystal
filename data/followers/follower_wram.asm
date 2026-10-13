; Replace the existing anonymous `ds 40` immediately after wCmdQueue with
; these labels. Total size remains exactly 40 bytes; no WRAM/save addresses move.
wFollowerOverrideMagic:: db
wFollowerOverrideGFXID:: dw
wFollowerResolvedGFXID:: dw
wFollowerPalette:: db
	ds 34
assert @ - wFollowerOverrideMagic == 40
