#!/usr/bin/env python3
"""Generate all image assets for Qavex Backgammon Gold (Pillow only).

Outputs:
  assets/images/app_icon.png        1024x1024
  assets/images/splash.png          1080x1920
  assets/images/board_art.png       1200x800  (board + checker art)
  assets/images/feature_graphic.png 1024x500
  store_art/feature_graphic.png     1024x500 (copy)
  store_art/screenshot_1..8.png     1080x1920 (mock screenshots)
"""
import math
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.expanduser(
    "~/workspace/qavex-games/games/qavexbackgammongold")
IMG = os.path.join(ROOT, "assets/images")
STORE = os.path.join(ROOT, "store_art")
os.makedirs(IMG, exist_ok=True)
os.makedirs(STORE, exist_ok=True)

# Signature palette: Golden Table
GOLD = (201, 162, 39)
DEEP_BROWN = (62, 39, 35)
DARK_BG = (26, 15, 8)
BURGUNDY = (107, 31, 42)
IVORY = (245, 236, 215)
BRASS = (140, 106, 47)
CREAM = (255, 248, 231)
WHITE = (255, 255, 255)

FONT_B = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FONT_R = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"


def font(size, bold=True):
    return ImageFont.truetype(FONT_B if bold else FONT_R, size)


def text_center(d, xy, s, fnt, fill):
    bb = d.textbbox((0, 0), s, font=fnt)
    w, h = bb[2] - bb[0], bb[3] - bb[1]
    d.text((xy[0] - w / 2, xy[1] - h / 2), s, font=fnt, fill=fill)


def gold_ring(d, cx, cy, r, width=10):
    for i in range(width):
        d.ellipse([cx - r + i, cy - r + i, cx + r - i, cy + r - i],
                  outline=GOLD)


def checker(d, cx, cy, r, light=True):
    base = CREAM if light else DEEP_BROWN
    edge = GOLD if light else (30, 20, 16)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=base, outline=edge,
              width=max(3, r // 8))
    d.ellipse([cx - r * 0.55, cy - r * 0.55, cx + r * 0.55, cy + r * 0.55],
              outline=edge, width=max(2, r // 14))


def dice_face(d, x, y, s, value, bg=IVORY, fg=DEEP_BROWN):
    d.rounded_rectangle([x, y, x + s, y + s], radius=s // 6, fill=bg,
                        outline=GOLD, width=4)
    pts = {1: [(0.5, 0.5)], 2: [(0.3, 0.3), (0.7, 0.7)],
           3: [(0.3, 0.3), (0.5, 0.5), (0.7, 0.7)],
           4: [(0.3, 0.3), (0.7, 0.3), (0.3, 0.7), (0.7, 0.7)],
           5: [(0.3, 0.3), (0.7, 0.3), (0.5, 0.5), (0.3, 0.7), (0.7, 0.7)],
           6: [(0.3, 0.28), (0.7, 0.28), (0.3, 0.5), (0.7, 0.5),
               (0.3, 0.72), (0.7, 0.72)]}[value]
    pr = s * 0.07
    for px, py in pts:
        d.ellipse([x + px * s - pr, y + py * s - pr,
                   x + px * s + pr, y + py * s + pr], fill=fg)


def bg_gradient(w, h, top=DARK_BG, bottom=(45, 26, 18)):
    img = Image.new("RGB", (w, h), top)
    d = ImageDraw.Draw(img)
    for y in range(h):
        t = y / h
        c = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        d.line([(0, y), (w, y)], fill=c)
    return img, d


# ---------------------------------------------------------------- icon
def make_icon():
    img, d = bg_gradient(1024, 1024)
    gold_ring(d, 512, 512, 430, 26)
    gold_ring(d, 512, 512, 380, 8)
    checker(d, 420, 470, 120, True)
    checker(d, 610, 470, 120, False)
    dice_face(d, 402, 640, 110, 5)
    dice_face(d, 540, 640, 110, 2)
    text_center(d, (512, 880), "QAVEX", font(72), GOLD)
    img.save(os.path.join(IMG, "app_icon.png"))
    print("app_icon.png")


# ---------------------------------------------------------------- splash
def make_splash():
    img, d = bg_gradient(1080, 1920, top=(20, 12, 7), bottom=(60, 34, 22))
    gold_ring(d, 540, 700, 300, 18)
    checker(d, 470, 660, 90, True)
    checker(d, 620, 660, 90, False)
    dice_face(d, 460, 800, 80, 6)
    dice_face(d, 560, 800, 80, 1)
    text_center(d, (540, 1130), "QAVEX", font(110), GOLD)
    text_center(d, (540, 1240), "BACKGAMMON", font(88), CREAM)
    text_center(d, (540, 1330), "GOLD", font(88), GOLD)
    text_center(d, (540, 1450), "Classic board strategy, golden style",
                font(40), IVORY)
    text_center(d, (540, 1830), "by QAVEX", font(36), BRASS)
    img.save(os.path.join(IMG, "splash.png"))
    print("splash.png")


# ---------------------------------------------------------------- board art
def make_board_art():
    W, H = 1200, 800
    img = Image.new("RGB", (W, H), DEEP_BROWN)
    d = ImageDraw.Draw(img)
    # wooden frame
    d.rectangle([0, 0, W, H], fill=(26, 15, 8))
    bx, by, bw, bh = 60, 60, W - 120, H - 120
    d.rectangle([bx, by, bx + bw, by + bh], fill=BURGUNDY)
    # bar
    barx = bx + bw // 2 - 25
    d.rectangle([barx, by, barx + 50, by + bh], fill=(26, 15, 8))
    # points (triangles) 12 per half, alternating ivory/brass
    pw = (bw - 50) / 12
    for half in range(2):
        x0 = bx if half == 0 else barx + 50
        for i in range(6):
            x = x0 + i * pw
            col = IVORY if (i + half) % 2 == 0 else BRASS
            # top row points down
            d.polygon([(x, by), (x + pw, by), (x + pw / 2, by + bh * 0.42)],
                      fill=col)
            # bottom row points up
            col2 = BRASS if (i + half) % 2 == 0 else IVORY
            d.polygon([(x, by + bh), (x + pw, by + bh),
                       (x + pw / 2, by + bh * 0.58)], fill=col2)
    # checkers: white home cluster bottom-right, black top-left etc.
    def col_checkers(x_center, y_start, n, light, direction):
        for k in range(min(n, 5)):
            checker(d, int(x_center), int(y_start + direction * k * 62), 30,
                    light)

    # demo layout resembling the standard opening
    half0x = bx
    for i, n in zip([0, 5], [2, 5]):  # white: pts 24,13 -> top row left half
        col_checkers(half0x + (5 - i) * pw + pw / 2, by + 40, n, True, 1)
    col_checkers(half0x + 4 * pw + pw / 2, by + bh - 40, 5, True, -1)
    col_checkers(half0x + 1 * pw + pw / 2, by + bh - 40, 3, True, -1)
    x1 = barx + 50
    for i, n in zip([0, 5], [2, 5]):  # black mirrored
        col_checkers(x1 + i * pw + pw / 2, by + bh - 40, n, False, -1)
    col_checkers(x1 + 4 * pw + pw / 2, by + 40, 3, False, 1)
    # gold title strip
    d.rectangle([0, 0, W, 44], fill=(26, 15, 8))
    text_center(d, (W // 2, 24), "QAVEX BACKGAMMON GOLD — GOLDEN TABLE",
                font(30), GOLD)
    img.save(os.path.join(IMG, "board_art.png"))
    print("board_art.png")


# ---------------------------------------------------------------- feature
def make_feature():
    W, H = 1024, 500
    img, d = bg_gradient(W, H)
    gold_ring(d, 170, 250, 130, 10)
    checker(d, 140, 235, 45, True)
    checker(d, 205, 235, 45, False)
    dice_face(d, 120, 300, 55, 6)
    dice_face(d, 190, 300, 55, 3)
    text_center(d, (640, 190), "QAVEX BACKGAMMON GOLD", font(64), GOLD)
    text_center(d, (640, 280),
                "Official rules • 4 AI levels • 8 themes", font(36), CREAM)
    text_center(d, (640, 340), "Doubling cube • Offline • No ads",
                font(36), IVORY)
    img.save(os.path.join(IMG, "feature_graphic.png"))
    img.save(os.path.join(STORE, "feature_graphic.png"))
    print("feature_graphic.png")


# ---------------------------------------------------------------- screenshots
def phone(title, subtitle, draw_fn):
    W, H = 1080, 1920
    img, d = bg_gradient(W, H)
    # status bar
    text_center(d, (W // 2, 60), title, font(54), GOLD)
    text_center(d, (W // 2, 120), subtitle, font(32), IVORY)
    draw_fn(d, W, H)
    # watermark
    text_center(d, (W // 2, H - 60), "QAVEX BACKGAMMON GOLD", font(30), BRASS)
    return img


def ss_board_mini(d, x, y, w, h, accent=GOLD):
    d.rounded_rectangle([x, y, x + w, y + h], radius=24, fill=BURGUNDY,
                        outline=accent, width=6)
    barx = x + w // 2 - 12
    d.rectangle([barx, y + 10, barx + 24, y + h - 10], fill=(26, 15, 8))
    pw = (w - 24) / 12
    for half in range(2):
        x0 = x if half == 0 else barx + 24
        for i in range(6):
            px = x0 + i * pw
            c1 = IVORY if (i + half) % 2 == 0 else BRASS
            c2 = BRASS if (i + half) % 2 == 0 else IVORY
            d.polygon([(px, y + 10), (px + pw, y + 10),
                       (px + pw / 2, y + h * 0.32)], fill=c1)
            d.polygon([(px, y + h - 10), (px + pw, y + h - 10),
                       (px + pw / 2, y + h * 0.68)], fill=c2)
    rng = [(0, 4, True, 0), (0, 1, True, 1), (1, 5, False, 0)]
    for half, i, light, row in rng:
        x0 = x if half == 0 else barx + 24
        cx = x0 + i * pw + pw / 2
        cy = y + 60 if row == 0 else y + h - 60
        checker(d, int(cx), int(cy), int(pw * 0.42), light)


def card(d, x, y, w, h, title, desc):
    d.rounded_rectangle([x, y, x + w, y + h], radius=24,
                        fill=(58, 42, 32), outline=GOLD, width=3)
    d.text((x + 36, y + 24), title, font=font(40), fill=GOLD)
    d.text((x + 36, y + 84), desc, font=font(30), fill=IVORY)


def make_screenshots():
    W, H = 1080, 1920

    def s1(d, W, H):  # home
        gold_ring(d, 540, 520, 190, 12)
        checker(d, 480, 490, 70, True)
        checker(d, 610, 490, 70, False)
        dice_face(d, 470, 620, 60, 5)
        dice_face(d, 555, 620, 60, 4)
        for i, t in enumerate(["PLAY", "THEMES", "STATS", "SHOP"]):
            y = 900 + i * 170
            d.rounded_rectangle([190, y, 890, y + 130], radius=28,
                                fill=GOLD)
            text_center(d, (540, y + 65), t, font(48), DARK_BG)

    def s2(d, W, H):  # mode select
        modes = ["Classic", "vs AI", "Timed Blitz", "Tournament Ladder",
                 "Doubling Cube Masters", "Pass & Play"]
        for i, m in enumerate(modes):
            card(d, 90, 220 + i * 250, 900, 200, m,
                 "Official backgammon rules")

    def s3(d, W, H):  # game board golden table
        ss_board_mini(d, 60, 220, 960, 1100)
        dice_face(d, 420, 1400, 90, 6)
        dice_face(d, 540, 1400, 90, 2)
        d.rounded_rectangle([340, 1540, 740, 1640], radius=28, fill=GOLD)
        text_center(d, (540, 1590), "ROLL DICE", font(44), DARK_BG)

    def s4(d, W, H):  # themes
        names = ["Golden Table", "Midnight", "Ocean", "Neon",
                 "Classic Wood", "Royal Green", "Mono", "Desert"]
        cols = [GOLD, (127, 178, 240), (63, 208, 201), (254, 228, 64),
                (218, 169, 78), (212, 175, 55), (176, 176, 176),
                (184, 134, 11)]
        for i, (n, c) in enumerate(zip(names, cols)):
            x, y = 90 + (i % 2) * 470, 220 + (i // 2) * 380
            d.rounded_rectangle([x, y, x + 430, y + 320], radius=24,
                                fill=(58, 42, 32), outline=c, width=5)
            d.ellipse([x + 165, y + 40, x + 265, y + 140], fill=c)
            text_center(d, (x + 215, y + 230), n, font(36), CREAM)

    def s5(d, W, H):  # stats/achievements
        for i in range(6):
            card(d, 90, 220 + i * 250, 900, 200,
                 ["First Roll", "Taste of Victory", "Blot Slayer",
                  "Grandmaster", "Cube Tamer", "Devoted"][i],
                 "Achievement unlocked")

    def s6(d, W, H):  # shop
        for i, (n, p) in enumerate(
                [("Gold Trim", "500"), ("Obsidian Edge", "1200"),
                 ("Marble Checkers", "600"), ("Onyx & Gold", "1500")]):
            card(d, 90, 220 + i * 250, 900, 200, n, f"{p} Doubloon Coins")

    def s7(d, W, H):  # how to play
        rules = ["Roll the dice", "Move your checkers",
                 "Hit enemy blots", "Bear off all 15",
                 "Use the doubling cube", "Crawford rule in finals"]
        for i, r in enumerate(rules):
            y = 240 + i * 230
            d.ellipse([110, y, 190, y + 80], fill=GOLD)
            text_center(d, (150, y + 40), str(i + 1), font(44), DARK_BG)
            d.text((220, y + 12), r, font=font(40), fill=CREAM)

    def s8(d, W, H):  # AI levels
        lvls = [("Easy", "Learn the ropes"),
                ("Medium", "A solid club player"),
                ("Hard", "Sharp tactics"),
                ("Expert", "Near-optimal play")]
        for i, (n, b) in enumerate(lvls):
            card(d, 90, 260 + i * 330, 900, 260, f"{n} AI", b)

    shots = [
        ("Qavex Backgammon Gold", "Home", s1),
        ("Choose Your Mode", "7 ways to play", s2),
        ("Golden Table", "Signature theme", s3),
        ("8 Themes", "A table for every mood", s4),
        ("Achievements", "60 to unlock", s5),
        ("Shop", "Skins for Doubloon Coins", s6),
        ("How to Play", "Learn in minutes", s7),
        ("4 AI Levels", "From Easy to Expert", s8),
    ]
    for i, (title, sub, fn) in enumerate(shots, 1):
        img = phone(title, sub, fn)
        img.save(os.path.join(STORE, f"screenshot_{i}.png"))
        print(f"screenshot_{i}.png")


if __name__ == "__main__":
    make_icon()
    make_splash()
    make_board_art()
    make_feature()
    make_screenshots()
    print("done")
