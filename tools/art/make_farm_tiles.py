"""FloraLab çiftlik karo atlasını (SVG) üretir: assets/art/farm/farm_tiles.svg.

Çalıştırma (depo kökünden):  python3 -I tools/art/make_farm_tiles.py

Atlas: 6 karo yan yana, her biri 180x180 piksel (Godot TileSet bölgesi = 180x180).
  0 zemin paneli        3 ıslak saksı
  1 UV lamba şeridi     4 kuru saksı + boru
  2 kuru saksı          5 ıslak saksı + boru
Saksı karolarında bitki tabanı (90, 116) noktasındadır (FarmView bu noktaya PlantInstance koyar).
Renkler koyu siber paletle uyumludur; bitki renkleri oyunda `modulate` ile gelir, karolar sabittir.
"""
import sys

TILE = 180
TILE_COUNT = 6

DEFS = """
  <linearGradient id="panel" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#14251f"/><stop offset="1" stop-color="#0a1512"/>
  </linearGradient>
  <linearGradient id="lamp" x1="0" y1="0" x2="1" y2="0">
    <stop offset="0" stop-color="#8f4dff"/><stop offset="0.5" stop-color="#e2b8ff"/><stop offset="1" stop-color="#8f4dff"/>
  </linearGradient>
  <radialGradient id="lampGlow" cx="0.5" cy="0.5" r="0.5">
    <stop offset="0" stop-color="#b37bff" stop-opacity="0.75"/><stop offset="1" stop-color="#b37bff" stop-opacity="0"/>
  </radialGradient>
  <linearGradient id="cone" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#a66bff" stop-opacity="0.32"/><stop offset="1" stop-color="#a66bff" stop-opacity="0"/>
  </linearGradient>
  <linearGradient id="pot" x1="0" y1="0" x2="1" y2="0">
    <stop offset="0" stop-color="#22362f"/><stop offset="0.45" stop-color="#52786a"/><stop offset="1" stop-color="#1f2f29"/>
  </linearGradient>
  <linearGradient id="pipe" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#6ea3b8"/><stop offset="0.5" stop-color="#34596b"/><stop offset="1" stop-color="#244354"/>
  </linearGradient>
  <linearGradient id="pipeWet" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#8fe8ff"/><stop offset="0.5" stop-color="#2f9fcd"/><stop offset="1" stop-color="#1f6f96"/>
  </linearGradient>
  <linearGradient id="water" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#6fdcff"/><stop offset="1" stop-color="#2290c8"/>
  </linearGradient>
"""


def panel(x0: int) -> str:
    return f"""
  <g transform="translate({x0},0)">
    <rect width="{TILE}" height="{TILE}" fill="url(#panel)"/>
    <rect x="7" y="7" width="166" height="166" rx="8" fill="none" stroke="#2a4d40" stroke-width="2"/>
    <rect x="20" y="20" width="140" height="140" rx="6" fill="none" stroke="#1b362d" stroke-width="1.5" stroke-dasharray="6 8"/>
    <circle cx="16" cy="16" r="3" fill="#34594b"/><circle cx="164" cy="16" r="3" fill="#34594b"/>
    <circle cx="16" cy="164" r="3" fill="#34594b"/><circle cx="164" cy="164" r="3" fill="#34594b"/>
    <polygon points="0,0 74,0 0,92" fill="#ffffff" opacity="0.025"/>
  </g>"""


def lamp(x0: int) -> str:
    return f"""
  <g transform="translate({x0},0)">
    <rect width="{TILE}" height="{TILE}" fill="url(#panel)"/>
    <polygon points="30,44 150,44 176,180 4,180" fill="url(#cone)"/>
    <ellipse cx="90" cy="40" rx="86" ry="34" fill="url(#lampGlow)"/>
    <rect x="22" y="0" width="136" height="12" fill="#2a443a"/>
    <rect x="12" y="12" width="156" height="26" rx="13" fill="url(#lamp)"/>
    <rect x="22" y="17" width="136" height="6" rx="3" fill="#ffffff" opacity="0.55"/>
    <circle cx="16" cy="164" r="3" fill="#34594b"/><circle cx="164" cy="164" r="3" fill="#34594b"/>
  </g>"""


def pot(x0: int, wet: bool, piped: bool) -> str:
    water_h = 20 if wet else 4
    water_y = 148 - water_h
    water_fill = "url(#water)" if wet else "#6a5a44"
    pipe = ""
    if piped:
        grad = "url(#pipeWet)" if wet else "url(#pipe)"
        pipe = f"""
    <rect x="0" y="134" width="46" height="16" fill="{grad}"/>
    <rect x="40" y="129" width="7" height="26" rx="2" fill="#7fa1b3"/>
    <rect x="134" y="134" width="46" height="16" fill="{grad}"/>
    <rect x="133" y="129" width="7" height="26" rx="2" fill="#7fa1b3"/>"""
    return f"""
  <g transform="translate({x0},0)">
    <rect width="{TILE}" height="{TILE}" fill="url(#panel)"/>
    <rect x="0" y="162" width="{TILE}" height="18" fill="#0f1c18"/>
    <rect x="0" y="160" width="{TILE}" height="3" fill="#2f6b55"/>{pipe}
    <path d="M38,114 L142,114 L132,162 L48,162 Z" fill="url(#pot)" stroke="#a3cdb9" stroke-width="2" stroke-linejoin="round"/>
    <ellipse cx="90" cy="114" rx="52" ry="10" fill="#80ab97"/>
    <ellipse cx="90" cy="114" rx="43" ry="7" fill="{'#17323f' if wet else '#2f261d'}"/>
    <rect x="62" y="124" width="56" height="26" rx="7" fill="#07120e" stroke="#86b9a2" stroke-width="2"/>
    <rect x="65" y="{water_y}" width="50" height="{water_h}" rx="4" fill="{water_fill}"/>
    <rect x="68" y="{water_y + 2}" width="26" height="3" rx="1.5" fill="#ffffff" opacity="{0.5 if wet else 0.0}"/>
  </g>"""


def build() -> str:
    parts = [panel(0), lamp(TILE), pot(2 * TILE, False, False), pot(3 * TILE, True, False), pot(4 * TILE, False, True), pot(5 * TILE, True, True)]
    width = TILE * TILE_COUNT
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{TILE}" viewBox="0 0 {width} {TILE}">\n  <defs>{DEFS}  </defs>' + "".join(parts) + "\n</svg>\n"


if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else "assets/art/farm/farm_tiles.svg"
    import os

    os.makedirs(os.path.dirname(target), exist_ok=True)
    with open(target, "w", encoding="utf-8") as handle:
        handle.write(build())
    print("yazıldı:", target)
