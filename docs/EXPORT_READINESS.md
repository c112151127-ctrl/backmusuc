# 匯出與平台驗收狀態

## Godot 執行檔

本機 Godot 位置：

```powershell
C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe
```

已確認版本：

```text
4.6.3.stable.official.7d41c59c4
```

## Export Presets

專案已新增 `export_presets.cfg`：

- `Windows Desktop`：輸出到 `builds/windows/WasteRecycler.exe`
- `Android`：輸出到 `builds/android/WasteRecycler.apk`

`builds/` 已加入 `.gitignore`，避免把匯出成品提交進 git。

## Windows 匯出驗證

先建立輸出資料夾：

```powershell
New-Item -ItemType Directory -Force -Path 'builds\windows'
```

執行匯出：

```powershell
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --export-release 'Windows Desktop' 'builds\windows\WasteRecycler.exe'
```

目前執行結果：preset 可被 Godot 讀取，但本機缺 Windows export templates，因此尚不能產生 `.exe`。

Godot 回報缺少：

```text
C:/Users/wuwu6/AppData/Roaming/Godot/export_templates/4.6.3.stable/windows_debug_x86_64.exe
C:/Users/wuwu6/AppData/Roaming/Godot/export_templates/4.6.3.stable/windows_release_x86_64.exe
```

## Android 匯出狀態

目前本機缺少 Android export templates 與 Android 工具鏈。

Godot 回報缺少：

```text
C:/Users/wuwu6/AppData/Roaming/Godot/export_templates/4.6.3.stable/android_debug.apk
C:/Users/wuwu6/AppData/Roaming/Godot/export_templates/4.6.3.stable/android_release.apk
Godot Editor Settings 中需要有效 Java SDK 路徑
```

命令列工具檢查結果缺少：

- `adb`
- `sdkmanager`
- `apksigner`
- `keytool`

因此目前只能提交 Android preset，尚不能完成 APK 匯出、安裝或實機觸控驗證。

Android 工具鏈補齊後：

```powershell
New-Item -ItemType Directory -Force -Path 'builds\android'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --export-debug 'Android' 'builds\android\WasteRecycler.apk'
adb install -r 'builds\android\WasteRecycler.apk'
```

## 目前可驗證項目

即使 Android 匯出工具鏈尚未補齊，仍可驗證跨平台操作設計：

```powershell
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/ValidationRunner.tscn'
```

驗證內容包含：

- PC InputMap：WASD、滑鼠、互動、背包、存讀檔。
- Android 觸控 UI：左下 D-pad 與右下動作按鈕。
- 核心可玩循環：野外戰鬥、撿取、射擊、存讀檔、回村狀態。
