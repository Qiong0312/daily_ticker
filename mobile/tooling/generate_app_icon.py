#!/usr/bin/env python3
"""Generate Daily Ticker app icons: white thick check on orange (matches Today task badge)."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

# Matches completed-task badge in today_view.dart (circle behind Icons.check)
ORANGE = (251, 191, 36)  # 0xFFFBBF24
WHITE = (255, 255, 255)

ROOT = Path(__file__).resolve().parent.parent


def _draw_check(draw: ImageDraw.ImageDraw, size: int) -> None:
    w = h = size
    stroke = max(2, int(size * 0.16))
    points = [
        (w * 0.22, h * 0.52),
        (w * 0.42, h * 0.72),
        (w * 0.78, h * 0.28),
    ]
    draw.line(points, fill=WHITE, width=stroke, joint="curve")
    cap_r = stroke // 2
    for x, y in (points[0], points[-1]):
        draw.ellipse(
            (x - cap_r, y - cap_r, x + cap_r, y + cap_r),
            fill=WHITE,
        )


def draw_icon(size: int) -> Image.Image:
    img = Image.new("RGB", (size, size), ORANGE)
    _draw_check(ImageDraw.Draw(img), size)
    return img


def draw_foreground(size: int) -> Image.Image:
    """White check only (for Android adaptive icon foreground)."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    _draw_check(ImageDraw.Draw(img), size)
    return img


def write_ios_icons(master: Image.Image) -> None:
    ios_dir = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    specs: list[tuple[str, int]] = [
        ("Icon-App-20x20@1x.png", 20),
        ("Icon-App-20x20@2x.png", 40),
        ("Icon-App-20x20@3x.png", 60),
        ("Icon-App-29x29@1x.png", 29),
        ("Icon-App-29x29@2x.png", 58),
        ("Icon-App-29x29@3x.png", 87),
        ("Icon-App-40x40@1x.png", 40),
        ("Icon-App-40x40@2x.png", 80),
        ("Icon-App-40x40@3x.png", 120),
        ("Icon-App-60x60@2x.png", 120),
        ("Icon-App-60x60@3x.png", 180),
        ("Icon-App-76x76@1x.png", 76),
        ("Icon-App-76x76@2x.png", 152),
        ("Icon-App-83.5x83.5@2x.png", 167),
        ("Icon-App-1024x1024@1x.png", 1024),
    ]
    for name, px in specs:
        out = master.resize((px, px), Image.Resampling.LANCZOS)
        out.save(ios_dir / name, "PNG")
    print(f"wrote {len(specs)} iOS icons -> {ios_dir}")


def write_macos_icons(master: Image.Image) -> None:
    mac_dir = ROOT / "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    specs: list[tuple[str, int]] = [
        ("app_icon_16.png", 16),
        ("app_icon_32.png", 32),
        ("app_icon_64.png", 64),
        ("app_icon_128.png", 128),
        ("app_icon_256.png", 256),
        ("app_icon_512.png", 512),
        ("app_icon_1024.png", 1024),
    ]
    for name, px in specs:
        out = master.resize((px, px), Image.Resampling.LANCZOS)
        out.save(mac_dir / name, "PNG")
    print(f"wrote {len(specs)} macOS icons -> {mac_dir}")


def write_android_icons(master: Image.Image) -> None:
    res = ROOT / "android/app/src/main/res"
    densities: list[tuple[str, int]] = [
        ("mipmap-mdpi", 48),
        ("mipmap-hdpi", 72),
        ("mipmap-xhdpi", 96),
        ("mipmap-xxhdpi", 144),
        ("mipmap-xxxhdpi", 192),
    ]
    for folder, px in densities:
        out_dir = res / folder
        out_dir.mkdir(parents=True, exist_ok=True)
        icon = master.resize((px, px), Image.Resampling.LANCZOS)
        icon.save(out_dir / "ic_launcher.png", "PNG")
    fg_dir = res / "drawable-nodpi"
    fg_dir.mkdir(parents=True, exist_ok=True)
    draw_foreground(432).save(fg_dir / "ic_launcher_foreground.png", "PNG")
    print(f"wrote Android launcher icons -> {res}")


def main() -> None:
    master = draw_icon(1024)
    preview = ROOT / "tooling/app_icon_preview_1024.png"
    master.save(preview, "PNG")
    print(f"preview -> {preview}")
    write_ios_icons(master)
    write_macos_icons(master)
    write_android_icons(master)


if __name__ == "__main__":
    main()
