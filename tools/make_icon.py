#!/usr/bin/env python3
"""Zeichnet das App-Icon (Sonnenuntergang, Meer, Palme, Radiowellen)."""
import math, os, sys
from PIL import Image, ImageDraw, ImageFilter
S = 1024
out = sys.argv[1] if len(sys.argv) > 1 else "ViceStation/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
img = Image.new("RGB", (S, S))
d = ImageDraw.Draw(img)
stops = [(0, (91, 42, 134)), (0.35, (214, 47, 158)), (0.55, (255, 61, 139)), (0.68, (255, 138, 61))]
def lerp(a, b, t): return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))
for y in range(S):
    t = y / S
    for i in range(len(stops) - 1):
        if stops[i][0] <= t <= stops[i + 1][0]:
            c = lerp(stops[i][1], stops[i + 1][1], (t - stops[i][0]) / (stops[i + 1][0] - stops[i][0])); break
    else:
        c = stops[-1][1]
    d.line([(0, y), (S, y)], fill=c)
# Sonne
glow = Image.new("L", (S, S), 0); g = ImageDraw.Draw(glow)
g.ellipse([S*0.22, S*0.36, S*0.78, S*0.92], fill=255)
glow = glow.filter(ImageFilter.GaussianBlur(40))
img.paste(Image.new("RGB", (S, S), (255, 227, 179)), (0, 0), glow)
# Meer
sea_top = int(S * 0.68)
for y in range(sea_top, S):
    t = (y - sea_top) / (S - sea_top)
    d.line([(0, y), (S, y)], fill=lerp((25, 227, 211), (11, 40, 70), t))
for i in range(9):
    y = sea_top + 14 + i * 26; w = S * (0.42 - i * 0.04)
    d.rounded_rectangle([S/2 - w/2, y, S/2 + w/2, y + 6], 3, fill=(255, 227, 179))
# Palme
pal = (20, 8, 30)
d.polygon([(150, S), (215, S), (330, 330), (310, 325)], fill=pal)
top = (320, 328)
for ang, ln in [(-170, 300), (-140, 280), (-100, 200), (-60, 240), (-25, 300), (5, 310), (35, 250), (150, 230)]:
    r = math.radians(ang); tip = (top[0] + math.cos(r) * ln, top[1] + math.sin(r) * ln + 70)
    n = (-math.sin(r) * 30, math.cos(r) * 30)
    mid = (top[0] + math.cos(r) * ln * 0.5, top[1] + math.sin(r) * ln * 0.5 - 20)
    d.polygon([top, (mid[0] + n[0], mid[1] + n[1]), tip, (mid[0] - n[0], mid[1] - n[1])], fill=pal)
# Radiowellen
cx, cy = 700, 300
for i, r in enumerate([70, 130, 190]):
    d.arc([cx - r, cy - r, cx + r, cy + r], -55, 55, fill=(255, 255, 255), width=26 - i * 4)
    d.arc([cx - r, cy - r, cx + r, cy + r], 125, 235, fill=(255, 255, 255), width=26 - i * 4)
d.ellipse([cx - 32, cy - 32, cx + 32, cy + 32], fill=(25, 227, 211))
os.makedirs(os.path.dirname(out), exist_ok=True)
img.save(out)
print(out)
