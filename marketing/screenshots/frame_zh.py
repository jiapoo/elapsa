"""Captioned App Store screenshots for Elapsa in 简体 and 繁體, matching the English set.

    python3 frame_zh.py <raw root with zh/ and zh-hant/> <out root>

Writes <out>/6.9-captioned-<lang>/ (1320x2868) and <out>/6.3-captioned-<lang>/ (1206x2622).
Layout measured from the English 6.9-captioned set: crimson background, the screen
1012 px wide at x 154, top at y 610, corners rounded 58 px, caption centred above.
"""
import os
import sys
from PIL import Image, ImageDraw, ImageFont

RAW, OUT = sys.argv[1], sys.argv[2]
W, H = 1320, 2868
CRIMSON = (221, 27, 63)
SX, SY, SW = 154, 610, 1012
SH = round(2868 * SW / 1320)
RADIUS = 58
TEXT_CENTRE = 335

NAMES = ["01-wallet", "02-detail", "03-reminders", "04-privacy"]
CAPTIONS = {
    "zh": [
        "你的护照\n其实早六个月\n就“过期”了。",
        "还剩 96 天，\n换发要好几周。\n现在就该开始办。",
        "不用设置，\n到时间就提醒你。",
        "不用注册，不上传。\n数据加密，只存在手机里。",
    ],
    "zh-hant": [
        "你的護照\n其實早六個月\n就「過期」了。",
        "還剩 96 天，\n換發要好幾週。\n現在就該開始辦。",
        "不用設定，\n時間到了就提醒你。",
        "不用註冊，不上傳。\n資料加密，只存在手機裡。",
    ],
}


def font_for(lang):
    if lang == "zh-hant":
        return ImageFont.truetype("/System/Library/Fonts/STHeiti Medium.ttc", 94, index=0), 1
    return ImageFont.truetype("/System/Library/Fonts/Hiragino Sans GB.ttc", 94, index=2), 0


mask = Image.new("L", (SW, SH), 0)
ImageDraw.Draw(mask).rounded_rectangle((0, 0, SW - 1, SH - 1), radius=RADIUS, fill=255)

for lang, caps in CAPTIONS.items():
    font, stroke = font_for(lang)
    d69 = os.path.join(OUT, f"6.9-captioned-{lang}")
    d63 = os.path.join(OUT, f"6.3-captioned-{lang}")
    os.makedirs(d69, exist_ok=True)
    os.makedirs(d63, exist_ok=True)
    for name, text in zip(NAMES, caps):
        canvas = Image.new("RGB", (W, H), CRIMSON)
        screen = Image.open(os.path.join(RAW, lang, name + ".png")).convert("RGB")
        screen = screen.resize((SW, SH), Image.LANCZOS)
        canvas.paste(screen, (SX, SY), mask)
        d = ImageDraw.Draw(canvas)
        box = d.multiline_textbbox((0, 0), text, font=font, align="center", spacing=26,
                                   stroke_width=stroke)
        tw, th = box[2] - box[0], box[3] - box[1]
        assert tw < W - 120, f"{lang} {name}: caption too wide ({tw}px)"
        x = (W - tw) / 2 - box[0]
        y = TEXT_CENTRE - th / 2 - box[1]
        d.multiline_text((x, y), text, font=font, fill="white", align="center", spacing=26,
                         stroke_width=stroke, stroke_fill="white")
        canvas.save(os.path.join(d69, name + ".png"))
        canvas.resize((1206, 2622), Image.LANCZOS).save(os.path.join(d63, name + ".png"))
    print(lang, "ok")
