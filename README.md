This is where i got the idea, i used an old code from autohotkey official forum as a starting point: 👉https://www.autohotkey.com/boards/viewtopic.php?t=106962

🌞🌞Now take a look at this, a much more improved version working with GDI+ and working with every screen size, so give it a try 🌹🌹🌹


🖼️ Fast Image Preview with GDI+

QuickLook‑style image previews for Windows desktop and Explorer, powered by AutoHotkey and GDI+.  
Hold Left Ctrl over an image file icon to instantly see a scaled preview window near your mouse.



📌 Scripts Included

1. FastImagePreviewWithGDI+ Original.ahk
- 🎯 Purpose: Quick image preview on a fixed widescreen (1920×1080).  
- ⚙️ Behavior:  
  - Detects file under mouse pointer.  
  - Loads image formats (.png, .jpg, .bmp, .gif, .tiff, .webp, etc.).  
  - Scales longest side to 800px.  
  - Shows preview window near mouse.  
- ⚠️ Limitations:  
  - Hardcoded for 1920×1080 resolution.  
  - Preview may go off‑screen on smaller monitors.  
  - No multi‑monitor support.  
- 🎥 Demo: YouTube showcase
-Demo original😉  👉https://youtu.be/i-HDpToqw7k👈



2. All Screen & MultiMonitors FastImagePreviewWithGDI+.ahk
- 🚀 Purpose: Improved version that works on any resolution and supports multiple monitors.  
- ⚙️ Enhancements:  
  - Detects monitor where mouse is located.  
  - Scales preview to 80% of monitor size or 800px, whichever is smaller.  
  - Smart positioning logic:
    - Places preview to the right of mouse if possible.  
    - Falls back to left if needed.  
    - Adjusts vertically to avoid cursor overlap.  
    - Clamps to screen edges so preview never goes off‑screen.  
- ✅ Result: Robust, adaptive, and reliable across laptops, ultrawides, and multi‑monitor setups.


🛠️ Requirements
- Windows (tested on 7/10/11).  
- AutoHotkey v1.1 (download from autohotkey.com).  
- GDI+ library (Gdip_All.ahk) — included in most AHK GDI+ packages.  



📥 Installation
1. 📦 Decompress ZIP (if provided).  
2. 💻 Install AutoHotkey (v1.1 recommended).  
3. 📂 Place scripts (.ahk) and Gdip_All.ahk in the same folder.  
4. ▶️ Run the script by double‑clicking the .ahk file.  



🎮 Usage
- 🔑 Trigger: Hold Left Ctrl while hovering over an image file icon (desktop or Explorer).  
- 🖼️ Preview: A borderless window appears near the mouse.  
- ✋ Close: Release Left Ctrl to dismiss the preview.  
- 📑 Supported formats: .ico, .png, .jpg, .jpeg, .bmp, .gif, .tif, .tiff, .webp.  



📝 Recommendation
- Use Original if you only work on a fixed widescreen (1920×1080).  
- Use All Screen & MultiMonitors for adaptive handling across different resolutions and multi‑monitor setups.


🆕 New Feature: Everything 1.5 Support
Your fast image preview script now works seamlessly inside Everything 1.5 (Voidtools).  
- 🔱 Simply select an image file in the Everything results list.  
- 🔱 Hold down Left Control (Ctrl) to instantly preview the image with the same smooth GDI+ rendering used on Desktop and Explorer.  
- 🔱 The preview window respects monitor boundaries, scales intelligently, and avoids cursor overlap—just like in other supported environments.  

🌹🌹 This addition makes the script consistent across Desktop, Explorer, and Everything 1.5, giving you a unified QuickLook-style experience wherever you browse files.  
