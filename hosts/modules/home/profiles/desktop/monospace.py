import sys

from fontTools.ttLib import TTFont

source, destination = sys.argv[1], sys.argv[2]

font = TTFont(source)
hmtx = font["hmtx"]
encoded = set(font.getBestCmap().values())

target = max(hmtx[name][0] for name in encoded)

for name in font.getGlyphOrder():
    advance, bearing = hmtx[name]
    if advance > 0:
        hmtx[name] = (target, bearing)

font["post"].isFixedPitch = 1
font["OS/2"].panose.bProportion = 9

font.save(destination)
print(target, font["head"].unitsPerEm)
