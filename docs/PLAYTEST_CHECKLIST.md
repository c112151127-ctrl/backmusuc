# 廢土回收商 PC 端測試清單

## 自動驗證

請先執行：

```powershell
node -e "JSON.parse(require('fs').readFileSync('data/maps/npcs.json','utf8')); console.log('JSON OK')"
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --quit
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/ValidationRunner.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/AutomatedPlaytestRunner.tscn'
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/VisualReviewRunner.tscn'
```

若玩家 sprite atlas 有調整，再執行：

```powershell
& 'C:\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'C:\Code\Game\first-game' --scene 'res://scenes/tests/PixelAssetBaker.tscn'
```

## PC 操作

- WASD：移動。
- 滑鼠左鍵按住：連續射擊。
- 空白鍵：近戰拔刀與砍擊。
- E：互動 / 交談 / 使用設施。
- I：背包與裝備。
- Q：切換快捷欄。
- 1-4：直接選擇快捷欄裝備。
- M：開關小地圖。
- H：開關完整教學。
- F5：存檔。
- F9：讀檔。

## 人工試玩流程

1. 啟動遊戲後確認預設進入全螢幕，畫面不再顯示手機方向鍵或手機攻擊按鈕。
2. 確認底部有小型 PC 操作提示，按 H 可開啟完整教學，按 M 可開啟小地圖。
3. 在村莊檢查鍛造爐、合成台、商店、改裝站、拆解機、維修存檔點、廢土出口、公會出口是否分區清楚，沒有互相壓住主要操作區。
4. 靠近村莊 NPC，按 E 交談，確認 NPC 有 PNG 角色圖、姓名職稱、首次獎勵與重複對話。
5. 前往冒險公會，確認委託看板、獎勵櫃台、前往廢土出口、返回村莊出口位置清楚。
6. 在公會接委託，再前往廢土。
7. 在廢土使用滑鼠左鍵按住射擊，確認會消耗彈藥並有射擊音效。
8. 使用空白鍵近戰，確認會切換拔刀與砍擊動畫，命中時有打擊音效。
9. 擊倒污染體後撿取廢鐵、彈藥、核心或其他資源，確認 HUD 數值更新。
10. 回村使用設施強化或合成，確認資源循環成立。
11. 按 F5 存檔、F9 讀檔，確認場景、玩家位置、背包、裝備、委託與已交談 NPC 狀態恢復。
12. 檢查 `docs/visual_review_village.png`、`docs/visual_review_guild.png`、`docs/visual_review_wasteland.png`，確認自動截圖中沒有大型 UI 或建築區塊遮住主要路線。

## 目前已知限制

- 美術已換成可用 PNG 像素素材，但仍屬 vertical slice 素材，後續可再交由專業像素美術精修。
- Android 觸控 UI 暫停，優先完成 PC 端。
- 音樂與音效為本地程式生成 WAV，可作為佔位音效，後續可替換成正式授權音源。
