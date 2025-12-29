import pyautogui
import pygetwindow as gw
import time
import os

SCREENSHOT_DIR = "L:/SJ/SJ/screenshots"
os.makedirs(SCREENSHOT_DIR, exist_ok=True)

def get_app_window():
    windows = gw.getWindowsWithTitle('frontend')
    return windows[0] if windows else None

def capture_app_only(name):
    window = get_app_window()
    if window:
        screenshot = pyautogui.screenshot(region=(
            window.left + 8,
            window.top + 31,
            window.width - 16,
            window.height - 39
        ))
        filepath = f"{SCREENSHOT_DIR}/{name}.png"
        screenshot.save(filepath)
        print(f"  Saved: {filepath}")
        return True
    return False

window = get_app_window()
if window:
    print("앱 창 발견! 운세(메뉴) 화면 캡쳐...")
    time.sleep(3)  # 앱 로딩 대기
    capture_app_only("01_menu_fortune")
else:
    print("앱 창을 찾을 수 없습니다")
