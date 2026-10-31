"""FloraLab ikon setini (SVG) üretir: assets/art/icons/ic_<ad>.svg.

Çalıştırma (depo kökünden):  python3 -I tools/art/make_icons.py

Tasarım dili (design/design-language.md, "İkonografi"):
- 48x48 ızgara, 3.5 çizgi kalınlığı, yuvarlak uç ve köşe; tek renk BEYAZ: oyunda `modulate` ile tema renginden boyanır.
- Dolu şekiller yalnızca durum/ödül işaretlerinde (yıldız, ışıltı, üçgen oklar); `ic_credit` kredinin KENDİ renkli simgesidir.
- Oyuncuya görünen hiçbir yerde Unicode sembol glifi (◆ ▲ ▼ ★ ✓ ×) kullanılmaz: cihazın yedek fontunda olmayabilir.
"""
import math
import os
import sys

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "art", "icons")
STROKE = "#FFFFFF"
W = 3.5


def svg(body: str, fill: str = "none") -> str:
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 48 48">'
        f'<g fill="{fill}" stroke="{STROKE}" stroke-width="{W}" stroke-linecap="round" stroke-linejoin="round">{body}</g></svg>\n'
    )


def solid(body: str) -> str:
    """Dolu şekil: çizgi yok, beyaz dolgu."""
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 48 48">'
        f'<g fill="#FFFFFF" stroke="#FFFFFF" stroke-width="2" stroke-linejoin="round">{body}</g></svg>\n'
    )


def radial(cx: float, cy: float, r0: float, r1: float, count: int, offset_deg: float = 0.0) -> str:
    parts = []
    for i in range(count):
        a = math.radians(offset_deg + i * 360.0 / count)
        parts.append(f'<path d="M{cx + r0 * math.cos(a):.2f} {cy + r0 * math.sin(a):.2f} L{cx + r1 * math.cos(a):.2f} {cy + r1 * math.sin(a):.2f}"/>')
    return "".join(parts)


def star(cx: float, cy: float, outer: float, inner: float, points: int = 5) -> str:
    coords = []
    for i in range(points * 2):
        r = outer if i % 2 == 0 else inner
        a = -math.pi / 2 + i * math.pi / points
        coords.append(f"{cx + r * math.cos(a):.2f},{cy + r * math.sin(a):.2f}")
    return f'<polygon points="{" ".join(coords)}"/>'


ICONS = {
    # --- sekmeler
    "farm": svg('<path d="M24 41V23"/><path d="M24 28C14 28 9 22 9 13C18 13 24 18 24 28Z"/><path d="M24 23C24 15 30 9 39 9C39 18 33 23 24 23Z"/><path d="M12 41H36"/>'),
    "lab": svg('<path d="M19 6H29"/><path d="M21 6V19L9 38C7 41 9 43 12 43H36C39 43 41 41 39 38L27 19V6"/><path d="M14 31H34"/><circle cx="21" cy="37" r="1" fill="#FFFFFF"/><circle cx="28" cy="35" r="1.4" fill="#FFFFFF"/>'),
    "market": svg('<path d="M8 8V40H41"/><path d="M13 31L22 21L28 27L39 13"/><path d="M32 13H39V20"/>'),
    "dex": svg('<path d="M11 7H35C37 7 39 9 39 11V41H15C12.8 41 11 39.2 11 37Z"/><path d="M11 37C11 34.8 12.8 33 15 33H39"/><path d="M25 14C30 15 31 21 25 26C19 21 20 15 25 14Z"/>'),
    "upgrades": svg('<path d="M24 40V13"/><path d="M13 23L24 12L35 23"/><path d="M12 43H36"/>'),
    # --- üst çubuk ve genel
    "menu": svg('<path d="M7 12H14M22 12H41"/><circle cx="18" cy="12" r="4"/><path d="M7 24H27M35 24H41"/><circle cx="31" cy="24" r="4"/><path d="M7 36H11M19 36H41"/><circle cx="15" cy="36" r="4"/>'),
    "close": svg('<path d="M13 13L35 35M35 13L13 35"/>'),
    "check": svg('<path d="M10 25L20 35L38 13"/>'),
    "lock": svg('<path d="M12 22H36V41H12Z"/><path d="M17 22V16C17 12 20 9 24 9C28 9 31 12 31 16V22"/><circle cx="24" cy="31" r="2" fill="#FFFFFF"/>'),
    "chevron_left": svg('<path d="M30 9L15 24L30 39"/>'),
    "chevron_right": svg('<path d="M18 9L33 24L18 39"/>'),
    "speed": svg('<path d="M9 11L21 24L9 37"/><path d="M25 11L37 24L25 37"/>'),
    "pause": svg('<path d="M16 10V38M32 10V38"/>'),
    "day": svg('<circle cx="24" cy="24" r="7"/>' + radial(24, 24, 12, 17, 8)),
    "night": svg('<path d="M31 8A16 16 0 1 0 40 30A13 13 0 0 1 31 8Z"/>'),
    "clock": svg('<circle cx="24" cy="24" r="16"/><path d="M24 14V24L31 28"/>'),
    "news": svg('<path d="M8 20V28H14L30 38V10L14 20Z"/><path d="M36 18C39 22 39 26 36 30"/>'),
    "star": solid(star(24, 25, 17, 7.5)),
    "sparkle": solid('<path d="M24 4C26 16 32 22 44 24C32 26 26 32 24 44C22 32 16 26 4 24C16 22 22 16 24 4Z"/>'),
    "trend_up": solid('<path d="M24 11L39 36H9Z"/>'),
    "trend_down": solid('<path d="M24 37L9 12H39Z"/>'),
    "flag": svg('<path d="M12 42V8"/><path d="M12 10H37L31 18L37 26H12"/>'),
    "target": svg('<circle cx="24" cy="24" r="16"/><circle cx="24" cy="24" r="8"/><circle cx="24" cy="24" r="1.5" fill="#FFFFFF"/>'),
    # --- çiftlik ve ekipman
    "water": svg('<path d="M24 6C24 6 11 20 11 30C11 37.2 16.8 43 24 43C31.2 43 37 37.2 37 30C37 20 24 6 24 6Z"/><path d="M18 31C18 34 20 36 23 36"/>'),
    "uv": svg('<path d="M24 5C15 5 10 12 13 20C15 24 17 26 17 30H31C31 26 33 24 35 20C38 12 33 5 24 5Z"/><path d="M19 35H29M21 40H27"/><path d="M24 12V21M20 16L24 12L28 16"/>'),
    "drone": svg('<circle cx="24" cy="24" r="5"/><path d="M20 20L12 12M28 20L36 12M20 28L12 36M28 28L36 36"/><circle cx="10" cy="10" r="4.5"/><circle cx="38" cy="10" r="4.5"/><circle cx="10" cy="38" r="4.5"/><circle cx="38" cy="38" r="4.5"/>'),
    "tower": svg('<path d="M12 42V10H36V42"/><path d="M7 42H41"/><path d="M19 17H21M27 17H29M19 25H21M27 25H29M19 33H21M27 33H29"/>'),
    "seed": svg('<path d="M24 7C37 13 39 30 24 43C9 30 11 13 24 7Z"/><path d="M24 17V35"/>'),
    "dna": svg('<path d="M14 5C14 20 34 28 34 43"/><path d="M34 5C34 20 14 28 14 43"/><path d="M17 12H31"/><path d="M19 24H29"/><path d="M17 36H31"/>'),
    "tag": svg('<path d="M8 8H24L40 24L24 40L8 24Z"/><circle cx="16" cy="16" r="2.6" fill="#FFFFFF"/>'),
    "order": svg('<path d="M13 10H35V42H13Z"/><path d="M19 6H29V12H19Z"/><path d="M19 23H29M19 30H29M19 37H25"/>'),
    "plant": svg('<path d="M24 42V26"/><path d="M24 31C17 31 13 27 13 20C20 20 24 24 24 31Z"/><path d="M24 26C24 19 28 14 35 14C35 21 31 26 24 26Z"/>'),
    # --- ayarlar
    "sound_on": svg('<path d="M8 19V29H15L26 38V10L15 19Z"/><path d="M32 18C35 21.5 35 26.5 32 30"/><path d="M37 13C42 19 42 29 37 35"/>'),
    "sound_off": svg('<path d="M8 19V29H15L26 38V10L15 19Z"/><path d="M33 18L43 30M43 18L33 30"/>'),
    "vibration": svg('<rect x="16" y="6" width="16" height="36" rx="4"/><path d="M8 16V32M40 16V32"/><path d="M3 21V27M45 21V27"/>'),
    "motion": svg('<path d="M6 24C11 14 17 14 24 24C31 34 37 34 42 24"/><path d="M6 32C11 22 17 22 24 32"/>'),
    "eye": svg('<path d="M4 24C10 14 17 10 24 10C31 10 38 14 44 24C38 34 31 38 24 38C17 38 10 34 4 24Z"/><circle cx="24" cy="24" r="6"/>'),
    "text_size": svg('<path d="M6 40L18 8L30 40"/><path d="M10.5 29H25.5"/><path d="M33 40L38 26L43 40"/><path d="M35 35.5H41"/>'),
    "globe": svg('<circle cx="24" cy="24" r="17"/><ellipse cx="24" cy="24" rx="7.5" ry="17"/><path d="M7 24H41M10 15H38M10 33H38"/>'),
    "trash": svg('<path d="M9 13H39"/><path d="M19 13V8H29V13"/><path d="M12 13L14 41H34L36 13"/><path d="M20 20V34M28 20V34"/>'),
    "info": svg('<circle cx="24" cy="24" r="17"/><path d="M24 22V33"/><circle cx="24" cy="15" r="1.6" fill="#FFFFFF"/>'),
}

# Kredi simgesi: renkli "öz kristali" (altıgen elmas). Tema renginden bağımsızdır (altın/kehribar).
CREDIT = """<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 48 48">
<defs>
<linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFE9A8"/><stop offset="1" stop-color="#F2A93B"/></linearGradient>
</defs>
<polygon points="14,7 34,7 44,19 24,43 4,19" fill="url(#g)" stroke="#B8741A" stroke-width="2.5" stroke-linejoin="round"/>
<polygon points="14,7 34,7 30,19 18,19" fill="#FFF6D6" fill-opacity="0.8"/>
<polygon points="4,19 18,19 24,43" fill="#E39B2C" fill-opacity="0.45"/>
<polygon points="44,19 30,19 24,43" fill="#B8741A" fill-opacity="0.4"/>
<path d="M4 19H44M14 7L18 19L24 43L30 19L34 7" fill="none" stroke="#B8741A" stroke-width="1.8" stroke-linejoin="round" stroke-opacity="0.75"/>
</svg>
"""


def main() -> int:
    os.makedirs(OUT, exist_ok=True)
    for name, text in ICONS.items():
        with open(os.path.join(OUT, f"ic_{name}.svg"), "w", encoding="utf-8") as handle:
            handle.write(text)
    with open(os.path.join(OUT, "ic_credit.svg"), "w", encoding="utf-8") as handle:
        handle.write(CREDIT)
    print(f"{len(ICONS) + 1} ikon yazıldı: {os.path.abspath(OUT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
