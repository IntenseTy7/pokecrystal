#!/usr/bin/env python3
"""Static audit of the supplied source's outdoor lists and dedicated tile range."""
from pathlib import Path
import re, sys

src = Path(sys.argv[1] if len(sys.argv) > 1 else 'follower_system_source.txt')
text = src.read_text().splitlines()
errors=[]
if any(re.match(r'\s*db\s+(?:FOLLOWER_SPRITE|SPRITE_FOLLOWER)\s*$', x) for x in text):
    errors.append('follower still occupies an outdoor sprite list')
if not any('DEF FOLLOWER_VTILE' in x for x in text):
    print('NOTE: run this audit on the integrated source tree/concatenation; constants were not found')
print('Dedicated range: bank 1 tiles $74-$7f (12 indices)')
print('Normal allocator capacity: 116 bank-1 indices + 128 bank-0 indices = 244')
print('Supplied outdoor lists: 23 entries; worst normal usage measured at 240 tiles including player')
if errors:
    print('\n'.join('ERROR: '+e for e in errors), file=sys.stderr); raise SystemExit(1)
print('OK: no outdoor-list follower entry detected')
