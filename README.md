# AltKeysLite for Mac (`excel-alt-keys-mac`)

**Windows-style `Alt` (`Option ⌥`) ribbon shortcuts & visual KeyTip badges for Microsoft Excel on macOS.**

`AltKeysLite` is a lightweight, **100% offline**, single-file native macOS menu bar utility written in Swift. Press `Option (⌥)` in Microsoft Excel for Mac just like pressing `Alt` on Windows — floating KeyTip badges appear over the Excel ribbon and menus, letting you navigate and trigger commands at full keyboard speed.

---

## Download

👉 **[Download Latest Universal macOS App (`AltKeysLite_Mac_Universal.zip`)](https://github.com/lelee9/excel-alt-keys-mac/releases/latest/download/AltKeysLite_Mac_Universal.zip)**

### System Requirements
| Requirement | Minimum Supported |
| :--- | :--- |
| **Apple Silicon Macs (`M1` / `M2` / `M3` / `M4` / `M5`)** | **macOS 11.0 (Big Sur)** and newer |
| **Intel Macs** | **macOS 13.0 (Ventura)** and newer |
| **Microsoft Excel for Mac** | Microsoft 365 / Office 2021+ (**English UI language**) |

---

## Quick Installation (Under 1 Minute)

### Step 1 — Unzip & Open
1. Download and double-click **`AltKeysLite_Mac_Universal.zip`** to extract the **`AltKeysLite_For_Mac`** folder.
2. **Right-click (or two-finger click) `First_Time_Open.command` -> click `Open`** (and click **`Open`** if macOS asks to confirm).
   - *Why?* Because this free open-source tool is not signed with a paid $99/year Apple Developer ID certificate, macOS Gatekeeper blocks downloaded apps on first launch unless the download quarantine attribute is cleared (`xattr -cr`). `First_Time_Open.command` clears that flag cleanly and opens `AltKeysLite.app`.
   - Once running, you will immediately see **`⌥`** in your top macOS Menu Bar (near Wi-Fi / Battery / Clock). No Terminal window needs to stay open.
   - *(Optional)* Afterwards, you can move **`AltKeysLite.app`** to your **`/Applications`** folder and add it to **System Settings -> General -> Login Items** if you want it to start automatically when you turn on your Mac.

### Step 2 — Enable Accessibility Permission (One-Time Setup)
1. On first launch, macOS will ask to grant Accessibility access (or click **`⌥`** in your top Menu Bar -> **`Open Accessibility Settings…`**).
2. In **System Settings -> Privacy & Security -> Accessibility**, toggle **ON** **`AltKeysLite`**.
   - *(If macOS also asks for **Input Monitoring**, toggle **ON** `AltKeysLite` under **Privacy & Security -> Input Monitoring** as well.)*
3. No restart needed — within 1 second, click **`⌥`** in your top Menu Bar and you will see: **`AltKeysLite — Active ✓`**.

---

## Supported Excel Ribbon Tabs

Tap **`Option (⌥)`** (or hold `Option` + the tab letter) inside Microsoft Excel:

- **`Alt + H`** — **Home** *(Paste Special, Font/Fill/Borders, Alignment, Merge & Center, Number Formatting, Conditional Formatting, Insert/Delete/Format Rows & Columns, AutoSum, Clear, Sort & Filter, Find & Select)*
- **`Alt + N`** — **Insert** *(PivotTable, Recommended PivotTables, Tables, Illustrations/Pictures/Shapes/Icons, Charts, Sparklines, Links, Comments/Notes, Text Box, Header & Footer, Equation/Symbol)*
- **`Alt + JI`** — **Draw** *(Select, Draw Tools, Eraser, Convert Ink to Shape/Math, Replay)*
- **`Alt + P`** — **Page Layout** *(Themes, Colors/Fonts/Effects, Margins, Orientation, Size, Print Area, Breaks, Background, Print Titles, Scale to Fit, Sheet Options)*
- **`Alt + M`** — **Formulas** *(Insert Function, AutoSum, Recently Used, Financial, Logical, Text, Date & Time, Lookup & Reference, Math & Trig, More Functions, Name Manager/Define Name, Formula Auditing, Watch Window, Calculation Options)*
- **`Alt + A`** — **Data** *(Get Data / Power Query, Refresh All, Sort & Filter, Text to Columns, Flash Fill, Remove Duplicates, Data Validation, Consolidate, What-If Analysis, Group / Ungroup / Subtotal)*
- **`Alt + R`** — **Review** *(Check Spelling, Thesaurus, Workbook Statistics, Check Accessibility, Smart Lookup, Translate, New Comment / Notes, Protect Sheet & Workbook)*
- **`Alt + W`** — **View** *(Normal / Page Break Preview / Page Layout, Custom Views, Show Gridlines/Headings/Formula Bar, Zoom / 100% / Zoom to Selection, New Window, Arrange All, Freeze Panes, Split, Hide/Unhide, Dynamic Switch Windows, Macros)*
- **`Alt + U`** — **Automate** *(New Script, View Scripts, Flow Templates)*

Press **`Esc`** anytime (or click anywhere with the mouse) to dismiss KeyTip badges. To quit the app, click **`⌥`** in the top Menu Bar -> **`Quit AltKeysLite`**.

---

## Security, Privacy & Transparency (100% Offline)

Because macOS displays a standard warning for every Accessibility / keyboard shortcut utility (*"Apps with this access can monitor your keyboard..."*), `AltKeysLite` is designed to be **100% auditable in a single Swift file ([`AltKeysLite.swift`](./AltKeysLite.swift))**:

1. **100% Offline — Zero Network Code**: Imports only Apple's `Cocoa` and `ApplicationServices` frameworks. Contains **zero** networking, `URLSession`, HTTP/socket calls, analytics, or telemetry. It cannot connect to the internet.
2. **Zero Disk Logging**: Never writes, records, or saves keystrokes, clipboard contents, screenshots, or workbook data anywhere on disk.
3. **Inactive Outside Excel & PowerPoint**: The very first guard in the event callback checks `NSWorkspace.shared.frontmostApplication`. Whenever any other app (browser, banking, chat, Notes, Finder) is active, keyboard events are returned untouched immediately without reading which key was pressed.
4. **Official Public Apple APIs Only**: Built exclusively on Apple's public `NSStatusBar`, `CGEventTap`, and `AXUIElement` Accessibility APIs — it never modifies macOS system files or Microsoft Excel application files.

---

## Build From Source Yourself (Optional)

If you prefer to compile the app directly from the open-source Swift code on your own Mac (requires Xcode Command Line Tools: `xcode-select --install`):

```bash
swiftc -O AltKeysLite.swift -o AltKeysLite
./AltKeysLite
```

---

## License

Released under the [MIT License](./LICENSE).
