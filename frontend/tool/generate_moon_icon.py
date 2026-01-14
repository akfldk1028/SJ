"""
달과 별 앱 아이콘 생성기
"""
import math
import random
from PIL import Image, ImageDraw, ImageFilter

def create_moon_stars_icon(size=1024):
    """달과 별 아이콘을 생성합니다."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 배경 그라데이션 (밤하늘)
    for y in range(size):
        for x in range(size):
            # 중심에서의 거리 계산
            cx, cy = size * 0.65, size * 0.35
            dist = math.sqrt((x - cx) ** 2 + (y - cy) ** 2)
            max_dist = size * 1.2
            t = min(dist / max_dist, 1.0)

            # 색상 보간
            r = int(44 * (1 - t) + 13 * t)
            g = int(62 * (1 - t) + 13 * t)
            b = int(80 * (1 - t) + 20 * t)
            img.putpixel((x, y), (r, g, b, 255))

    draw = ImageDraw.Draw(img)

    # 초승달 위치 미리 계산 (별 배치에 사용)
    moon_center_x = size // 2 - size // 28
    moon_center_y = size // 2
    moon_radius = int(size * 0.32)

    def is_in_moon_area(x, y):
        """달 영역 안에 있는지 확인 (여유 공간 포함)"""
        dist = math.sqrt((x - moon_center_x) ** 2 + (y - moon_center_y) ** 2)
        return dist < moon_radius * 1.4  # 달 주변 여유 공간

    # 별들 그리기 (달 영역 제외)
    random.seed(42)
    stars_drawn = 0
    attempts = 0
    while stars_drawn < 15 and attempts < 100:
        x = random.randint(0, size)
        y = random.randint(0, size)
        attempts += 1

        # 달 영역이면 스킵
        if is_in_moon_area(x, y):
            continue

        star_size = random.randint(2, 5) * size // 140
        opacity = int(100 + random.random() * 155)
        draw.ellipse(
            [x - star_size, y - star_size, x + star_size, y + star_size],
            fill=(255, 255, 255, opacity)
        )
        stars_drawn += 1

    # 초승달 그리기
    center_x = size // 2 - size // 28
    center_y = size // 2
    moon_radius = int(size * 0.32)

    # 달 마스크 생성
    moon_mask = Image.new('L', (size, size), 0)
    moon_draw = ImageDraw.Draw(moon_mask)

    # 외부 원
    moon_draw.ellipse([
        center_x - moon_radius,
        center_y - moon_radius,
        center_x + moon_radius,
        center_y + moon_radius
    ], fill=255)

    # 내부 원 (초승달 형태를 위해)
    inner_offset = int(moon_radius * 0.5)
    inner_radius = int(moon_radius * 0.85)
    moon_draw.ellipse([
        center_x + inner_offset - inner_radius,
        center_y - inner_radius,
        center_x + inner_offset + inner_radius,
        center_y + inner_radius
    ], fill=0)

    # 달 색상 (골드 그라데이션)
    moon_layer = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    moon_layer_draw = ImageDraw.Draw(moon_layer)

    for y in range(size):
        for x in range(size):
            if moon_mask.getpixel((x, y)) > 0:
                # 그라데이션: 위쪽은 밝은 베이지, 아래쪽은 골드
                t = (y - (center_y - moon_radius)) / (2 * moon_radius)
                t = max(0, min(1, t))
                r = int(245 * (1 - t) + 196 * t)
                g = int(230 * (1 - t) + 169 * t)
                b = int(202 * (1 - t) + 98 * t)
                moon_layer.putpixel((x, y), (r, g, b, 255))

    # 달 글로우 효과
    glow = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_radius = int(moon_radius * 1.3)
    for r in range(glow_radius, 0, -3):
        opacity = int(50 * (1 - r / glow_radius))
        glow_draw.ellipse([
            center_x - r,
            center_y - r,
            center_x + r,
            center_y + r
        ], fill=(196, 169, 98, opacity))

    img = Image.alpha_composite(img, glow)
    img = Image.alpha_composite(img, moon_layer)

    # 큰 별 그리기 (꽉 찬 5각 별)
    def draw_star(img, cx, cy, star_size, color):
        draw = ImageDraw.Draw(img)
        points = []
        inner_size = star_size * 0.4  # 내부 꼭지점 크기
        for i in range(10):
            angle = (i * math.pi / 5) - math.pi / 2
            if i % 2 == 0:
                # 외부 꼭지점
                r = star_size
            else:
                # 내부 꼭지점
                r = inner_size
            x = cx + r * math.cos(angle)
            y = cy + r * math.sin(angle)
            points.append((x, y))
        draw.polygon(points, fill=color)
        return img

    scale = size / 140
    img = draw_star(img, center_x + 35 * scale + size * 0.05, center_y - 25 * scale, 12 * scale, (196, 169, 98, 255))
    img = draw_star(img, center_x + 20 * scale + size * 0.05, center_y + 30 * scale, 8 * scale, (232, 213, 163, 255))

    # 작은 반짝이는 별 추가 (모서리 위주로 배치)
    draw = ImageDraw.Draw(img)
    small_stars = [
        (0.1, 0.1, 3),
        (0.9, 0.1, 3),
        (0.9, 0.9, 3),
        (0.1, 0.9, 3),
    ]
    for sx, sy, ss in small_stars:
        x, y = int(size * sx), int(size * sy)
        s = ss * size // 140
        draw.ellipse([x-s, y-s, x+s, y+s], fill=(255, 255, 255, 180))

    return img

def main():
    import os

    # 아이콘 디렉토리 생성
    icon_dir = os.path.join(os.path.dirname(__file__), '..', 'assets', 'icons')
    os.makedirs(icon_dir, exist_ok=True)

    # 1024x1024 아이콘 생성
    print("Generating 1024x1024 icon...")
    icon = create_moon_stars_icon(1024)
    icon_path = os.path.join(icon_dir, 'app_icon.png')
    icon.save(icon_path, 'PNG')
    print(f"Saved: {icon_path}")

    # 다양한 크기로 저장
    sizes = [512, 192, 144, 96, 72, 48]
    for s in sizes:
        print(f"Generating {s}x{s} icon...")
        resized = icon.resize((s, s), Image.LANCZOS)
        path = os.path.join(icon_dir, f'app_icon_{s}.png')
        resized.save(path, 'PNG')
        print(f"Saved: {path}")

    print("\nDone! Icon files generated in assets/icons/")

if __name__ == '__main__':
    main()
