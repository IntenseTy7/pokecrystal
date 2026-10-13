#!/usr/bin/env python3
"""Validate the dedicated follower manifest and 384-byte graphics sheets."""
from pathlib import Path
import argparse, csv, sys

ALLOWED_PALETTES = {
    'PAL_OW_RED', 'PAL_OW_BLUE', 'PAL_OW_GREEN', 'PAL_OW_BROWN',
    'PAL_OW_ROCK', 'PAL_OW_TREE', 'PAL_OW_EMOTE',
}
CORE_COUNT = 251
EXPECTED_SIZE = 12 * 16 * 2

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--repo', type=Path, default=Path('.'))
    ap.add_argument('--manifest', type=Path,
                    default=Path('data/followers/follower_gfx_manifest.csv'))
    ap.add_argument('--allow-missing-assets', action='store_true')
    args = ap.parse_args()
    manifest = args.manifest
    if not manifest.is_absolute(): manifest = args.repo / manifest
    rows = list(csv.DictReader(manifest.open(newline='')))
    errors = []
    ids, labels, paths = set(), set(), set()
    for pos,row in enumerate(rows,1):
        try: ident = int(row['id'])
        except Exception:
            errors.append(f'row {pos}: invalid id'); continue
        if ident != pos:
            errors.append(f'row {pos}: id {ident} is not contiguous')
        if ident in ids: errors.append(f'row {pos}: duplicate id {ident}')
        ids.add(ident)
        label = row['label_stem']
        if label in labels: errors.append(f'row {pos}: duplicate label {label}')
        labels.add(label)
        rel = Path(row['asset_path'])
        if rel.is_absolute() or '..' in rel.parts:
            errors.append(f'row {pos}: unsafe asset path {rel}')
        if str(rel) in paths: errors.append(f'row {pos}: duplicate path {rel}')
        paths.add(str(rel))
        if row['palette'] not in ALLOWED_PALETTES:
            errors.append(f'row {pos}: unsupported palette {row["palette"]}')
        asset = args.repo / rel
        if not asset.exists():
            if not args.allow_missing_assets:
                errors.append(f'row {pos}: missing {rel}')
        elif asset.stat().st_size != EXPECTED_SIZE:
            errors.append(f'row {pos}: {rel} is {asset.stat().st_size} bytes; expected {EXPECTED_SIZE}')
    if len(rows) < CORE_COUNT:
        errors.append(f'manifest has {len(rows)} rows; needs at least {CORE_COUNT}')
    if rows and rows[0]['species_symbol'] != 'BULBASAUR':
        errors.append('core table must begin with BULBASAUR')
    if len(rows) >= CORE_COUNT and rows[CORE_COUNT-1]['species_symbol'] != 'CELEBI':
        errors.append('core entry 251 must be CELEBI')
    if errors:
        print('\n'.join('ERROR: '+e for e in errors), file=sys.stderr)
        return 1
    print(f'OK: {len(rows)} contiguous entries; core 1..251 intact; each present asset is {EXPECTED_SIZE} bytes')
    return 0
if __name__ == '__main__': raise SystemExit(main())
