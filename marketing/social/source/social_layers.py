"""Still layers for Elapsa's social videos (TikTok, Reels, Shorts, 小红书), 1080x1920.

    python3 social_layers.py <out folder> <en|zh>

hook.png   crimson opening card, one big question (first ~2 s, made to stop the scroll)
bg.png     crimson background behind the app
mask.png   rounded corners for the app screen
cap0-3.png captions above the app, one per part of the recording
end.png    warm-white end card: icon, name, "search on the App Store"

Safe zones: TikTok/Reels/小红书 put their own buttons along the right edge and the
caption and username over the bottom ~25%, and tabs over the top ~150 px. All text
sits between y 170 and 1400 and away from the right 140 px.
"""
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT, LANG = sys.argv[1], sys.argv[2]
W, H = 1080, 1920
CRIMSON = (221, 27, 63)
WARM = (251, 250, 248)
INK = (20, 19, 18)
MUTED = (139, 134, 127)
SX, SY, SW = 130, 560, 820
SH = round(2868 * SW / 1320)
RADIUS = 52
ICON = "/Volumes/APPS/market/ljworkshop/site/img/elapsa/icon-rounded.webp"

TEXT = {
    "en": {
        "hook": "Did you know\nyour passport\nexpires 6 months\nearly?",
        "caps": [
            "Many countries won't let you in\nwith under 6 months left.",
            "Elapsa tells you when\nto start renewing.",
            "Reminders months ahead.\nAs many as you like.",
            "No account. No upload.\nIt all stays on your phone.",
        ],
        "name": "Elapsa",
        "cta": "Search “Elapsa”\non the App Store",
        "small": "Free for 3 documents · No subscription",
    },
    "zh": {
        "hook": "你知道吗？\n护照其实\n早半年就\n“过期”了",
        "caps": [
            "很多国家要求\n护照剩余有效期 ≥ 6 个月",
            "Elapsa 在该开始办的时候\n提醒你",
            "提前几个月提醒\n想设几个就设几个",
            "不用注册，不上传\n数据只存在你的手机里",
        ],
        "name": "Elapsa",
        "cta": "App Store 搜索\n「Elapsa」",
        "small": "前 3 份证件免费 · 不是订阅",
    },
}[LANG]


def font(size, weight="bold"):
    if LANG == "zh":
        f = ImageFont.truetype("/System/Library/Fonts/Hiragino Sans GB.ttc", size,
                               index=2 if weight == "bold" else 0)
        f.weight = weight
        return f
    f = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", size)
    try:
        f.set_variation_by_name("Bold" if weight == "bold" else "Regular")
    except Exception:
        pass
    f.weight = weight
    return f


def centred(draw, text, fnt, cy, fill, spacing, max_w=W - 280):
    # Shrink the font a step at a time until the widest line fits the safe area.
    size = fnt.size
    while True:
        box = draw.multiline_textbbox((0, 0), text, font=fnt, align="center",
                                      spacing=spacing)
        tw, th = box[2] - box[0], box[3] - box[1]
        if tw <= max_w:
            break
        size -= 2
        assert size > 30, f"can't fit: {text!r}"
        fnt = font(size, getattr(fnt, "weight", "bold"))  # keeps the weight
    # centre in the area left of the right-edge buttons
    x = (W - 140 - tw) / 2 + 70 - box[0]
    draw.multiline_text((x, cy - th / 2 - box[1]), text, font=fnt, fill=fill,
                        align="center", spacing=spacing)


# hook card
img = Image.new("RGB", (W, H), CRIMSON)
centred(ImageDraw.Draw(img), TEXT["hook"], font(118 if LANG == "zh" else 98), 820,
        "white", 30)
img.save(f"{OUT}/hook.png")

# app background and mask
Image.new("RGB", (W, H), CRIMSON).save(f"{OUT}/bg.png")
mask = Image.new("L", (SW, SH), 0)
ImageDraw.Draw(mask).rounded_rectangle((0, 0, SW - 1, SH - 1), radius=RADIUS, fill=255)
mask.save(f"{OUT}/mask.png")

# captions above the app
for i, text in enumerate(TEXT["caps"]):
    cap = Image.new("RGBA", (W, SY), (0, 0, 0, 0))
    centred(ImageDraw.Draw(cap), text, font(64 if LANG == "zh" else 62), 365, "white",
            20)
    cap.save(f"{OUT}/cap{i}.png")

# end card
end = Image.new("RGB", (W, H), WARM)
icon = Image.open(ICON).convert("RGBA").resize((260, 260), Image.LANCZOS)
shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ix = (W - 140 - 260) // 2 + 70
ImageDraw.Draw(shadow).rounded_rectangle((ix + 14, 470, ix + 246, 712), radius=58,
                                         fill=(20, 19, 18, 70))
shadow = shadow.filter(ImageFilter.GaussianBlur(22))
end.paste(shadow, (0, 0), shadow)
end.paste(icon, ((W - 140 - 260) // 2 + 70, 440), icon)
d = ImageDraw.Draw(end)
centred(d, TEXT["name"], font(120), 840, INK, 10)
centred(d, TEXT["cta"], font(70), 1040, CRIMSON, 24)
centred(d, TEXT["small"], font(44, "regular"), 1250, MUTED, 10)
end.save(f"{OUT}/end.png")
print(SH)
