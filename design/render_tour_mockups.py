from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

OUT = Path(__file__).resolve().parent / "tour_mockups"
OUT.mkdir(parents=True, exist_ok=True)

W, H, S = 390, 844, 2


def font(size, bold=False):
    root = Path("C:/Windows/Fonts")
    candidates = [
        root / ("segoeuib.ttf" if bold else "segoeui.ttf"),
        root / ("arialbd.ttf" if bold else "arial.ttf"),
    ]
    for path in candidates:
        if path.exists():
            return ImageFont.truetype(str(path), size * S)
    return ImageFont.load_default()


def sc(v):
    return int(round(v * S))


def box(draw, xy, fill, radius=16, outline=None, width=1):
    draw.rounded_rectangle(tuple(sc(v) for v in xy), radius=sc(radius), fill=fill, outline=outline, width=sc(width))


def shadow(im, xy, radius=18, blur=24, color=(15, 23, 42, 55)):
    layer = Image.new("RGBA", im.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.rounded_rectangle(tuple(sc(v) for v in xy), radius=sc(radius), fill=color)
    layer = layer.filter(ImageFilter.GaussianBlur(sc(blur)))
    im.alpha_composite(layer)


def text(draw, xy, value, size=14, fill=(23, 32, 47), bold=False, anchor=None):
    draw.text((sc(xy[0]), sc(xy[1])), value, font=font(size, bold), fill=fill, anchor=anchor)


def wrap(draw, value, width, size=14, bold=False):
    words, lines, current = value.split(), [], ""
    f = font(size, bold)
    for word in words:
        trial = f"{current} {word}".strip()
        if draw.textlength(trial, font=f) <= sc(width):
            current = trial
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def paragraph(draw, xy, value, width, size=14, fill=(102, 112, 133), line=1.35, bold=False):
    y = xy[1]
    for line_text in wrap(draw, value, width, size, bold):
        text(draw, (xy[0], y), line_text, size, fill, bold)
        y += size * line
    return y


def gradient(size, top, bottom):
    im = Image.new("RGBA", size, top)
    px = im.load()
    for y in range(size[1]):
        t = y / max(size[1] - 1, 1)
        col = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(4))
        for x in range(size[0]):
            px[x, y] = col
    return im


def base():
    im = gradient((W * S, H * S), (255, 255, 255, 255), (246, 248, 251, 255))
    d = ImageDraw.Draw(im)
    text(d, (24, 19), "9:41", 12, bold=True)
    text(d, (334, 19), "5G 100%", 12, bold=True)
    box(d, (141, 10, 249, 35), (16, 24, 40, 235), 14)
    return im, d


def app_shell(d):
    box(d, (18, 78, 62, 122), (217, 249, 157), 15)
    text(d, (40, 91), "AK", 14, bold=True, anchor="ma")
    text(d, (76, 78), "Good morning", 19, bold=True)
    text(d, (76, 104), "choose your work stream", 12, (102, 112, 133))
    box(d, (332, 80, 372, 120), (255, 255, 255), 14, (216, 222, 232))
    text(d, (352, 91), "!", 16, bold=True, anchor="ma")


def work_tile(d, x, y, title, sub, icon, active=False):
    fill = (255, 255, 255) if active else (248, 250, 252)
    box(d, (x, y, x + 148, y + 122), fill, 18, (226, 232, 240))
    box(d, (x + 13, y + 13, x + 47, y + 47), (37, 99, 235), 13)
    text(d, (x + 30, y + 20), icon, 13, (255, 255, 255), True, "ma")
    text(d, (x + 13, y + 74), title, 14, bold=True)
    text(d, (x + 13, y + 96), sub, 11, (102, 112, 133))


def hero(d, title, body, tiles):
    box(d, (18, 145, 372, 630), (255, 255, 255), 24, (216, 222, 232))
    text(d, (36, 165), title, 25, bold=True)
    paragraph(d, (36, 202), body, 310, 13)
    positions = [(36, 280), (206, 280), (36, 414), (206, 414)]
    for (x, y), t in zip(positions, tiles):
        work_tile(d, x, y, *t)


def bottom_nav(d, active="Home"):
    box(d, (18, 766, 372, 828), (255, 255, 255, 238), 24, (216, 222, 232))
    for i, label in enumerate(["Home", "Setup", "Reports", "More"]):
        fill = (37, 99, 235) if label == active else (100, 116, 139)
        text(d, (62 + i * 88, 787), label, 11, fill, True, "ma")


def scrim(im, blur=False):
    overlay = Image.new("RGBA", im.size, (15, 23, 42, 108))
    im.alpha_composite(overlay)


def language_popup():
    im, d = base()
    app_shell(d)
    hero(d, "What are you working on today?", "Select your category once. The app will shape setup, daily entry, and reports around it.",
         [("Mechanical", "Piping, insulation", "M"), ("Civil", "Site works", "C"), ("Electrical", "Panels, cable", "E"), ("Fabrication", "Shop floor", "F")])
    bottom_nav(d)
    scrim(im)
    shadow(im, (18, 128, 372, 610), 28, 22)
    box(d, (18, 128, 372, 610), (255, 255, 255), 28)
    box(d, (38, 150, 177, 181), (236, 254, 255), 16)
    text(d, (53, 157), "A", 13, (3, 105, 161), True)
    text(d, (73, 157), "Language Setup", 12, (3, 105, 161), True)
    text(d, (38, 205), "Choose the language", 27, bold=True)
    text(d, (38, 237), "you work in", 27, bold=True)
    paragraph(d, (38, 283), "Start in English instantly, or download another language pack for labels, prompts, and guided help.", 304, 14)
    for x, title, sub in [(38, "English", "Ready offline"), (205, "Hindi", "Download pack")]:
        box(d, (x, 366, x + 147, 424), (248, 251, 255), 16, (219, 234, 254))
        text(d, (x + 14, 379), title, 13, bold=True)
        text(d, (x + 14, 401), sub, 11, (102, 112, 133))
    box(d, (38, 449, 352, 501), (37, 99, 235), 16)
    text(d, (195, 464), "Select Language", 15, (255, 255, 255), True, "ma")
    box(d, (38, 513, 352, 565), (248, 250, 252), 16, (219, 227, 239))
    text(d, (195, 528), "Continue with English", 15, (30, 41, 59), True, "ma")
    text(d, (195, 584), "You can change this anytime in Settings.", 11, (118, 131, 154), anchor="ma")
    return im


def language_picker():
    im, d = base()
    box(d, (18, 74, 58, 114), (255, 255, 255), 14, (216, 222, 232))
    text(d, (38, 85), "<", 18, bold=True, anchor="ma")
    text(d, (195, 84), "App Language", 18, bold=True, anchor="ma")
    box(d, (332, 74, 372, 114), (255, 255, 255), 14, (216, 222, 232))
    text(d, (352, 85), "?", 16, bold=True, anchor="ma")
    shadow(im, (18, 132, 372, 220), 22, 15, (15, 23, 42, 35))
    box(d, (18, 132, 372, 220), (16, 33, 63), 22)
    text(d, (36, 151), "CURRENT SELECTION", 11, (183, 197, 220), True)
    text(d, (36, 177), "English", 21, (255, 255, 255), True)
    box(d, (300, 172, 352, 198), (16, 185, 129, 38), 13)
    text(d, (326, 177), "Ready", 11, (134, 239, 172), True, "ma")
    box(d, (18, 239, 372, 287), (255, 255, 255), 16, (219, 227, 239))
    text(d, (37, 253), "Search language", 14, (138, 152, 170), True)
    y = 307
    langs = [("EN", "English", "English - en-IN", True, "check"), ("HI", "Hindi", "Hindi - hi-IN", False, "download"), ("BN", "Bengali", "Bengali - bn-IN", False, "download"), ("MR", "Marathi", "Marathi - mr-IN", False, "download"), ("TA", "Tamil", "Tamil - ta-IN", False, "download")]
    for code, name, sub, active, action in langs:
        box(d, (18, y, 372, y + 72), (239, 246, 255) if active else (255, 255, 255), 18, (59, 130, 246) if active else (226, 232, 240))
        box(d, (31, y + 17, 69, y + 55), (37, 99, 235), 14)
        text(d, (50, y + 27), code, 12, (255, 255, 255), True, "ma")
        text(d, (82, y + 17), name, 15, bold=True)
        text(d, (82, y + 42), sub, 12, (102, 112, 133))
        text(d, (345, y + 27), "OK" if action == "check" else "DL", 12, (37, 99, 235) if active else (100, 116, 139), True, "ma")
        y += 84
    box(d, (18, 776, 132, 828), (248, 250, 252), 17, (219, 227, 239))
    text(d, (75, 791), "Back", 14, (30, 41, 59), True, "ma")
    box(d, (144, 776, 372, 828), (37, 99, 235), 17)
    text(d, (258, 791), "Save & Continue", 14, (255, 255, 255), True, "ma")
    return im


def tour_showcase():
    im, d = base()
    app_shell(d)
    hero(d, "Setup your first site", "Choose a setup module and Buddy will guide the fastest path.",
         [("View Sites", "Open list", "V"), ("Add Site", "Create or import", "+"), ("Rate", "Item pricing", "R"), ("Team", "Members", "T")])
    bottom_nav(d, "Setup")
    scrim(im)
    shadow(im, (206, 280, 354, 402), 20, 18, (14, 165, 233, 90))
    work_tile(d, 206, 280, "Add Site", "Create or import", "+", True)
    d.rounded_rectangle((sc(202), sc(276), sc(358), sc(406)), radius=sc(24), outline=(14, 165, 233), width=sc(5))
    shadow(im, (16, 558, 374, 748), 24, 18, (15, 23, 42, 105))
    box(d, (16, 558, 374, 748), (21, 33, 58), 24, (71, 142, 196))
    box(d, (176, 570, 214, 574), (255, 255, 255, 72), 3)
    box(d, (32, 592, 74, 634), (37, 99, 235), 16)
    text(d, (53, 603), "B", 16, (255, 255, 255), True, "ma")
    text(d, (86, 590), "View or Add", 14, (255, 255, 255), True)
    text(d, (86, 612), "Step 1 of 5 - Choose Add", 11, (139, 220, 255), True)
    text(d, (300, 600), "R  V  X", 12, (183, 197, 220), True)
    box(d, (32, 652, 358, 657), (255, 255, 255, 34), 3)
    box(d, (32, 652, 97, 657), (34, 211, 238), 3)
    paragraph(d, (32, 674), "You can view existing sites or add a new one. Tap the highlighted Add Site card to create your first site.", 320, 13, (238, 247, 255))
    text(d, (32, 724), "Replay voice", 12, (159, 179, 209), True)
    box(d, (285, 711, 358, 737), (37, 99, 235), 13)
    text(d, (321, 716), "Got it", 12, (255, 255, 255), True, "ma")
    return im


def tour_complete():
    im, d = base()
    app_shell(d)
    hero(d, "Your setup is ready", "Imported site data is now available for daily progress, manpower, and reports.",
         [("Sites", "1 active", "S"), ("Daily Entry", "Ready", "D"), ("Manpower", "Next setup", "M"), ("Reports", "Available", "R")])
    scrim(im)
    shadow(im, (24, 206, 366, 596), 30, 22)
    box(d, (24, 206, 366, 596), (255, 255, 255), 30)
    box(d, (154, 232, 236, 314), (16, 185, 129), 28)
    text(d, (195, 250), "OK", 26, (255, 255, 255), True, "ma")
    text(d, (195, 338), "Site setup complete", 25, bold=True, anchor="ma")
    paragraph(d, (61, 380), "Your first site is ready. You can continue to daily entry or setup the next module.", 270, 14, anchor if False else (102,112,133))
    labels = [("5", "steps"), ("1", "site"), ("100%", "done")]
    x = 51
    for val, lab in labels:
        box(d, (x, 452, x + 84, 510), (248, 250, 252), 16, (226, 232, 240))
        text(d, (x + 42, 462), val, 17, bold=True, anchor="ma")
        text(d, (x + 42, 488), lab, 10, (102, 112, 133), True, "ma")
        x += 101
    box(d, (48, 532, 342, 584), (37, 99, 235), 16)
    text(d, (195, 547), "Continue to Setup", 15, (255, 255, 255), True, "ma")
    return im


def save(name, im):
    path = OUT / name
    im.resize((W, H), Image.Resampling.LANCZOS).convert("RGB").save(path, quality=96)
    return path


def main():
    items = [
        ("01_language_popup.png", language_popup()),
        ("02_language_picker.png", language_picker()),
        ("03_tour_showcase.png", tour_showcase()),
        ("04_tour_complete.png", tour_complete()),
    ]
    paths = [save(name, im) for name, im in items]
    sheet = Image.new("RGB", (W * 4 + 28 * 5, H + 56), (232, 237, 245))
    for i, path in enumerate(paths):
        img = Image.open(path).convert("RGB")
        sheet.paste(img, (28 + i * (W + 28), 28))
    sheet.save(OUT / "tour_mockup_sheet.png", quality=96)
    print("\n".join(str(p) for p in paths + [OUT / "tour_mockup_sheet.png"]))


if __name__ == "__main__":
    main()
