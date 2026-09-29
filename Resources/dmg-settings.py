# dmgbuild settings for the release DMG. Positions are icon centres in points
# from the window's top-left and must match Scripts/generate-dmg-background.swift.
import os.path

app = defines.get("app", ".build/pkg/BrowserSchedule.app")  # noqa: F821

format = "ULMO"
filesystem = "APFS"
files = [app]
symlinks = {"Applications": "/Applications"}
icon = "Resources/AppIcon.icns"
background = "Resources/dmg-background.tiff"

# The height includes the title bar; the content area is 640x400.
window_rect = ((200, 120), (640, 432))
default_view = "icon-view"
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
show_icon_preview = False
include_icon_view_settings = True

icon_size = 112
text_size = 13
icon_locations = {
    os.path.basename(app): (160, 190),
    "Applications": (480, 190),
}
