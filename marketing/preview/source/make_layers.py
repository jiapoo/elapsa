"""Background, rounded screen mask and caption PNGs for the captioned preview.

    python3 make_layers.py <out folder> <en|zh|zh-hant>
"""
import sys
from PIL import Image, ImageDraw, ImageFont

OUT, LANG = sys.argv[1], sys.argv[2]
W, H = 886, 1920
CRIMSON = (221, 27, 63)
SCREEN_X, SCREEN_Y, SCREEN_W = 104, 409, 678
SCREEN_H = round(2868 * SCREEN_W / 1320)
RADIUS = 46

CAPTIONS = {
    "en": [
        "Your passport expires\n6 months before\nit says it does.",
        "Told when to start\nrenewing, not when\nit's too late.",
        "Reminders months\nahead, as many as\nyou like.",
        "No account. No upload.\nEncrypted on\nyour phone.",
    ],
    "zh": [
        "你的护照，\n其实早六个月\n就“过期”了。",
        "该开始办的时候\n就提醒你，\n不等来不及。",
        "提前几个月提醒，\n想设几个\n就设几个。",
        "不用注册，不上传。\n数据加密，\n只存在你的手机里。",
    ],
    "zh-hant": [
        "你的護照，\n其實早六個月\n就「過期」了。",
        "該開始辦的時候\n就提醒你，\n不等來不及。",
        "提前幾個月提醒，\n想設幾個\n就設幾個。",
        "不用註冊，不上傳。\n資料加密，\n只存在你的手機裡。",
    ],
}


def caption_font():
    if LANG == "zh-hant":
        # Heiti TC Medium (face 0): Traditional character shapes.
        return ImageFont.truetype("/System/Library/Fonts/STHeiti Medium.ttc", 60, index=0)
    if LANG == "zh":
        # Hiragino Sans GB W6 (face 2): a bold Simplified Chinese system font.
        return ImageFont.truetype("/System/Library/Fonts/Hiragino Sans GB.ttc", 60, index=2)
    font = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", 62)
    try:
        font.set_variation_by_name("Bold")
    except Exception:
        pass
    return font


Image.new("RGB", (W, H), CRIMSON).save(f"{OUT}/bg.png")

mask = Image.new("L", (SCREEN_W, SCREEN_H), 0)
ImageDraw.Draw(mask).rounded_rectangle(
    (0, 0, SCREEN_W - 1, SCREEN_H - 1), radius=RADIUS, fill=255)
mask.save(f"{OUT}/mask.png")

font = caption_font()
spacing = 18 if LANG.startswith("zh") else 10
# Heiti TC has no bold weight, so its strokes are thickened to match the others.
stroke = 1 if LANG == "zh-hant" else 0
for i, text in enumerate(CAPTIONS[LANG]):
    img = Image.new("RGBA", (W, SCREEN_Y), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    box = d.multiline_textbbox((0, 0), text, font=font, align="center", spacing=spacing,
                               stroke_width=stroke)
    tw, th = box[2] - box[0], box[3] - box[1]
    x = (W - tw) / 2 - box[0]
    y = (SCREEN_Y - th) / 2 - box[1]
    d.multiline_text((x, y), text, font=font, fill="white", align="center", spacing=spacing,
                     stroke_width=stroke, stroke_fill="white")
    img.save(f"{OUT}/cap{i}.png")

print(SCREEN_H)
