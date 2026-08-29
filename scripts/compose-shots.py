#!/usr/bin/env python3
"""Compose English product shots onto a dark studio background."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs"
SHOTS = Path("/tmp/checkusage-shots")
BG = Path(
    "/Users/sysrootix/.cursor/projects/Users-sysrootix-orca-projects-check-usage/assets/checkusage-bg-4x3.png"
)
SF = "/System/Library/Fonts/SFNS.ttf"
HN = "/System/Library/Fonts/HelveticaNeue.ttc"


def crop_alpha(im: Image.Image, pad: int = 0) -> Image.Image:
    a = im.split()[-1]
    box = a.point(lambda p: 255 if p > 16 else 0).getbbox()
    if not box:
        return im
    l, t, r, b = box
    return im.crop((max(0, l - pad), max(0, t - pad), min(im.width, r + pad), min(im.height, b + pad)))


def font(size: int, index: int = 0) -> ImageFont.FreeTypeFont:
    try:
        return ImageFont.truetype(SF, size)
    except OSError:
        return ImageFont.truetype(HN, size, index=index)


def shadow(im: Image.Image, blur: int = 36, opacity: int = 170, dy: int = 18) -> Image.Image:
    pad = blur * 3 + abs(dy)
    canvas = Image.new("RGBA", (im.width + pad * 2, im.height + pad * 2 + dy), (0, 0, 0, 0))
    mask = im.split()[-1]
    shade = Image.new("RGBA", im.size, (0, 0, 0, opacity))
    shade.putalpha(mask.point(lambda p: int(p * opacity / 255)))
    canvas.paste(shade, (pad, pad + dy), shade)
    canvas = canvas.filter(ImageFilter.GaussianBlur(blur))
    canvas.paste(im, (pad, pad), im)
    return canvas


def cover(src: Image.Image, size: tuple[int, int]) -> Image.Image:
    tw, th = size
    scale = max(tw / src.width, th / src.height)
    w, h = int(src.width * scale), int(src.height * scale)
    resized = src.resize((w, h), Image.Resampling.LANCZOS)
    x = (w - tw) // 2
    y = (h - th) // 2
    return resized.crop((x, y, x + tw, y + th))


def paste(base: Image.Image, piece: Image.Image, xy: tuple[int, int]) -> None:
    base.alpha_composite(piece, xy)


def main() -> None:
    popover = crop_alpha(Image.open(SHOTS / "popover.png").convert("RGBA"))
    pill = crop_alpha(Image.open(SHOTS / "pill.png").convert("RGBA"))
    studio = Image.open(BG).convert("RGBA")

    popover_s = shadow(popover, blur=42, opacity=190, dy=22)
    pill_s = shadow(pill, blur=32, opacity=170, dy=16)

    # README hero — 4:3, product only
    hero_w, hero_h = 2400, 1800
    hero = cover(studio, (hero_w, hero_h))
    gap = 28
    cluster_w = popover_s.width + gap + pill_s.width
    cluster_h = max(popover_s.height, pill_s.height)
    ox = (hero_w - cluster_w) // 2
    oy = (hero_h - cluster_h) // 2 + 20
    paste(hero, popover_s, (ox, oy))
    paste(hero, pill_s, (ox + popover_s.width + gap, oy + 36))
    hero.convert("RGB").resize((1600, 1200), Image.Resampling.LANCZOS).save(
        OUT / "screenshot.jpg", "JPEG", quality=90, optimize=True, progressive=True
    )

    # Tight pill
    panel_w, panel_h = 720, 1100
    panel = cover(studio, (panel_w, panel_h))
    px = (panel_w - pill_s.width) // 2
    py = (panel_h - pill_s.height) // 2
    paste(panel, pill_s, (px, py))
    panel.convert("RGB").save(OUT / "screenshot-panel.png", "PNG", optimize=True)

    # 16:9 — wordmark + product (README wide + X)
    wide_w, wide_h = 2880, 1620
    wide = cover(studio, (wide_w, wide_h))
    draw = ImageDraw.Draw(wide)
    title = font(92)
    sub = font(30)
    word = "CheckUsage"
    tag = "AI usage limits on your Mac."
    line = "No extra login.  No telemetry."
    left = 168
    title_y = 560
    draw.text((left, title_y), word, fill=(255, 255, 255, 235), font=title)
    tw = draw.textlength(word, font=title)
    draw.rectangle((left, title_y + 118, left + min(72, tw), title_y + 121), fill=(56, 214, 102, 210))
    draw.text((left, title_y + 148), tag, fill=(210, 210, 214, 210), font=sub)
    draw.text((left, title_y + 196), line, fill=(150, 150, 156, 190), font=sub)

    scale = 0.92
    pop_w = int(popover_s.width * scale)
    pop_h = int(popover_s.height * scale)
    pill_w = int(pill_s.width * scale)
    pill_h = int(pill_s.height * scale)
    pop = popover_s.resize((pop_w, pop_h), Image.Resampling.LANCZOS)
    pl = pill_s.resize((pill_w, pill_h), Image.Resampling.LANCZOS)
    ux = 1320
    uy = (wide_h - max(pop_h, pill_h)) // 2
    paste(wide, pop, (ux, uy))
    paste(wide, pl, (ux + pop_w + 18, uy + 28))
    card = wide.convert("RGB").resize((1920, 1080), Image.Resampling.LANCZOS)
    card.save(OUT / "screenshot-wide.jpg", "JPEG", quality=90, optimize=True, progressive=True)
    card.save(OUT / "x-card.jpg", "JPEG", quality=90, optimize=True, progressive=True)

    for p in (OUT / "screenshot.jpg", OUT / "screenshot-wide.jpg", OUT / "screenshot-panel.png", OUT / "x-card.jpg"):
        im = Image.open(p)
        print(p.name, im.size, p.stat().st_size)


if __name__ == "__main__":
    main()
