// AltKeysLite.swift
// Windows-style Alt-key ribbon shortcut engine for Mac Excel.
//
// Build:  swiftc -O AltKeysLite.swift -o AltKeysLite
// Run:    ./AltKeysLite

import Cocoa
import ApplicationServices

setbuf(stdout, nil)

// MARK: - Actions

enum Action {
    case menu([String])
    case keys([(CGKeyCode, CGEventFlags)])
    case pressAX(String)
    case focusRibbon(String)
    case custom((pid_t) -> Void)
}

let cmdCtrl: CGEventFlags = [.maskCommand, .maskControl]

// Windows shortcuts in Mac Excel
let sequences: [String: Action] = [
    // --- FORMAT (HO) ---
    "HOH": .pressAX("Row Height..."),
    "HOA": .pressAX("AutoFit Row Height"),
    "HOW": .pressAX("Column Width..."),
    "HOI": .pressAX("AutoFit Column Width"),
    "HOD": .pressAX("Default Width..."),
    "HOR": .pressAX("Rename Sheet"),
    "HOM": .pressAX("Move or Copy Sheet..."),
    "HOT": .pressAX("Tab Color"),
    "HOP": .pressAX("Protect Sheet..."),
    "HOL": .pressAX("Lock Cell"),
    "HOE": .pressAX("Format Cells..."),
    
    // --- HIDE & UNHIDE (HOU) ---
    "HOUR": .pressAX("Hide Rows"),
    "HOUC": .pressAX("Hide Columns"),
    "HOUS": .pressAX("Hide Sheet"),
    "HOUO": .pressAX("Unhide Rows"),
    "HOUL": .pressAX("Unhide Columns"),
    "HOUH": .pressAX("Unhide Sheet..."),
    
    // --- INSERT (HI) ---
    "HII": .menu(["Insert", "Cells..."]),
    "HIR": .menu(["Insert", "Rows"]),
    "HIC": .menu(["Insert", "Columns"]),
    "HIS": .menu(["Insert", "Sheet", "Insert Sheet"]),
    
    // --- DELETE (HD) ---
    "HDD": .menu(["Edit", "Delete..."]),
    "HDR": .custom({ pid in
        send(49, [.maskShift]) // Shift + Space
        usleep(90_000)
        pressMenu(pid: pid, path: ["Edit", "Delete..."])
    }),
    "HDC": .custom({ pid in
        send(49, [.maskControl]) // Control + Space
        usleep(90_000)
        pressMenu(pid: pid, path: ["Edit", "Delete..."])
    }),
    "HDS": .menu(["Edit", "Sheet", "Delete Sheet"]),
    
    // --- CONDITIONAL FORMATTING (HL) ---
    "HLR": .pressAX("Manage Rules..."),
    "HLN": .pressAX("New Rule..."),
    "HLD": .pressAX("Data Bars"),
    "HLS": .pressAX("Color Scales"),
    "HLI": .pressAX("Icon Sets"),
    
    // Clear Rules (HLC)
    "HLCS": .pressAX("Clear Rules from Selected Cells"),
    "HLCE": .pressAX("Clear Rules from Entire Sheet"),
    "HLCT": .pressAX("Clear Rules from This Table"),
    "HLCP": .pressAX("Clear Rules from This PivotTable"),
    
    // Highlight Cells Rules (HLH)
    "HLHG": .pressAX("Greater Than..."),
    "HLHL": .pressAX("Less Than..."),
    "HLHB": .pressAX("Between..."),
    "HLHE": .pressAX("Equal To..."),
    "HLHT": .pressAX("Text that Contains..."),
    "HLHA": .pressAX("A Date Occurring..."),
    "HLHD": .pressAX("Duplicate Values..."),
    "HLHM": .pressAX("More Rules..."),
    
    // Top/Bottom Rules (HLT)
    "HLTT": .pressAX("Top 10 Items..."),
    "HLTP": .pressAX("Top 10 %..."),
    "HLTB": .pressAX("Bottom 10 Items..."),
    "HLTO": .pressAX("Bottom 10 %..."),
    "HLTA": .pressAX("Above Average..."),
    "HLTU": .pressAX("Below Average..."),
    "HLTM": .pressAX("More Rules..."),
    
    // --- BORDERS (HB) ---
    "HBO": .pressAX("Bottom Border"),
    "HBP": .pressAX("Top Border"),
    "HBL": .pressAX("Left Border"),
    "HBR": .pressAX("Right Border"),
    "HBN": .pressAX("No Border"),
    "HBA": .pressAX("All Borders"),
    "HBS": .pressAX("Outside Borders"),
    "HBT": .pressAX("Thick Box Border"),
    "HBB": .pressAX("Bottom Double Border"),
    "HBH": .pressAX("Thick Bottom Border"),
    "HBD": .pressAX("Top and Bottom Border"),
    "HBC": .pressAX("Top and Thick Bottom Border"),
    "HBU": .pressAX("Top and Double Bottom Border"),
    "HBW": .pressAX("Draw Border"),
    "HBG": .pressAX("Draw Border Grid"),
    "HBE": .pressAX("Erase Border"),
    "HBI": .pressAX("Line Color"),
    "HBY": .pressAX("Line Style"),
    "HBM": .pressAX("More Borders..."),
    
    // --- FILL COLOR / SHADING (HH) ---
    "HHN": .pressAX("No Fill"),
    "HHM": .pressAX("More Colors..."),
    
    // --- MERGE & CENTER (HM) ---
    "HMC": .pressAX("Merge & Center"),
    "HMA": .pressAX("Merge Across"),
    "HMM": .pressAX("Merge Cells"),
    "HMU": .pressAX("Unmerge Cells"),
    "HMS": .pressAX("Center Across Selection"),
    
    // --- AUTOSUM (HU) ---
    "HUS": .pressAX("Sum"),
    "HUU": .pressAX("Sum"),
    "HUA": .pressAX("Average"),
    "HUC": .pressAX("Count Numbers"),
    "HUM": .pressAX("Max"),
    "HUI": .pressAX("Min"),
    "HUF": .pressAX("More Functions..."),
    
    // --- SORT & FILTER (HS) ---
    "HSS": .pressAX("Sort A to Z"),
    "HSO": .pressAX("Sort Z to A"),
    "HSU": .pressAX("Custom Sort..."),
    "HST": .pressAX("Filter"),
    "HSC": .pressAX("Clear"),
    "HSA": .pressAX("Reapply"),
    
    // --- CLEAR (HE) ---
    "HEA": .pressAX("Clear All"),
    "HEF": .pressAX("Clear Formats"),
    "HEC": .pressAX("Clear Contents"),
    "HEM": .pressAX("Clear Comments and Notes"),
    "HEL": .pressAX("Clear Hyperlinks"),
    "HEO": .pressAX("Clear Hyperlinks"),
    "HER": .pressAX("Remove Hyperlinks"),
    "HEU": .pressAX("Remove Hyperlinks"),
    
    // Clear (HEE variants)
    "HEEA": .pressAX("Clear All"),
    "HEEF": .pressAX("Clear Formats"),
    "HEEC": .pressAX("Clear Contents"),
    "HEEM": .pressAX("Clear Comments and Notes"),
    "HEEL": .pressAX("Clear Hyperlinks"),
    "HEEO": .pressAX("Clear Hyperlinks"),
    "HEER": .pressAX("Remove Hyperlinks"),
    "HEEU": .pressAX("Remove Hyperlinks"),
    
    // --- FIND & SELECT (HFD) ---
    "HFDF": .pressAX("Find..."),
    "HFDR": .pressAX("Replace..."),
    "HFDG": .pressAX("Go To..."),
    "HFDS": .pressAX("Go To Special..."),
    "HFDU": .pressAX("Formulas"),
    "HFDM": .pressAX("Notes"),
    "HFDN": .pressAX("Notes"),
    "HFDC": .pressAX("Conditional Formatting"),
    "HFDO": .pressAX("Constants"),
    "HFDV": .pressAX("Data Validation"),
    "HFDD": .pressAX("Data Validation"),
    "HFDB": .pressAX("Select Objects"),
    "HFDP": .pressAX("Selection Pane..."),
    
    // --- ORIENTATION (HFQ) ---
    "HFQO": .pressAX("Angle Counterclockwise"),
    "HFQL": .pressAX("Angle Clockwise"),
    "HFQV": .pressAX("Vertical Text"),
    "HFQU": .pressAX("Rotate Text Up"),
    "HFQD": .pressAX("Rotate Text Down"),
    "HFQM": .pressAX("Format Cell Alignment"),
    
    // --- FORMAT AS TABLE (HT) --- (gallery: use arrow keys + Enter for styles)
    "HTN": .pressAX("New Table Style..."),
    "HTP": .pressAX("New PivotTable Style..."),
    
    // --- CELL STYLES (HJ) --- (gallery: use arrow keys + Enter for styles)
    "HJN": .pressAX("New Cell Style..."),
    "HJM": .pressAX("Merge Styles..."),
    
    // --- WRAP TEXT (HW) ---
    "HWW": .pressAX("Wrap Text"),
    "HWS": .pressAX("Shrink Text to Fit"),
    "HWF": .pressAX("Shrink Text to Fit"),
    
    // --- NUMBER FORMAT (HN / HAN / HP / HK / H0 / H9) ---
    "HN":  .focusRibbon("Number Format"),
    "HAN": .pressAX("Accounting Number Format"),
    "HP":  .pressAX("Percent Style"),
    "HK":  .pressAX("Comma Style"),
    "H0":  .pressAX("Increase Decimal"),
    "H9":  .pressAX("Decrease Decimal"),
    
    // --- ALIGNMENT (HA) ---
    "HAT": .pressAX("Top Align"),
    "HAM": .pressAX("Middle Align"),
    "HAB": .pressAX("Bottom Align"),
    "HAL": .pressAX("Align Left"),
    "HAC": .pressAX("Center"),
    "HAR": .pressAX("Align Right"),
    "H5":  .pressAX("Decrease Indent"),
    "H6":  .pressAX("Increase Indent"),
    "HAO": .pressAX("Decrease Indent"),
    "HAI": .pressAX("Increase Indent"),
    
    // --- ADD-INS (HAS) ---
    "HAS": .pressAX("Add-ins"),
    
    // --- FILL (HFI) ---
    "HFID": .pressAX("Down"),
    "HFIR": .pressAX("Right"),
    "HFIU": .pressAX("Up"),
    "HFIL": .pressAX("Left"),
    "HFIS": .pressAX("Series..."),
    "HFIJ": .pressAX("Justify"),
    "HFIE": .pressAX("Flash Fill"),
    "HFIA": .pressAX("Across Worksheets..."),
    
    // --- FONT & CLIPBOARD (HFF, HFS, HFG, HFK, HFC, HFP) ---
    "HFF":  .focusRibbon("Font:"),
    "HFS":  .focusRibbon("Font Size:"),
    "HFG":  .pressAX("Increase Font Size"),
    "HFK":  .pressAX("Decrease Font Size"),
    "HFCA": .pressAX("Automatic"),
    "HFCM": .pressAX("More Colors..."),
    "HFP":  .custom({ pid in pressFormatPainter(pid: pid) }),
    
    // --- FONT / ALIGNMENT / CLIPBOARD ---
    "H1":  .keys([(11, [.maskCommand])]), // Cmd + B (Bold)
    "H2":  .keys([(34, [.maskCommand])]), // Cmd + I (Italic)
    "H3U": .pressAX("Underline"),
    "H3D": .pressAX("Double Underline"),
    "HV":  .keys([(9, [.maskCommand])]),  // Cmd + V (Paste)
    "HC":  .keys([(8, [.maskCommand])]),  // Cmd + C (Copy)
    "HX":  .keys([(7, [.maskCommand])]),  // Cmd + X (Cut)
    
    // =========================================================================
    // INSERT TAB (Alt + N)
    // =========================================================================

    // --- 1. FORMS (Alt + N + FR) ---
    "NFRN": .pressAX("Forms > New Form"),
    "NFRP": .pressAX("Forms > Preview Form"),
    "NFRE": .pressAX("Forms > Edit Form"),
    "NFRS": .pressAX("Forms > Send Form"),

    // --- 2. FROM PICTURE (Alt + N + F1) ---
    "NF1F": .pressAX("From Picture > Picture From File..."),
    "NF1C": .pressAX("From Picture > Picture From Clipboard"),

    // --- 3. PICTURES (Alt + N + P1) ---
    // Place in Cell (C or I)
    "NP1CB": .pressAX("Place in Cell > Photo Browser…"),
    "NP1CF": .pressAX("Place in Cell > Picture from File..."),
    "NP1CD": .pressAX("Place in Cell > Picture from File..."),
    "NP1CS": .pressAX("Place in Cell > Stock Images..."),
    "NP1CO": .pressAX("Place in Cell > Online Pictures..."),
    "NP1IB": .pressAX("Place in Cell > Photo Browser…"),
    "NP1IF": .pressAX("Place in Cell > Picture from File..."),
    "NP1ID": .pressAX("Place in Cell > Picture from File..."),
    "NP1IS": .pressAX("Place in Cell > Stock Images..."),
    "NP1IO": .pressAX("Place in Cell > Online Pictures..."),
    // Place over Cells (O or V)
    "NP1OB": .pressAX("Place over Cells > Photo Browser…"),
    "NP1OF": .pressAX("Place over Cells > Picture from File..."),
    "NP1OD": .pressAX("Place over Cells > Picture from File..."),
    "NP1OS": .pressAX("Place over Cells > Stock Images..."),
    "NP1OO": .pressAX("Place over Cells > Online Pictures..."),
    "NP1VB": .pressAX("Place over Cells > Photo Browser…"),
    "NP1VF": .pressAX("Place over Cells > Picture from File..."),
    "NP1VD": .pressAX("Place over Cells > Picture from File..."),
    "NP1VS": .pressAX("Place over Cells > Stock Images..."),
    "NP1VO": .pressAX("Place over Cells > Online Pictures..."),

    // --- 4. 3D MODELS (Alt + N + S3) ---
    "NS3D": .pressAX("3D Models > This Device..."),
    "NS3F": .pressAX("3D Models > This Device..."),
    "NS3S": .pressAX("3D Models > Stock 3D Models..."),
    "NS3O": .pressAX("3D Models > Stock 3D Models..."),

    // --- 5. SMARTART (Alt + N + M) ---
    "NML": .pressAX("SmartArt > List"),
    "NMP": .pressAX("SmartArt > Process"),
    "NMC": .pressAX("SmartArt > Cycle"),
    "NMH": .pressAX("SmartArt > Hierarchy"),
    "NMR": .pressAX("SmartArt > Relationship"),
    "NMM": .pressAX("SmartArt > Matrix"),
    "NMY": .pressAX("SmartArt > Pyramid"),
    "NMI": .pressAX("SmartArt > Picture"),
    "NMT": .pressAX("SmartArt > Timeline"),
    "NME": .pressAX("SmartArt > Meet The Team"),
    "NMX": .pressAX("SmartArt > Text Card"),

    // --- 6. SPARKLINES (Alt + N + Y5) ---
    "NY5L": .pressAX("Sparklines > Line"),
    "NY5C": .pressAX("Sparklines > Column"),
    "NY5W": .pressAX("Sparklines > Win/Loss"),

    // --- OTHER INSERT TAB CONTROLS (Native KeyTip Passthrough Equivalents) ---
    "NV":  .pressAX("InsertRibbon > PivotTable"),
    "NY1": .pressAX("InsertRibbon > Recommended PivotTables"),
    "NT":  .pressAX("InsertRibbon > Table"),
    "NSH": .custom({ pid in openRibbonMenu(pid: pid, name: "Shapes", tab: "Insert") }),
    "NY2": .pressAX("InsertRibbon > Icons"),
    "NSC": .custom({ pid in openRibbonMenu(pid: pid, name: "Screenshot", tab: "Insert") }),
    "NC1": .pressAX("InsertRibbon > Checkbox"),
    "NR":  .custom({ pid in openRibbonMenu(pid: pid, name: "Recommended Charts", tab: "Insert") }),
    "NC2": .custom({ pid in openRibbonMenu(pid: pid, name: "Column", tab: "Insert") }),
    "NN":  .custom({ pid in openRibbonMenu(pid: pid, name: "Line", tab: "Insert") }),
    "NQ":  .custom({ pid in openRibbonMenu(pid: pid, name: "Pie", tab: "Insert") }),
    "NHI": .custom({ pid in openRibbonMenu(pid: pid, name: "Hierarchy", tab: "Insert") }),
    "NSA": .custom({ pid in openRibbonMenu(pid: pid, name: "Statistical", tab: "Insert") }),
    "ND":  .custom({ pid in openRibbonMenu(pid: pid, name: "X Y (Scatter)", tab: "Insert") }),
    "NY3": .custom({ pid in openRibbonMenu(pid: pid, name: "Waterfall", tab: "Insert") }),
    "NSD": .custom({ pid in openRibbonMenu(pid: pid, name: "Combo", tab: "Insert") }),
    "NY4": .custom({ pid in openRibbonMenu(pid: pid, name: "Maps", tab: "Insert") }),
    "NPC": .pressAX("InsertRibbon > PivotChart"),
    "NSF": .pressAX("InsertRibbon > Slicer"),
    "NST": .pressAX("InsertRibbon > Timeline"),
    "NI":  .pressAX("InsertRibbon > Link"),
    "NC3": .pressAX("InsertRibbon > New Comment"),
    "NX":  .pressAX("InsertRibbon > Text Box"),
    "NH1": .pressAX("InsertRibbon > Header & Footer"),
    "NW":  .custom({ pid in openRibbonMenu(pid: pid, name: "WordArt", tab: "Insert") }),
    "NJ":  .pressAX("InsertRibbon > Object"),
    "NE":  .custom({ pid in openRibbonMenu(pid: pid, name: "Equation", tab: "Insert") }),
    "NY6": .pressAX("InsertRibbon > Symbol"),

    // =========================================================================
    // DRAW TAB (Alt + JI)
    // =========================================================================

    // --- 1. ERASER (Alt + JI + E) ---
    "JIES": .pressAX("Eraser > Stroke Eraser"),
    "JIEK": .pressAX("Eraser > Stroke Eraser"),
    "JIE1": .pressAX("Eraser > Stroke Eraser"),
    "JIEL": .pressAX("Eraser > Small Eraser"),
    "JIEA": .pressAX("Eraser > Small Eraser"),
    "JIE2": .pressAX("Eraser > Small Eraser"),
    "JIEM": .pressAX("Eraser > Medium Eraser"),
    "JIE3": .pressAX("Eraser > Medium Eraser"),
    "JIEG": .pressAX("Eraser > Segment Eraser"),
    "JIET": .pressAX("Eraser > Segment Eraser"),
    "JIE4": .pressAX("Eraser > Segment Eraser"),

    // --- 2. ADD PEN / HIGHLIGHTER / PENCIL (Alt + JI + A) ---
    "JIAP": .pressAX("Add > Pen"),
    "JIA1": .pressAX("Add > Pen"),
    "JIAH": .pressAX("Add > Highlighter"),
    "JIA2": .pressAX("Add > Highlighter"),
    "JIAC": .pressAX("Add > Pencil"),
    "JIAL": .pressAX("Add > Pencil"),
    "JIA3": .pressAX("Add > Pencil"),

    // --- OTHER DRAW TAB CONTROLS (Native KeyTip Passthrough Equivalents) ---
    "JID":  .pressAX("DrawRibbon > Draw"),
    "JIL":  .pressAX("DrawRibbon > Lasso Select"),
    "JIY":  .pressAX("DrawRibbon > Draw with\nTrackpad"),

    // =========================================================================
    // PAGE LAYOUT TAB (Alt + P)
    // =========================================================================

    // --- 1. THEMES (Alt + P + TH) --- (gallery: use arrow keys + Enter for themes, or B / S)
    "PTHB": .pressAX("Themes > Browse for Themes..."),
    "PTHS": .pressAX("Themes > Save Current Theme..."),
    "PTHO": .pressAX("Themes > Office"),

    // --- 2. MARGINS (Alt + P + M) ---
    "PMN": .pressAX("Margins > Normal"),
    "PM1": .pressAX("Margins > Normal"),
    "PMW": .pressAX("Margins > Wide"),
    "PM2": .pressAX("Margins > Wide"),
    "PMR": .pressAX("Margins > Narrow"),
    "PMA": .pressAX("Margins > Narrow"),
    "PM3": .pressAX("Margins > Narrow"),
    "PML": .pressAX("Margins > Last Custom Setting"),
    "PMC": .pressAX("Margins > Custom Margins..."),
    "PMM": .pressAX("Margins > Custom Margins..."),
    "PM4": .pressAX("Margins > Custom Margins..."),

    // --- 3. ORIENTATION (Alt + P + O) ---
    "POP": .pressAX("PageOrientation > Portrait"),
    "PO1": .pressAX("PageOrientation > Portrait"),
    "POL": .pressAX("PageOrientation > Landscape"),
    "PO2": .pressAX("PageOrientation > Landscape"),

    // --- 4. PRINT AREA (Alt + P + R) ---
    "PRS": .pressAX("Print Area > Set Print Area"),
    "PR1": .pressAX("Print Area > Set Print Area"),
    "PRC": .pressAX("Print Area > Clear Print Area"),
    "PR2": .pressAX("Print Area > Clear Print Area"),
    "PRA": .pressAX("Print Area > Add to Print Area"),
    "PR3": .pressAX("Print Area > Add to Print Area"),

    // --- 5. BREAKS (Alt + P + B) ---
    "PBI": .pressAX("Breaks > Insert Page Break"),
    "PB1": .pressAX("Breaks > Insert Page Break"),
    "PBR": .pressAX("Breaks > Remove Page Break"),
    "PB2": .pressAX("Breaks > Remove Page Break"),
    "PBA": .pressAX("Breaks > Reset All Page Breaks"),
    "PBS": .pressAX("Breaks > Reset All Page Breaks"),
    "PB3": .pressAX("Breaks > Reset All Page Breaks"),

    // --- OTHER PAGE LAYOUT TAB CONTROLS (Native KeyTip Passthrough Equivalents) ---
    "PTC": .custom({ pid in openRibbonMenu(pid: pid, name: "Colors", tab: "Page Layout") }),
    "PTF": .custom({ pid in openRibbonMenu(pid: pid, name: "Fonts", tab: "Page Layout") }),
    "PSZ": .custom({ pid in openRibbonMenu(pid: pid, name: "Size", tab: "Page Layout") }),
    "PG":  .pressAX("PageLayoutRibbon > Background"),
    "PI":  .pressAX("PageLayoutRibbon > Print Titles"),
    "PSP": .pressAX("PageLayoutRibbon > Page Setup"),
    "PW":  .focusRibbon("Width:"),
    "PH":  .focusRibbon("Height:"),

    // =========================================================================
    // FORMULAS TAB (Alt + M)
    // =========================================================================

    // --- 1. AUTOSUM (Alt + M + U) ---
    "MUS": .pressAX("FormulasAutoSum > Sum"),
    "MUU": .pressAX("FormulasAutoSum > Sum"),
    "MUA": .pressAX("FormulasAutoSum > Average"),
    "MUC": .pressAX("FormulasAutoSum > Count Numbers"),
    "MUM": .pressAX("FormulasAutoSum > Max"),
    "MUI": .pressAX("FormulasAutoSum > Min"),
    "MUF": .pressAX("FormulasAutoSum > More Functions..."),

    // --- 2. RECENTLY USED (Alt + M + R) (Insert Function only) ---
    "MRF": .pressAX("Recently Used > Insert Function..."),
    "MRI": .pressAX("Recently Used > Insert Function..."),

    // --- 3. FINANCIAL (Alt + M + I) (Insert Function only) ---
    "MIF": .pressAX("Financial > Insert Function..."),
    "MII": .pressAX("Financial > Insert Function..."),

    // --- 4. LOGICAL (Alt + M + L) (Insert Function only) ---
    "MLF": .pressAX("Logical > Insert Function..."),
    "MLI": .pressAX("Logical > Insert Function..."),

    // --- 5. TEXT (Alt + M + T) (Insert Function only) ---
    "MTF": .pressAX("Text > Insert Function..."),
    "MTI": .pressAX("Text > Insert Function..."),

    // --- 6. DATE & TIME (Alt + M + E) (Insert Function only) ---
    "MEF": .pressAX("Date & Time > Insert Function..."),
    "MEI": .pressAX("Date & Time > Insert Function..."),

    // --- 7. LOOKUP & REFERENCE (Alt + M + O) (Insert Function only) ---
    "MOF": .pressAX("Lookup & Reference > Insert Function..."),
    "MOI": .pressAX("Lookup & Reference > Insert Function..."),

    // --- 8. MATH & TRIG (Alt + M + G) (Insert Function only) ---
    "MGF": .pressAX("Math & Trig > Insert Function..."),
    "MGI": .pressAX("Math & Trig > Insert Function..."),

    // --- 9. MORE FUNCTIONS (Alt + M + Q) (6 Subsections + Insert Function in each) ---
    "MQSF": .pressAX("MoreFnStatistical > Insert Function..."),
    "MQSI": .pressAX("MoreFnStatistical > Insert Function..."),
    "MQEF": .pressAX("MoreFnEngineering > Insert Function..."),
    "MQEI": .pressAX("MoreFnEngineering > Insert Function..."),
    "MQCF": .pressAX("MoreFnCube > Insert Function..."),
    "MQCI": .pressAX("MoreFnCube > Insert Function..."),
    "MQIF": .pressAX("MoreFnInformation > Insert Function..."),
    "MQII": .pressAX("MoreFnInformation > Insert Function..."),
    "MQMF": .pressAX("MoreFnCompatibility > Insert Function..."),
    "MQMI": .pressAX("MoreFnCompatibility > Insert Function..."),
    "MQOF": .pressAX("MoreFnCompatibility > Insert Function..."),
    "MQOI": .pressAX("MoreFnCompatibility > Insert Function..."),
    "MQWF": .pressAX("MoreFnWeb > Insert Function..."),
    "MQWI": .pressAX("MoreFnWeb > Insert Function..."),

    // --- 10. DEFINE NAME (Alt + M + M) ---
    "MMD": .pressAX("Define Name > Define Name..."),
    "MMM": .pressAX("Define Name > Define Name..."),
    "MM1": .pressAX("Define Name > Define Name..."),
    "MMA": .pressAX("Define Name > Apply Names..."),
    "MM2": .pressAX("Define Name > Apply Names..."),

    // --- 11. REMOVE ARROWS (Alt + M + A) ---
    "MAA": .pressAX("Remove Arrows > Remove Arrows"),
    "MAR": .pressAX("Remove Arrows > Remove Arrows"),
    "MA1": .pressAX("Remove Arrows > Remove Arrows"),
    "MAP": .pressAX("Remove Arrows > Remove Precedent Arrows"),
    "MA2": .pressAX("Remove Arrows > Remove Precedent Arrows"),
    "MAD": .pressAX("Remove Arrows > Remove Dependent Arrows"),
    "MA3": .pressAX("Remove Arrows > Remove Dependent Arrows"),

    // --- 12. ERROR CHECKING (Alt + M + K) ---
    "MKE": .pressAX("Error Checking > Error Checking..."),
    "MKK": .pressAX("Error Checking > Error Checking..."),
    "MK1": .pressAX("Error Checking > Error Checking..."),
    "MKT": .pressAX("Error Checking > Trace Error"),
    "MK2": .pressAX("Error Checking > Trace Error"),
    "MKC": .pressAX("Error Checking > Circular References"),
    "MK3": .pressAX("Error Checking > Circular References"),

    // --- 13. CALCULATION OPTIONS (Alt + M + X) ---
    "MXA": .pressAX("Calculation Options > Automatic"),
    "MX1": .pressAX("Calculation Options > Automatic"),
    "MXP": .pressAX("Calculation Options > Partial"),
    "MXE": .pressAX("Calculation Options > Partial"),
    "MX2": .pressAX("Calculation Options > Partial"),
    "MXM": .pressAX("Calculation Options > Manual"),
    "MX3": .pressAX("Calculation Options > Manual"),
    "MXF": .pressAX("Calculation Options > Format Stale Values"),
    "MXS": .pressAX("Calculation Options > Format Stale Values"),
    "MX4": .pressAX("Calculation Options > Format Stale Values"),
    "MXC1": .pressAX("Compatibility Version > Version 1"),
    "MXV1": .pressAX("Compatibility Version > Version 1"),
    "MXC2": .pressAX("Compatibility Version > Version 2 (Recommended)"),
    "MXV2": .pressAX("Compatibility Version > Version 2 (Recommended)"),
    "MXCL": .pressAX("Compatibility Version > Learn More"),
    "MXCM": .pressAX("Compatibility Version > Learn More"),
    "MXVL": .pressAX("Compatibility Version > Learn More"),

    // --- OTHER FORMULAS TAB CONTROLS (Native KeyTip Passthrough Equivalents) ---
    "MF":  .pressAX("FormulasRibbon > Insert Function"),
    "MN":  .pressAX("FormulasRibbon > Name Manager"),
    "MS":  .custom({ pid in openRibbonMenu(pid: pid, name: "Use in Formula", tab: "Formulas") }),
    "MC":  .pressAX("FormulasRibbon > Create from Selection"),
    "MP":  .pressAX("FormulasRibbon > Trace Precedents"),
    "MD":  .pressAX("FormulasRibbon > Trace Dependents"),
    "MH":  .pressAX("FormulasRibbon > Show Formulas"),
    "MW":  .pressAX("FormulasRibbon > Watch Window"),
    "MB":  .pressAX("FormulasRibbon > Calculate Now"),
    "MJ":  .pressAX("FormulasRibbon > Calculate Sheet"),

    // =========================================================================
    // DATA TAB (Alt + A)
    // =========================================================================

    // --- 1. GET DATA (POWER QUERY) (Alt + A + PN) ---
    "APNG": .pressAX("Get Data (Power Query) > Get Data (Power Query)..."),
    "APNP": .pressAX("Get Data (Power Query) > Get Data (Power Query)..."),
    "APN1": .pressAX("Get Data (Power Query) > Get Data (Power Query)..."),
    "APNL": .pressAX("Get Data (Power Query) > Launch Power Query Editor..."),
    "APNE": .pressAX("Get Data (Power Query) > Launch Power Query Editor..."),
    "APN2": .pressAX("Get Data (Power Query) > Launch Power Query Editor..."),
    "APND": .pressAX("Get Data (Power Query) > Data Source Settings..."),
    "APN3": .pressAX("Get Data (Power Query) > Data Source Settings..."),
    "APNB": .pressAX("Get Data (Power Query) > From Database (Microsoft Query)"),
    "APNM": .pressAX("Get Data (Power Query) > From Database (Microsoft Query)"),
    "APNQ": .pressAX("Get Data (Power Query) > From Database (Microsoft Query)"),
    "APN4": .pressAX("Get Data (Power Query) > From Database (Microsoft Query)"),
    "APNH": .pressAX("Get Data (Power Query) > From HTML"),
    "APN5": .pressAX("Get Data (Power Query) > From HTML"),
    "APNT": .pressAX("Get Data (Power Query) > From Text (Legacy)"),
    "APN6": .pressAX("Get Data (Power Query) > From Text (Legacy)"),
    "APNS": .pressAX("Get Data (Power Query) > From SQL Server ODBC"),
    "APNO": .pressAX("Get Data (Power Query) > From SQL Server ODBC"),
    "APN7": .pressAX("Get Data (Power Query) > From SQL Server ODBC"),

    // --- 2. FROM PICTURE (Alt + A + F1) ---
    "AF1F": .pressAX("DataFromPicture > Picture From File..."),
    "AF11": .pressAX("DataFromPicture > Picture From File..."),
    "AF1C": .pressAX("DataFromPicture > Picture From Clipboard"),
    "AF12": .pressAX("DataFromPicture > Picture From Clipboard"),

    // --- 3. REFRESH ALL (Alt + A + R) ---
    "ARA": .pressAX("Refresh All > Refresh All"),
    "AR1": .pressAX("Refresh All > Refresh All"),
    "ARR": .pressAX("Refresh All > Refresh"),
    "AR2": .pressAX("Refresh All > Refresh"),
    "ARS": .pressAX("Refresh All > Refresh Status"),
    "AR3": .pressAX("Refresh All > Refresh Status"),
    "ARC": .pressAX("Refresh All > Cancel Refresh"),
    "AR4": .pressAX("Refresh All > Cancel Refresh"),
    "ARP": .pressAX("Refresh All > Properties"),
    "ARO": .pressAX("Refresh All > Properties"),
    "AR5": .pressAX("Refresh All > Properties"),

    // --- 4. DATA VALIDATION (Alt + A + V1) ---
    "AV1V": .pressAX("Data Validation > Data Validation..."),
    "AV1D": .pressAX("Data Validation > Data Validation..."),
    "AV11": .pressAX("Data Validation > Data Validation..."),
    "AV1I": .pressAX("Data Validation > Circle Invalid Data"),
    "AV1C": .pressAX("Data Validation > Circle Invalid Data"),
    "AV12": .pressAX("Data Validation > Circle Invalid Data"),
    "AV1R": .pressAX("Data Validation > Clear Validation Circles"),
    "AV1L": .pressAX("Data Validation > Clear Validation Circles"),
    "AV1E": .pressAX("Data Validation > Clear Validation Circles"),
    "AV13": .pressAX("Data Validation > Clear Validation Circles"),

    // --- 5. WHAT-IF ANALYSIS (Alt + A + W) ---
    "AWS": .pressAX("What-If Analysis > Scenario Manager..."),
    "AW1": .pressAX("What-If Analysis > Scenario Manager..."),
    "AWG": .pressAX("What-If Analysis > Goal Seek..."),
    "AW2": .pressAX("What-If Analysis > Goal Seek..."),
    "AWT": .pressAX("What-If Analysis > Data Table..."),
    "AWD": .pressAX("What-If Analysis > Data Table..."),
    "AW3": .pressAX("What-If Analysis > Data Table..."),

    // --- 6. GROUP (Alt + A + G) ---
    "AGG": .pressAX("Group > Group..."),
    "AG1": .pressAX("Group > Group..."),
    "AGA": .pressAX("Group > Auto Outline"),
    "AGO": .pressAX("Group > Auto Outline"),
    "AG2": .pressAX("Group > Auto Outline"),

    // --- 7. UNGROUP (Alt + A + U) ---
    "AUU": .pressAX("Ungroup > Ungroup..."),
    "AU1": .pressAX("Ungroup > Ungroup..."),
    "AUC": .pressAX("Ungroup > Clear Outline"),
    "AUO": .pressAX("Ungroup > Clear Outline"),
    "AU2": .pressAX("Ungroup > Clear Outline"),

    // --- OTHER DATA TAB CONTROLS (Native KeyTip Passthrough Equivalents) ---
    "AO":  .pressAX("DataRibbon > Queries & Connections"),
    "AP1": .pressAX("DataRibbon > Properties"),
    "AK":  .pressAX("DataRibbon > Workbook Links"),
    "ASA": .pressAX("DataRibbon > Sort A to Z"),
    "ASD": .pressAX("DataRibbon > Sort Z to A"),
    "ASS": .pressAX("DataRibbon > Sort"),
    "AT":  .pressAX("DataRibbon > Filter"),
    "AC":  .pressAX("DataRibbon > Clear"),
    "AY1": .pressAX("DataRibbon > Reapply"),
    "AQ":  .pressAX("DataRibbon > Advanced"),
    "AE":  .pressAX("DataRibbon > Text to Columns"),
    "AFE": .pressAX("DataRibbon > Analyze Data"),
    "AFF": .pressAX("DataRibbon > Flash Fill"),
    "AM":  .pressAX("DataRibbon > Remove Duplicates"),
    "AN":  .pressAX("DataRibbon > Consolidate"),
    "AB":  .pressAX("DataRibbon > Subtotal"),
    "AJ":  .pressAX("DataRibbon > Show Detail"),
    "AH1": .pressAX("DataRibbon > Hide Detail"),
    "AH2": .pressAX("DataRibbon > Analysis Tools"),
    "AY2": .pressAX("DataRibbon > Data Analysis"),
    "AV2": .pressAX("DataRibbon > Solver"),

    // =========================================================================
    // REVIEW TAB (Alt + R)
    // =========================================================================

    // --- 1. CHECK ACCESSIBILITY (Alt + R + A) ---
    "RAA": .pressAX("Check Accessibility > Check Accessibility"),
    "RAC": .pressAX("Check Accessibility > Check Accessibility"),
    "RA1": .pressAX("Check Accessibility > Check Accessibility"),
    "RAT": .pressAX("Check Accessibility > Alt Text"),
    "RAX": .pressAX("Check Accessibility > Alt Text"),
    "RA2": .pressAX("Check Accessibility > Alt Text"),
    "RAF": .pressAX("Check Accessibility > Format as Table"),
    "RA3": .pressAX("Check Accessibility > Format as Table"),
    "RAU": .pressAX("Check Accessibility > Unmerge Cells"),
    "RAM": .pressAX("Check Accessibility > Unmerge Cells"),
    "RA4": .pressAX("Check Accessibility > Unmerge Cells"),
    "RAH": .pressAX("Check Accessibility > Accessibility Help"),
    "RA5": .pressAX("Check Accessibility > Accessibility Help"),

    // --- 2. NOTES (Alt + R + T) ---
    "RTN": .pressAX("ReviewNotes > New Note"),
    "RTE": .pressAX("ReviewNotes > New Note"),
    "RT1": .pressAX("ReviewNotes > New Note"),
    "RTP": .pressAX("ReviewNotes > Previous Note"),
    "RTV": .pressAX("ReviewNotes > Previous Note"),
    "RT2": .pressAX("ReviewNotes > Previous Note"),
    "RTX": .pressAX("ReviewNotes > Next Note"),
    "RT3": .pressAX("ReviewNotes > Next Note"),
    "RTH": .pressAX("ReviewNotes > Show/Hide Note"),
    "RT4": .pressAX("ReviewNotes > Show/Hide Note"),
    "RTA": .pressAX("ReviewNotes > Show All Notes"),
    "RTS": .pressAX("ReviewNotes > Show All Notes"),
    "RT5": .pressAX("ReviewNotes > Show All Notes"),
    "RTC": .pressAX("ReviewNotes > Convert to Comments"),
    "RT6": .pressAX("ReviewNotes > Convert to Comments"),

    // --- 3. RESTRICT PERMISSION (Alt + R + R) ---
    "RRN": .pressAX("Restrict Permission > No Restrictions"),
    "RRU": .pressAX("Restrict Permission > No Restrictions"),
    "RR1": .pressAX("Restrict Permission > No Restrictions"),
    "RRR": .pressAX("Restrict Permission > Restricted Access..."),
    "RRA": .pressAX("Restrict Permission > Restricted Access..."),
    "RR2": .pressAX("Restrict Permission > Restricted Access..."),

    // --- 4. HIDE INK (Alt + R + H2) ---
    "RH2H": .pressAX("Hide Ink > Hide Ink"),
    "RH2I": .pressAX("Hide Ink > Hide Ink"),
    "RH21": .pressAX("Hide Ink > Hide Ink"),
    "RH2S": .pressAX("Hide Ink > Delete All Ink on Sheet"),
    "RH2D": .pressAX("Hide Ink > Delete All Ink on Sheet"),
    "RH22": .pressAX("Hide Ink > Delete All Ink on Sheet"),
    "RH2W": .pressAX("Hide Ink > Delete All Ink in Workbook"),
    "RH2B": .pressAX("Hide Ink > Delete All Ink in Workbook"),
    "RH23": .pressAX("Hide Ink > Delete All Ink in Workbook"),

    // --- OTHER REVIEW TAB CONTROLS (Native KeyTip Passthrough Equivalents) ---
    "RS":  .pressAX("ReviewRibbon > Spelling"),
    "RE":  .pressAX("ReviewRibbon > Thesaurus"),
    "RB":  .pressAX("ReviewRibbon > Workbook Statistics"),
    "RL":  .pressAX("ReviewRibbon > Translate"),
    "RG":  .pressAX("ReviewRibbon > Show Changes"),
    "RC":  .pressAX("ReviewRibbon > New Comment"),
    "RD":  .pressAX("ReviewRibbon > Delete"),
    "RV":  .pressAX("ReviewRibbon > Previous Comment"),
    "RN":  .pressAX("ReviewRibbon > Next Comment"),
    "RH1": .pressAX("ReviewRibbon > Show Comments"),
    "RPS": .pressAX("ReviewRibbon > Protect Sheet"),
    "RPW": .pressAX("ReviewRibbon > Protect Workbook"),
    "RO":  .pressAX("ReviewRibbon > Always Open Read-Only"),

    // =========================================================================
    // VIEW TAB (Alt + W)
    // =========================================================================

    // --- 1. SHOW -> FOCUS CELL (Alt + W + ZS -> E1) ---
    "WZSE1F": .pressAX("Focus Cell > Focus Cell"),
    "WZSE11": .pressAX("Focus Cell > Focus Cell"),
    "WZSE1C": .pressAX("Focus Cell > Focus Cell Color"),
    "WZSE12": .pressAX("Focus Cell > Focus Cell Color"),
    "WZSE1A": .pressAX("Focus Cell > Show Auto-Highlight"),
    "WZSE1H": .pressAX("Focus Cell > Show Auto-Highlight"),
    "WZSE1S": .pressAX("Focus Cell > Show Auto-Highlight"),
    "WZSE13": .pressAX("Focus Cell > Show Auto-Highlight"),

    // Other controls inside Show popover (Alt + W + ZS -> K, R1, VG, VF, VH, VI)
    "WZSK":  .pressAX("ShowPopover > Navigation"),
    "WZSR1": .pressAX("ShowPopover > Ruler"),
    "WZSVG": .pressAX("ShowPopover > Gridlines"),
    "WZSVF": .pressAX("ShowPopover > Formula Bar"),
    "WZSVH": .pressAX("ShowPopover > Headings"),
    "WZSVI": .pressAX("ShowPopover > Data Type Icons"),

    // --- 2. FREEZE PANES (Alt + W + F) ---
    "WFF": .pressAX("Freeze Panes > Freeze Panes"),
    "WFU": .pressAX("Freeze Panes > Freeze Panes"),
    "WF1": .pressAX("Freeze Panes > Freeze Panes"),
    "WFR": .pressAX("Freeze Panes > Freeze Top Row"),
    "WFT": .pressAX("Freeze Panes > Freeze Top Row"),
    "WF2": .pressAX("Freeze Panes > Freeze Top Row"),
    "WFC": .pressAX("Freeze Panes > Freeze First Column"),
    "WF3": .pressAX("Freeze Panes > Freeze First Column"),

    // --- 3. SWITCH WINDOWS (Alt + W + W -> Dynamic 1..N handled dynamically in callback) ---

    // --- OTHER VIEW TAB CONTROLS (Native KeyTip Passthrough Equivalents) ---
    "WVC": .custom({ pid in
        selectRibbonTab(pid: pid, name: "View")
        focusRibbonControl(pid: pid, descPrefix: "Switch Sheet View")
    }),
    "WVK": .pressAX("ViewRibbon > Keep"),
    "WVE": .pressAX("ViewRibbon > Exit"),
    "WVN": .pressAX("ViewRibbon > New"),
    "WVO": .pressAX("ViewRibbon > Options"),
    "WL":  .pressAX("ViewRibbon > Normal"),
    "WI":  .pressAX("ViewRibbon > Page Break Preview"),
    "WP1": .pressAX("ViewRibbon > Page Layout"),
    "WC":  .pressAX("ViewRibbon > Custom Views"),
    "WQ":  .custom({ pid in
        selectRibbonTab(pid: pid, name: "View")
        focusRibbonControl(pid: pid, descPrefix: "Zoom")
    }),
    "WJ":  .pressAX("ViewRibbon > Zoom to 100%"),
    "WG":  .pressAX("ViewRibbon > Zoom to Selection"),
    "WN":  .menu(["Window", "New Window"]),
    "WA":  .pressAX("ViewRibbon > Arrange All"),
    "WS":  .pressAX("ViewRibbon > Split"),
    "WH":  .pressAX("ViewRibbon > Hide"),
    "WU1": .pressAX("ViewRibbon > Unhide"),
    "WB":  .pressAX("ViewRibbon > View Side by Side"),
    "WVS": .pressAX("ViewRibbon > Synchronous Scrolling"),
    "WT":  .pressAX("ViewRibbon > Reset Window Position"),

    // Macros popover (Alt + W + ZM -> PM, R2, U2)
    "WZMPM": .pressAX("MacrosPopover > View Macros"),
    "WZMV":  .pressAX("MacrosPopover > View Macros"),
    "WZMR2": .pressAX("MacrosPopover > Record Macro"),
    "WZMR":  .pressAX("MacrosPopover > Record Macro"),
    "WZMU2": .pressAX("MacrosPopover > Use Relative References"),
    "WZMU":  .pressAX("MacrosPopover > Use Relative References"),

    // =========================================================================
    // AUTOMATE TAB (Alt + U)
    // =========================================================================

    // --- 1. NEW SCRIPT (Alt + U + N) ---
    "UNC": .pressAX("New Script > Create in Code Editor"),
    "UNE": .pressAX("New Script > Create in Code Editor"),
    "UN1": .pressAX("New Script > Create in Code Editor"),
    "UNR": .pressAX("New Script > Create from Recording"),
    "UNF": .pressAX("New Script > Create from Recording"),
    "UN2": .pressAX("New Script > Create from Recording"),

    // --- 2. VIEW SCRIPTS (Alt + U + V) ---
    "UVR": .pressAX("View Scripts > Recent Scripts"),
    "UV1": .pressAX("View Scripts > Recent Scripts"),
    "UVW": .pressAX("View Scripts > Scripts from this Workbook"),
    "UVT": .pressAX("View Scripts > Scripts from this Workbook"),
    "UVB": .pressAX("View Scripts > Scripts from this Workbook"),
    "UV2": .pressAX("View Scripts > Scripts from this Workbook"),
    "UVS": .pressAX("View Scripts > Samples"),
    "UVA": .pressAX("View Scripts > Samples"),
    "UVM": .pressAX("View Scripts > Samples"),
    "UV3": .pressAX("View Scripts > Samples"),

    // --- OTHER AUTOMATE TAB CONTROLS ---
    "UT":  .pressAX("AutomateRibbon > Flow Templates"),
]

let targetApps: Set<String> = ["com.microsoft.Excel", "com.microsoft.Powerpoint"]

// MARK: - Accessibility Helpers

func attr(_ e: AXUIElement, _ name: String) -> CFTypeRef? {
    var v: CFTypeRef?
    AXUIElementCopyAttributeValue(e, name as CFString, &v)
    return v
}

func children(_ e: AXUIElement) -> [AXUIElement] { (attr(e, kAXChildrenAttribute) as? [AXUIElement]) ?? [] }
func title(_ e: AXUIElement) -> String { (attr(e, kAXTitleAttribute) as? String) ?? "" }
func role(_ e: AXUIElement) -> String { (attr(e, kAXRoleAttribute) as? String) ?? "" }
func subrole(_ e: AXUIElement) -> String { (attr(e, kAXSubroleAttribute) as? String) ?? "" }

func frameOf(_ e: AXUIElement) -> CGRect? {
    guard let pv = attr(e, kAXPositionAttribute), let sv = attr(e, kAXSizeAttribute) else { return nil }
    var p = CGPoint.zero, sz = CGSize.zero
    AXValueGetValue(pv as! AXValue, .cgPoint, &p)
    AXValueGetValue(sv as! AXValue, .cgSize, &sz)
    return CGRect(origin: p, size: sz)
}

func entries(_ e: AXUIElement) -> [AXUIElement] {
    children(e).flatMap { role($0) == "AXMenu" ? children($0) : [$0] }
}

func pressMenu(pid: pid_t, path: [String]) {
    let app = AXUIElementCreateApplication(pid)
    guard let raw = attr(app, kAXMenuBarAttribute) else { return }
    var cur = raw as! AXUIElement
    for (i, name) in path.enumerated() {
        let items = entries(cur)
        guard let next = items.first(where: { title($0) == name })
                ?? items.first(where: { title($0).lowercased().hasPrefix(name.lowercased()) })
                ?? items.first(where: { name == "Freeze Panes" && title($0).contains("Freeze") }) else {
            print("[AltKeys] Menu item '\(name)' not found. Available: \(items.map(title))")
            return
        }
        if i == path.count - 1 { AXUIElementPerformAction(next, kAXPressAction as CFString) }
        cur = next
    }
}

func activeStandardWindow(_ app: AXUIElement, _ wins: [AXUIElement]) -> AXUIElement? {
    for key in [kAXFocusedWindowAttribute, kAXMainWindowAttribute] {
        if let w = attr(app, key), CFGetTypeID(w) == AXUIElementGetTypeID() {
            let win = w as! AXUIElement
            if subrole(win) == "AXStandardWindow" { return win }
        }
    }
    if let mainStd = wins.first(where: { subrole($0) == "AXStandardWindow" && ((attr($0, kAXMainAttribute) as? NSNumber)?.boolValue == true) }) {
        return mainStd
    }
    return wins.first(where: { subrole($0) == "AXStandardWindow" }) ?? wins.first
}

func isPopupMenuWindow(_ w: AXUIElement) -> Bool {
    return role(w) == "AXWindow" && subrole(w) == "AXUnknown" && !title(w).isEmpty
}

func popupWindowMatches(_ winTitle: String, _ targetTitle: String) -> Bool {
    if winTitle.caseInsensitiveCompare(targetTitle) == .orderedSame { return true }
    // Prevent "Ungroup" from matching "Group", "Compatibility Version" from matching "Compatibility",
    // or "Focus Cell Color" from matching "Focus Cell"
    if targetTitle.caseInsensitiveCompare("Group") == .orderedSame && winTitle.localizedCaseInsensitiveContains("Ungroup") {
        return false
    }
    if targetTitle.caseInsensitiveCompare("Compatibility") == .orderedSame && winTitle.localizedCaseInsensitiveContains("Compatibility Version") {
        return false
    }
    if targetTitle.caseInsensitiveCompare("Focus Cell") == .orderedSame && winTitle.localizedCaseInsensitiveContains("Focus Cell Color") {
        return false
    }
    return winTitle.localizedCaseInsensitiveContains(targetTitle)
}

func hasShowPopover(_ e: AXUIElement, depth: Int = 0) -> Bool {
    if depth > 10 { return false }
    let r = role(e)
    if r == "AXSplitGroup" || r == "AXTable" || r == "AXLayoutArea" { return false }
    if r == "AXPopover" { return true }
    for c in children(e) {
        if hasShowPopover(c, depth: depth + 1) { return true }
    }
    return false
}

func closeShowPopovers(pid: pid_t) {
    let app = AXUIElementCreateApplication(pid)
    let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
    func cancelPopovers(_ e: AXUIElement, depth: Int = 0) {
        if depth > 10 { return }
        let r = role(e)
        if r == "AXSplitGroup" || r == "AXTable" || r == "AXLayoutArea" { return }
        if r == "AXPopover" {
            _ = AXUIElementPerformAction(e, kAXCancelAction as CFString)
            return
        }
        for c in children(e) { cancelPopovers(c, depth: depth + 1) }
    }
    for w in wins where subrole(w) == "AXStandardWindow" {
        cancelPopovers(w)
    }
}

func findRibbonPopover(_ e: AXUIElement, buttonTitle: String, depth: Int = 0) -> AXUIElement? {
    if depth > 10 { return nil }
    let r = role(e)
    if r == "AXSplitGroup" || r == "AXTable" || r == "AXToolbar" || r == "AXLayoutArea" { return nil }
    if (r == "AXMenuButton" || r == "AXPopUpButton") && title(e) == buttonTitle {
        return children(e).first(where: { role($0) == "AXPopover" })
    }
    for c in children(e) {
        if let found = findRibbonPopover(c, buttonTitle: buttonTitle, depth: depth + 1) { return found }
    }
    return nil
}

@discardableResult
func openRibbonPopover(pid: pid_t, buttonTitle: String, tab: String = "View") -> Bool {
    let app = AXUIElementCreateApplication(pid)
    let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
    guard let main = activeStandardWindow(app, wins) else { return false }
    commitCellEditIfNeeded(main)
    selectRibbonTab(pid: pid, name: tab)
    if findRibbonPopover(main, buttonTitle: buttonTitle) != nil { return true }
    var targetBtn: AXUIElement? = nil
    func findBtn(_ e: AXUIElement, depth: Int = 0) {
        if targetBtn != nil || depth > 10 { return }
        let r = role(e)
        if r == "AXSplitGroup" || r == "AXTable" || r == "AXToolbar" || r == "AXLayoutArea" { return }
        if (r == "AXMenuButton" || r == "AXPopUpButton") && title(e) == buttonTitle {
            targetBtn = e
            return
        }
        for c in children(e) { findBtn(c, depth: depth + 1) }
    }
    findBtn(main)
    guard let btn = targetBtn else { return false }
    if children(btn).contains(where: { role($0) == "AXPopover" }) { return true }
    if AXUIElementPerformAction(btn, "AXShowMenu" as CFString) != .success {
        _ = AXUIElementPerformAction(btn, kAXPressAction as CFString)
    }
    for _ in 0..<8 {
        usleep(25_000)
        if findRibbonPopover(main, buttonTitle: buttonTitle) != nil { return true }
    }
    return findRibbonPopover(main, buttonTitle: buttonTitle) != nil
}

@discardableResult
func openShowPopover(pid: pid_t) -> Bool {
    return openRibbonPopover(pid: pid, buttonTitle: "Show", tab: "View")
}

@discardableResult
func openMacrosPopover(pid: pid_t) -> Bool {
    return openRibbonPopover(pid: pid, buttonTitle: "Macros", tab: "View")
}

@discardableResult
func openFocusCellMenu(pid: pid_t) -> Bool {
    let app = AXUIElementCreateApplication(pid)
    let initialWins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
    if initialWins.contains(where: { isPopupMenuWindow($0) && popupWindowMatches(title($0), "Focus Cell") }) {
        return true
    }
    _ = openShowPopover(pid: pid)
    let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
    guard let main = activeStandardWindow(app, wins) else { return false }
    var fcBtn: AXUIElement? = nil
    func findFC(_ e: AXUIElement, depth: Int = 0) {
        if fcBtn != nil || depth > 12 { return }
        let r = role(e)
        if r == "AXSplitGroup" || r == "AXTable" || r == "AXToolbar" || r == "AXLayoutArea" { return }
        if (r == "AXMenuButton" || r == "AXPopUpButton") && title(e) == "Focus Cell" {
            fcBtn = e
            return
        }
        for c in children(e) { findFC(c, depth: depth + 1) }
    }
    findFC(main)
    guard let btn = fcBtn else { return false }
    if AXUIElementPerformAction(btn, "AXShowMenu" as CFString) != .success {
        _ = AXUIElementPerformAction(btn, kAXPressAction as CFString)
    }
    for _ in 0..<8 {
        usleep(25_000)
        let wNow = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
        if wNow.contains(where: { isPopupMenuWindow($0) && popupWindowMatches(title($0), "Focus Cell") }) {
            return true
        }
    }
    return false
}

func switchWindowBadgeKey(forIndex idx: Int, title t: String) -> String {
    if t.localizedCaseInsensitiveContains("More") && !t.first!.isNumber {
        return "M"
    }
    if idx >= 1 && idx <= 9 {
        return "\(idx)"
    } else if idx == 10 {
        return "0"
    } else {
        let extraKeys = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
        let offset = idx - 11
        if offset >= 0 && offset < extraKeys.count {
            return extraKeys[offset]
        }
        return "\(idx)"
    }
}

func getSwitchWindowsPopupItems(pid: pid_t) -> [(key: String, element: AXUIElement, frame: CGRect?)] {
    let app = AXUIElementCreateApplication(pid)
    let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
    var result: [(key: String, element: AXUIElement, frame: CGRect?)] = []
    for w in wins {
        if subrole(w) == "AXStandardWindow" { continue }
        if popupWindowMatches(title(w), "Switch Windows") {
            var idx = 0
            func walk(_ e: AXUIElement, depth: Int = 0) {
                if depth > 8 { return }
                if role(e) == "AXMenuButton" {
                    let t = title(e).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !t.isEmpty {
                        idx += 1
                        let digits = String(t.prefix(while: { $0.isNumber }))
                        let itemNum = Int(digits) ?? idx
                        let key = switchWindowBadgeKey(forIndex: itemNum, title: t)
                        result.append((key: key, element: e, frame: frameOf(e)))
                    }
                }
                for c in children(e) { walk(c, depth: depth + 1) }
            }
            walk(w)
            break
        }
    }
    return result
}

func validSwitchWindowsKeys(pid: pid_t) -> [String] {
    let popupItems = getSwitchWindowsPopupItems(pid: pid)
    if !popupItems.isEmpty {
        return popupItems.map { $0.key }
    }
    // Fallback if user typed the window number before Switch Windows finished opening on actionQueue:
    // match the exact count of currently open Excel workbook windows (AXStandardWindow)
    let app = AXUIElementCreateApplication(pid)
    let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
    let stdCount = wins.filter { role($0) == "AXWindow" && subrole($0) == "AXStandardWindow" }.count
    guard stdCount >= 1 else { return [] }
    return (1...stdCount).map { switchWindowBadgeKey(forIndex: $0, title: "\($0)") }
}

func collectSwitchWindowsBadges(pid: pid_t) -> [(String, CGRect)] {
    let items = getSwitchWindowsPopupItems(pid: pid)
    var hits: [(String, CGRect)] = []
    for item in items {
        if let f = item.frame, f.width > 0 && f.height > 0 {
            let w: CGFloat = item.key.count > 1 ? 22 : 16
            let badgeFrame = CGRect(x: f.minX + 8, y: f.midY - 8, width: w, height: 16)
            hits.append((item.key, badgeFrame))
        }
    }
    return hits
}

func switchExcelWindowByKey(pid: pid_t, key: String) {
    actionQueue.async {
        var items = getSwitchWindowsPopupItems(pid: pid)
        if items.isEmpty {
            _ = openRibbonMenu(pid: pid, name: "Switch Windows", tab: "View")
            for _ in 0..<8 {
                usleep(25_000)
                items = getSwitchWindowsPopupItems(pid: pid)
                if !items.isEmpty { break }
            }
        }
        if let match = items.first(where: { $0.key.caseInsensitiveCompare(key) == .orderedSame }) {
            _ = AXUIElementPerformAction(match.element, kAXPressAction as CFString)
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.08) {
                restoreGridFocus(pid: pid)
            }
        }
    }
}

func hasExcelKeyTips(_ wins: [AXUIElement]) -> Bool {
    return wins.contains { role($0) == "AXStaticText" }
}

@discardableResult
func commitCellEditIfNeeded(_ mainWin: AXUIElement) -> Bool {
    var enterBtn: AXUIElement? = nil
    var cancelBtn: AXUIElement? = nil
    var isBareEquals = false
    for c in children(mainWin) {
        let d = (attr(c, kAXDescriptionAttribute) as? String) ?? ""
        if d == "enter formula" {
            enterBtn = c
        } else if d == "cancel formula" {
            cancelBtn = c
        } else if role(c) == "AXTextArea" && d.hasPrefix("Formula Bar.") {
            let trimmed = d.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasSuffix(" =") {
                isBareEquals = true
            }
        }
    }
    if let enter = enterBtn, (attr(enter, kAXEnabledAttribute) as? Bool) == true {
        if isBareEquals, let cancel = cancelBtn {
            _ = AXUIElementPerformAction(cancel, kAXPressAction as CFString)
        } else {
            _ = AXUIElementPerformAction(enter, kAXPressAction as CFString)
        }
        usleep(60_000)
        return true
    }
    return false
}

func selectRibbonTab(pid: pid_t, name: String) {
    let app = AXUIElementCreateApplication(pid)
    let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
    guard let main = activeStandardWindow(app, wins) else { return }
    commitCellEditIfNeeded(main)
    var tabElem: AXUIElement? = nil
    func findTab(_ e: AXUIElement, depth: Int = 0) {
        if tabElem != nil || depth > 8 { return }
        let r = role(e)
        if r == "AXSplitGroup" || r == "AXTable" { return }
        if (r == "AXRadioButton" || r == "AXTabButton") && title(e) == name {
            tabElem = e
            return
        }
        for c in children(e) { findTab(c, depth: depth + 1) }
    }
    findTab(main)
    if let t = tabElem {
        let v = (attr(t, kAXValueAttribute) as? Int) ?? ((attr(t, kAXValueAttribute) as? String) == "1" ? 1 : 0)
        if v != 1 {
            AXUIElementPerformAction(t, kAXPressAction as CFString)
        }
    }
}

func pressAXNamedItem(pid: pid_t, name: String) -> Bool {
    var requiredWindowTitle: String? = nil
    var actualName = name
    if name.contains(" > ") {
        let parts = name.components(separatedBy: " > ")
        if parts.count == 2 {
            requiredWindowTitle = parts[0]
            actualName = parts[1]
        }
    }
    if requiredWindowTitle == "InsertRibbon" {
        selectRibbonTab(pid: pid, name: "Insert")
    } else if requiredWindowTitle == "DrawRibbon" {
        selectRibbonTab(pid: pid, name: "Draw")
    } else if requiredWindowTitle == "PageLayoutRibbon" {
        selectRibbonTab(pid: pid, name: "Page Layout")
    } else if requiredWindowTitle == "FormulasRibbon" {
        selectRibbonTab(pid: pid, name: "Formulas")
    } else if requiredWindowTitle == "DataRibbon" {
        selectRibbonTab(pid: pid, name: "Data")
    } else if requiredWindowTitle == "ReviewRibbon" {
        selectRibbonTab(pid: pid, name: "Review")
    } else if requiredWindowTitle == "ViewRibbon" {
        selectRibbonTab(pid: pid, name: "View")
    } else if requiredWindowTitle == "AutomateRibbon" {
        selectRibbonTab(pid: pid, name: "Automate")
    } else if requiredWindowTitle == "ShowPopover" {
        _ = openShowPopover(pid: pid)
    } else if requiredWindowTitle == "MacrosPopover" {
        _ = openMacrosPopover(pid: pid)
    }

    let app = AXUIElementCreateApplication(pid)
    // ONLY search AXWindows (never AXMenuBar to avoid triggering menu items like Format -> Conditional Formatting... which opens Manage Rules)
    let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
    var target: AXUIElement? = nil
    var disabledTarget: AXUIElement? = nil
    
    func searchWindow(_ e: AXUIElement, depth: Int = 0, skipTabs: Bool = false, allowFuzzy: Bool = false) {
        if target != nil || depth > 8 { return }
        let r = role(e)
        if r == "AXSplitGroup" || r == "AXTable" || r == "AXToolbar" { return } // Skip spreadsheet grid & QAT
        if skipTabs && (r == "AXRadioButton" || r == "AXTabButton") { return }
        if r != "AXWindow" && r != "AXGroup" {
            let t = title(e)
            let d = (attr(e, kAXDescriptionAttribute) as? String) ?? ""
            let tNorm = t.replacingOccurrences(of: "\u{2011}", with: "-").replacingOccurrences(of: "\u{2026}", with: "...")
            let dNorm = d.replacingOccurrences(of: "\u{2011}", with: "-").replacingOccurrences(of: "\u{2026}", with: "...")
            let dFirstLine = dNorm.components(separatedBy: "\n").first ?? dNorm
            let nameNorm = actualName.replacingOccurrences(of: "\u{2011}", with: "-").replacingOccurrences(of: "\u{2026}", with: "...")
            var matches = (t == actualName || d == actualName || tNorm == nameNorm || dNorm == nameNorm || dFirstLine == nameNorm ||
               (nameNorm.hasSuffix("...") && (t == actualName || d == actualName || tNorm == nameNorm || dNorm == nameNorm)) ||
               (t == actualName.replacingOccurrences(of: "...", with: "")) ||
               (d == actualName.replacingOccurrences(of: "...", with: "")) ||
               (tNorm == nameNorm.replacingOccurrences(of: "...", with: "")) ||
               (dNorm == nameNorm.replacingOccurrences(of: "...", with: "")))
            if !matches && allowFuzzy {
                if actualName == "Sort A to Z" {
                    matches = (t == "Sort Smallest to Largest" || t == "Sort Oldest to Newest" ||
                               d == "Sort Smallest to Largest" || d == "Sort Oldest to Newest")
                } else if actualName == "Sort Z to A" {
                    matches = (t == "Sort Largest to Smallest" || t == "Sort Newest to Oldest" ||
                               d == "Sort Largest to Smallest" || d == "Sort Newest to Oldest")
                } else if (actualName == "Clear Comments and Notes" && (t == "Clear Comments" || d == "Clear Comments" || t.contains("Comments") || d.contains("Comments"))) ||
                          (actualName == "Clear Comments" && (t == "Clear Comments and Notes" || d == "Clear Comments and Notes" || t.contains("Comments") || d.contains("Comments"))) {
                    matches = true
                } else if (actualName == "Clear Hyperlinks" || actualName == "Clear Formats" || actualName == "Clear Contents" || actualName == "Clear All") && !t.hasPrefix("Set ") && (t.contains(actualName.replacingOccurrences(of: "Clear ", with: "")) || d.contains(actualName.replacingOccurrences(of: "Clear ", with: ""))) {
                    matches = true
                } else if actualName == "Remove Hyperlinks" && (t.contains("Hyperlink") || d.contains("Hyperlink")) {
                    matches = true
                } else if actualName == "Lock Cell" && (t.contains("Lock") || d.contains("Lock")) {
                    matches = true
                } else if actualName == "Merge & Center" && ((t.contains("Merge") && t.contains("Center")) || (d.contains("Merge") && d.contains("Center"))) {
                    matches = true
                } else if actualName == "Merge Across" && (t.contains("Across") || d.contains("Across")) {
                    matches = true
                } else if actualName == "Merge Cells" && ((t.contains("Merge") && !t.contains("Across") && !t.contains("Center") && !t.contains("Unmerge")) || (d.contains("Merge") && !d.contains("Across") && !d.contains("Center") && !d.contains("Unmerge"))) {
                    matches = true
                } else if actualName == "Unmerge Cells" && (t.contains("Unmerge") || d.contains("Unmerge")) {
                    matches = true
                } else if actualName == "Center Across Selection" && (t.contains("Center Across") || d.contains("Center Across")) {
                    matches = true
                } else if actualName == "New Note" && (t == "Edit Note" || d == "Edit Note") {
                    matches = true
                } else if actualName == "Protect Sheet" && (t == "Unprotect Sheet" || d == "Unprotect Sheet") {
                    matches = true
                } else if actualName == "Freeze Panes" && (t == "Unfreeze Panes" || d == "Unfreeze Panes") {
                    matches = true
                } else if actualName == "Record Macro" && (t == "Stop Recording" || d == "Stop Recording") {
                    matches = true
                }
            }
            if matches {
                let enabled = (attr(e, kAXEnabledAttribute) as? Bool) ?? true
                if enabled {
                    target = e
                    return
                } else if disabledTarget == nil {
                    disabledTarget = e
                }
            }
        }
        for c in children(e) { searchWindow(c, depth: depth + 1, skipTabs: skipTabs, allowFuzzy: allowFuzzy) }
    }
    
    func searchTargetWindow(_ w: AXUIElement, skipTabs: Bool = false) {
        searchWindow(w, skipTabs: skipTabs, allowFuzzy: false)
        if target == nil {
            searchWindow(w, skipTabs: skipTabs, allowFuzzy: true)
        }
    }
    
    if requiredWindowTitle == "ShowPopover" || requiredWindowTitle == "MacrosPopover" {
        let btnTitle = (requiredWindowTitle == "MacrosPopover") ? "Macros" : "Show"
        if let active = activeStandardWindow(app, wins), let pop = findRibbonPopover(active, buttonTitle: btnTitle) {
            searchTargetWindow(pop)
        }
    } else if let reqWin = requiredWindowTitle, reqWin != "InsertRibbon" && reqWin != "DrawRibbon" && reqWin != "PageLayoutRibbon" && reqWin != "FormulasRibbon" && reqWin != "DataRibbon" && reqWin != "ReviewRibbon" && reqWin != "ViewRibbon" && reqWin != "AutomateRibbon" {
        let lookupWin: String
        switch reqWin {
        case "PageOrientation": lookupWin = "Orientation"
        case "FormulasAutoSum": lookupWin = "AutoSum"
        case "DataFromPicture": lookupWin = "From Picture"
        case "ReviewNotes": lookupWin = "Notes"
        case "MoreFnStatistical": lookupWin = "Statistical"
        case "MoreFnEngineering": lookupWin = "Engineering"
        case "MoreFnCube": lookupWin = "Cube"
        case "MoreFnInformation": lookupWin = "Information"
        case "MoreFnCompatibility": lookupWin = "Compatibility"
        case "MoreFnWeb": lookupWin = "Web"
        default: lookupWin = reqWin
        }
        // Scoped to a specific floating popup window title
        for w in wins {
            if role(w) == "AXWindow" && subrole(w) != "AXStandardWindow" && popupWindowMatches(title(w), lookupWin) {
                searchTargetWindow(w)
                if target != nil { break }
            }
        }
    } else if requiredWindowTitle == "InsertRibbon" || requiredWindowTitle == "DrawRibbon" || requiredWindowTitle == "PageLayoutRibbon" || requiredWindowTitle == "FormulasRibbon" || requiredWindowTitle == "DataRibbon" || requiredWindowTitle == "ReviewRibbon" || requiredWindowTitle == "ViewRibbon" || requiredWindowTitle == "AutomateRibbon" {
        if let active = activeStandardWindow(app, wins) {
            searchTargetWindow(active, skipTabs: true)
        }
    } else {
        // 1. Search floating popup menus first (Borders, Conditional Formatting, Highlight Cells Rules, etc.)
        for w in wins {
            if role(w) == "AXWindow" && subrole(w) != "AXStandardWindow" {
                searchTargetWindow(w)
                if target != nil { break }
            }
        }
        
        // 2. Search main window ribbon ONLY for direct ribbon controls (never for popup menu items)
        if target == nil && parentMenuForPopupItem(name) == nil {
            if let active = activeStandardWindow(app, wins) {
                searchTargetWindow(active, skipTabs: true)
            }
            if target == nil {
                for w in wins {
                    if subrole(w) == "AXStandardWindow" {
                        searchTargetWindow(w, skipTabs: true)
                        if target != nil { break }
                    }
                }
            }
        }
    }
    
    if let item = target {
        let res = AXUIElementPerformAction(item, kAXPressAction as CFString)
        if requiredWindowTitle?.hasSuffix("Ribbon") == true || requiredWindowTitle == "ShowPopover" || requiredWindowTitle == "MacrosPopover" {
            return true
        }
        return res == .success
    }
    if let disabledItem = disabledTarget {
        if parentMenuForPopupItem(name) != nil {
            _ = AXUIElementPerformAction(disabledItem, kAXPressAction as CFString)
            postKeyToPid(53, pid: pid)
            return true
        } else if requiredWindowTitle?.hasSuffix("Ribbon") == true {
            _ = AXUIElementPerformAction(disabledItem, kAXPressAction as CFString)
            return true
        }
    }
    return false
}

let insertTabMenus: Set<String> = [
    "Forms", "From Picture", "Pictures", "3D Models", "SmartArt", "Sparklines",
    "Shapes", "Screenshot", "Recommended Charts", "Column", "Line", "Pie",
    "Hierarchy", "Statistical", "X Y (Scatter)", "Waterfall", "Combo", "Maps",
    "WordArt", "Equation"
]

let drawTabMenus: Set<String> = [
    "Eraser", "Add"
]

let pageLayoutTabMenus: Set<String> = [
    "Themes", "Colors", "Fonts", "Margins", "PageOrientation", "Size", "Print Area", "Breaks"
]

let formulasTabMenus: Set<String> = [
    "FormulasAutoSum", "Recently Used", "Financial", "Logical", "Text",
    "Date & Time", "Lookup & Reference", "Math & Trig", "More Functions",
    "Define Name", "Use in Formula", "Remove Arrows", "Error Checking", "Calculation Options"
]

let dataTabMenus: Set<String> = [
    "Get Data (Power Query)", "DataFromPicture", "Refresh All",
    "Data Validation", "What-If Analysis", "Group", "Ungroup"
]

let reviewTabMenus: Set<String> = [
    "Check Accessibility", "ReviewNotes", "Restrict Permission", "Hide Ink"
]

let viewTabMenus: Set<String> = [
    "Show", "Freeze Panes", "Switch Windows", "Macros"
]

let automateTabMenus: Set<String> = [
    "New Script", "View Scripts"
]

func focusFirstGalleryItemIfNeeded(_ popupWin: AXUIElement, menuName: String) {
    guard menuName == "Themes" || menuName == "Format as Table" || menuName == "Cell Styles" || menuName == "Focus Cell Color" else { return }
    var firstRadio: AXUIElement? = nil
    func findRadio(_ e: AXUIElement, depth: Int = 0) {
        if firstRadio != nil || depth > 8 { return }
        if role(e) == "AXRadioButton" {
            firstRadio = e
            return
        }
        for c in children(e) { findRadio(c, depth: depth + 1) }
    }
    findRadio(popupWin)
    if let r = firstRadio {
        AXUIElementSetAttributeValue(r, kAXFocusedAttribute as CFString, kCFBooleanTrue)
    }
}

@discardableResult
func openRibbonMenu(pid: pid_t, name: String, tab: String? = nil) -> Bool {
    let requiredTab = tab ?? (insertTabMenus.contains(name) ? "Insert" : (drawTabMenus.contains(name) ? "Draw" : (pageLayoutTabMenus.contains(name) ? "Page Layout" : (formulasTabMenus.contains(name) ? "Formulas" : (dataTabMenus.contains(name) ? "Data" : (reviewTabMenus.contains(name) ? "Review" : (viewTabMenus.contains(name) ? "View" : (automateTabMenus.contains(name) ? "Automate" : "Home"))))))))
    let actualMenuName = (name == "PageOrientation") ? "Orientation" : ((name == "FormulasAutoSum") ? "AutoSum" : ((name == "DataFromPicture") ? "From Picture" : ((name == "ReviewNotes") ? "Notes" : name)))
    let app = AXUIElementCreateApplication(pid)
    let initialWins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
    if let main = activeStandardWindow(app, initialWins) {
        if commitCellEditIfNeeded(main) {
            if initialWins.contains(where: { isPopupMenuWindow($0) }) {
                postKeyToPid(53, pid: pid)
                usleep(40_000)
            }
        }
    }
    let winsAfterCommit = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
    if let existingPopup = winsAfterCommit.first(where: { isPopupMenuWindow($0) && popupWindowMatches(title($0), actualMenuName) }) {
        focusFirstGalleryItemIfNeeded(existingPopup, menuName: actualMenuName)
        return true
    }
    // Dismiss Excel native KeyTips before opening Insert/Draw/Page Layout/Formulas/Data/Review/View/Automate tab dropdowns so native KeyTips don't block popup interaction
    if (requiredTab == "Insert" || requiredTab == "Draw" || requiredTab == "Page Layout" || requiredTab == "Formulas" || requiredTab == "Data" || requiredTab == "Review" || requiredTab == "View" || requiredTab == "Automate") && hasExcelKeyTips(winsAfterCommit) {
        postKeyToPid(53, pid: pid)
        usleep(30_000)
    }
    
    for attempt in 0..<6 {
        let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
        if let existingPopup = wins.first(where: { isPopupMenuWindow($0) && popupWindowMatches(title($0), actualMenuName) }) {
            focusFirstGalleryItemIfNeeded(existingPopup, menuName: actualMenuName)
            return true
        }
        guard let main = activeStandardWindow(app, wins) else {
            usleep(30_000)
            continue
        }
        commitCellEditIfNeeded(main)
        selectRibbonTab(pid: pid, name: requiredTab)
        var target: AXUIElement? = nil
        let nameNorm = actualMenuName.replacingOccurrences(of: "\u{2011}", with: "-")
        func findMenuBtn(_ e: AXUIElement, depth: Int = 0) {
            if target != nil || depth > 10 { return }
            let r = role(e)
            if r == "AXSplitGroup" || r == "AXTable" || r == "AXToolbar" { return }
            if r == "AXMenuButton" || r == "AXPopUpButton" {
                let t = title(e)
                let d = (attr(e, kAXDescriptionAttribute) as? String) ?? ""
                let tNorm = t.replacingOccurrences(of: "\u{2011}", with: "-")
                if t == actualMenuName || d == actualMenuName || tNorm == nameNorm {
                    target = e
                    return
                }
            }
            for c in children(e) { findMenuBtn(c, depth: depth + 1) }
        }
        findMenuBtn(main)
        if target == nil {
            selectRibbonTab(pid: pid, name: requiredTab)
            usleep(40_000)
            findMenuBtn(main)
        }
        if let btn = target {
            if children(btn).contains(where: { role($0) == "AXPopover" }) {
                return true
            }
            if (attr(btn, kAXEnabledAttribute) as? Bool) != false {
                if AXUIElementPerformAction(btn, "AXShowMenu" as CFString) != .success {
                    _ = AXUIElementPerformAction(btn, kAXPressAction as CFString)
                }
                for _ in 0..<6 {
                    usleep(25_000)
                    if children(btn).contains(where: { role($0) == "AXPopover" }) {
                        return true
                    }
                    let wNow = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
                    if let openedPopup = wNow.first(where: { isPopupMenuWindow($0) }) {
                        focusFirstGalleryItemIfNeeded(openedPopup, menuName: actualMenuName)
                        return true
                    }
                }
            }
        }
        if attempt < 5 { usleep(30_000) }
    }
    return false
}

func focusRibbonControl(pid: pid_t, descPrefix: String) {
    let app = AXUIElementCreateApplication(pid)
    let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
    guard let mainWin = activeStandardWindow(app, wins) else { return }
    var target: AXUIElement? = nil
    func findTarget(_ e: AXUIElement, depth: Int = 0) {
        if target != nil || depth > 8 { return }
        let d = (attr(e, kAXDescriptionAttribute) as? String) ?? ""
        let r = role(e)
        if r == "AXComboBox" && d.hasPrefix(descPrefix) {
            target = e
            return
        }
        for c in children(e) { findTarget(c, depth: depth + 1) }
    }
    for _ in 0..<8 {
        findTarget(mainWin)
        if target != nil { break }
        usleep(25_000)
    }
    if let t = target {
        print("[AltKeys] Focused ribbon control: \(descPrefix)")
        AXUIElementSetAttributeValue(t, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        let val = (attr(t, kAXValueAttribute) as? String) ?? ""
        var range = CFRange(location: 0, length: val.utf16.count)
        if let valRange = AXValueCreate(.cfRange, &range) {
            AXUIElementSetAttributeValue(t, kAXSelectedTextRangeAttribute as CFString, valRange)
        }
    } else {
        print("[AltKeys] Failed to find ribbon control: \(descPrefix)")
    }
}

func pressFormatPainter(pid: pid_t) {
    let app = AXUIElementCreateApplication(pid)
    let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
    guard let mainWin = activeStandardWindow(app, wins) else { return }
    var target: AXUIElement? = nil
    func findPainter(_ e: AXUIElement, depth: Int = 0) {
        if target != nil || depth > 8 { return }
        if role(e) == "AXCheckBox" && title(e) == "Format" {
            target = e
            return
        }
        for c in children(e) { findPainter(c, depth: depth + 1) }
    }
    findPainter(mainWin)
    if let t = target {
        AXUIElementPerformAction(t, kAXPressAction as CFString)
    }
}

func postKeyToPid(_ vk: CGKeyCode, pid: pid_t, flags: CGEventFlags = []) {
    let down = CGEvent(keyboardEventSource: nil, virtualKey: vk, keyDown: true)
    down?.flags = flags
    let up = CGEvent(keyboardEventSource: nil, virtualKey: vk, keyDown: false)
    up?.flags = flags
    down?.postToPid(pid)
    usleep(15_000)
    up?.postToPid(pid)
}

func send(_ code: CGKeyCode, _ flags: CGEventFlags) {
    if let front = NSWorkspace.shared.frontmostApplication {
        postKeyToPid(code, pid: front.processIdentifier, flags: flags)
    } else {
        for down in [true, false] {
            let ev = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: down)
            ev?.flags = flags
            ev?.post(tap: .cghidEventTap)
        }
    }
}

func parentMenuForPopupItem(_ name: String) -> String? {
    if name.hasPrefix("Forms > ") { return "Forms" }
    if name.hasPrefix("From Picture > ") { return "From Picture" }
    if name.hasPrefix("Pictures > ") || name.hasPrefix("Place in Cell > ") || name.hasPrefix("Place over Cells > ") { return "Pictures" }
    if name.hasPrefix("3D Models > ") { return "3D Models" }
    if name.hasPrefix("SmartArt > ") { return "SmartArt" }
    if name.hasPrefix("Sparklines > ") { return "Sparklines" }
    if name.hasPrefix("Eraser > ") { return "Eraser" }
    if name.hasPrefix("Add > ") { return "Add" }
    if name.hasPrefix("Themes > ") { return "Themes" }
    if name.hasPrefix("Margins > ") { return "Margins" }
    if name.hasPrefix("PageOrientation > ") { return "PageOrientation" }
    if name.hasPrefix("Print Area > ") { return "Print Area" }
    if name.hasPrefix("Breaks > ") { return "Breaks" }
    if name.hasPrefix("FormulasAutoSum > ") { return "FormulasAutoSum" }
    if name.hasPrefix("Recently Used > ") { return "Recently Used" }
    if name.hasPrefix("Financial > ") { return "Financial" }
    if name.hasPrefix("Logical > ") { return "Logical" }
    if name.hasPrefix("Text > ") { return "Text" }
    if name.hasPrefix("Date & Time > ") { return "Date & Time" }
    if name.hasPrefix("Lookup & Reference > ") { return "Lookup & Reference" }
    if name.hasPrefix("Math & Trig > ") { return "Math & Trig" }
    if name.hasPrefix("More Functions > ") ||
       name.hasPrefix("MoreFnStatistical > ") ||
       name.hasPrefix("MoreFnEngineering > ") ||
       name.hasPrefix("MoreFnCube > ") ||
       name.hasPrefix("MoreFnInformation > ") ||
       name.hasPrefix("MoreFnCompatibility > ") ||
       name.hasPrefix("MoreFnWeb > ") {
        return "More Functions"
    }
    if name.hasPrefix("Define Name > ") { return "Define Name" }
    if name.hasPrefix("Remove Arrows > ") { return "Remove Arrows" }
    if name.hasPrefix("Error Checking > ") { return "Error Checking" }
    if name.hasPrefix("Calculation Options > ") || name.hasPrefix("Compatibility Version > ") { return "Calculation Options" }
    if name.hasPrefix("Get Data (Power Query) > ") { return "Get Data (Power Query)" }
    if name.hasPrefix("DataFromPicture > ") { return "DataFromPicture" }
    if name.hasPrefix("Refresh All > ") { return "Refresh All" }
    if name.hasPrefix("Data Validation > ") { return "Data Validation" }
    if name.hasPrefix("What-If Analysis > ") { return "What-If Analysis" }
    if name.hasPrefix("Group > ") { return "Group" }
    if name.hasPrefix("Ungroup > ") { return "Ungroup" }
    if name.hasPrefix("Check Accessibility > ") { return "Check Accessibility" }
    if name.hasPrefix("ReviewNotes > ") { return "ReviewNotes" }
    if name.hasPrefix("Restrict Permission > ") { return "Restrict Permission" }
    if name.hasPrefix("Hide Ink > ") { return "Hide Ink" }
    if name.hasPrefix("Focus Cell > ") { return "Focus Cell" }
    if name.hasPrefix("Freeze Panes > ") { return "Freeze Panes" }
    if name.hasPrefix("New Script > ") { return "New Script" }
    if name.hasPrefix("View Scripts > ") { return "View Scripts" }
    switch name {
    case "Highlight Cells Rules", "Top/Bottom Rules", "Data Bars", "Color Scales", "Icon Sets",
         "New Rule...", "Clear Rules", "Manage Rules...",
         "Greater Than...", "Less Than...", "Between...", "Equal To...",
         "Text that Contains...", "A Date Occurring...", "Duplicate Values...",
         "Top 10 Items...", "Top 10 %...", "Top 10%...", "Bottom 10 Items...", "Bottom 10 %...", "Bottom 10%...",
         "Above Average...", "Below Average...", "More Rules...",
         "Clear Rules from Selected Cells", "Clear Rules from Entire Sheet", "Clear Rules from This Table",
         "Clear Rules from This PivotTable":
        return "Conditional Formatting"
    case "Bottom Border", "Top Border", "Left Border", "Right Border", "No Border",
         "All Borders", "Outside Borders", "Thick Box Border", "Bottom Double Border",
         "Thick Bottom Border", "Top and Bottom Border", "Top and Thick Bottom Border",
         "Top and Double Bottom Border", "Draw Border", "Draw Border Grid", "Erase Border",
         "Line Color", "Line Style", "More Borders...":
        return "Borders"
    case "Merge & Center", "Merge Across", "Merge Cells", "Unmerge Cells", "Center Across Selection":
        return "Merge & Center"
    case "Find...", "Replace...", "Go To...", "Go To Special...", "Formulas", "Notes",
         "Conditional Formatting", "Constants", "Data Validation", "Select Objects", "Selection Pane...":
        return "Find & Select"
    case "Sum", "Average", "Count Numbers", "Max", "Min", "More Functions...":
        return "AutoSum"
    case "Wrap Text", "Shrink Text to Fit":
        return "Wrap Text"
    case "Sort A to Z", "Sort Z to A", "Sort Smallest to Largest", "Sort Largest to Smallest",
         "Sort Oldest to Newest", "Sort Newest to Oldest", "Custom Sort...", "Filter", "Clear", "Reapply":
        return "Sort & Filter"
    case "Row Height...", "AutoFit Row Height", "Column Width...", "AutoFit Column Width", "Default Width...",
         "Hide & Unhide", "Rename Sheet", "Move or Copy Sheet...", "Tab Color", "Protect Sheet...", "Lock Cell", "Format Cells...",
         "Hide Rows", "Hide Columns", "Hide Sheet", "Unhide Rows", "Unhide Columns", "Unhide Sheet...":
        return "Format"
    case "Clear All", "Clear Formats", "Clear Contents", "Clear Comments and Notes", "Clear Comments", "Clear Hyperlinks", "Remove Hyperlinks":
        return "Clear"
    case "Angle Counterclockwise", "Angle Clockwise", "Vertical Text", "Rotate Text Up", "Rotate Text Down", "Format Cell Alignment":
        return "Orientation"
    default:
        return nil
    }
}

let actionQueue = DispatchQueue(label: "com.altkeys.actionQueue", qos: .userInteractive)

func run(_ action: Action, pid: pid_t) {
    actionQueue.async {
        var shouldRestoreGrid = true
        switch action {
        case .pressAX(let name):
            let noRestoreItems = [
                "Sum", "Average", "Count Numbers", "Max", "Min", "More Functions...",
                "Draw Border", "Draw Border Grid", "Erase Border",
                "Line Color", "Line Style", "More Borders...",
                "Manage Rules...", "New Rule...",
                "Greater Than...", "Less Than...", "Between...", "Equal To...",
                "Text that Contains...", "A Date Occurring...", "Duplicate Values...",
                "Top 10 Items...", "Top 10 %...", "Top 10%...", "Bottom 10 Items...", "Bottom 10 %...", "Bottom 10%...",
                "Above Average...", "Below Average...", "More Rules...",
                "Data Bars", "Color Scales", "Icon Sets",
                "Custom Sort...", "Rename Sheet", "Tab Color", "Move or Copy Sheet...",
                "Row Height...", "Column Width...", "Default Width...", "Protect Sheet...",
                "Format Cells...", "Hide & Unhide", "Unhide Sheet...",
                "Lock Cell",
                "Clear All", "Clear Formats", "Clear Contents", "Clear Comments and Notes", "Clear Comments", "Clear Hyperlinks", "Remove Hyperlinks",
                "Merge & Center", "Merge Across", "Merge Cells", "Unmerge Cells", "Center Across Selection"
            ]
            if noRestoreItems.contains(name) ||
               name.hasPrefix("Forms > ") ||
               name.hasPrefix("From Picture > ") ||
               name.hasPrefix("Pictures > ") ||
               name.hasPrefix("Place in Cell > ") ||
               name.hasPrefix("Place over Cells > ") ||
               name.hasPrefix("3D Models > ") ||
               name.hasPrefix("SmartArt > ") ||
               name.hasPrefix("Sparklines > ") ||
               name.hasPrefix("InsertRibbon > ") ||
               name.hasPrefix("Eraser > ") ||
               name.hasPrefix("Add > ") ||
               name.hasPrefix("DrawRibbon > ") ||
               name.hasPrefix("Themes > ") ||
               name == "Margins > Custom Margins..." ||
               name.hasPrefix("PageLayoutRibbon > ") ||
               name.hasPrefix("FormulasAutoSum > ") ||
               name.contains("Insert Function") ||
               name.hasPrefix("Define Name > ") ||
               name.hasPrefix("Error Checking > ") ||
               name == "Compatibility Version > Learn More" ||
               name.hasPrefix("FormulasRibbon > ") ||
               name.hasPrefix("Get Data (Power Query) > ") ||
               name.hasPrefix("DataFromPicture > ") ||
               name == "Refresh All > Properties" ||
               name == "Refresh All > Refresh Status" ||
               name == "Data Validation > Data Validation..." ||
               name.hasPrefix("What-If Analysis > ") ||
               name == "Group > Group..." ||
               name == "Ungroup > Ungroup..." ||
               name.hasPrefix("DataRibbon > ") ||
               name.hasPrefix("Check Accessibility > ") ||
               name == "ReviewNotes > New Note" ||
               name == "ReviewNotes > Convert to Comments" ||
               name == "Restrict Permission > Restricted Access..." ||
               name.hasPrefix("ReviewRibbon > ") ||
               name == "Focus Cell > Focus Cell Color" ||
               name == "ShowPopover > Navigation" ||
               name == "MacrosPopover > View Macros" ||
               name == "MacrosPopover > Record Macro" ||
               name.hasPrefix("ViewRibbon > ") ||
               name.hasPrefix("New Script > ") ||
               name.hasPrefix("View Scripts > ") ||
               name.hasPrefix("AutomateRibbon > ") {
                shouldRestoreGrid = false
            }
            let app = AXUIElementCreateApplication(pid)
            if let parent = parentMenuForPopupItem(name) {
                // For items inside popup menus, NEVER send Escape (53).
                // Ensure parent dropdown is open before searching (ignore AXStaticText KeyTip elements!).
                let expectedWinTitle = (parent == "PageOrientation") ? "Orientation" : ((parent == "FormulasAutoSum") ? "AutoSum" : ((parent == "DataFromPicture") ? "From Picture" : ((parent == "ReviewNotes") ? "Notes" : parent)))
                let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
                let hasPopup = wins.contains { isPopupMenuWindow($0) && popupWindowMatches(title($0), expectedWinTitle) }
                if !hasPopup {
                    if parent == "Focus Cell" {
                        openFocusCellMenu(pid: pid)
                    } else {
                        openRibbonMenu(pid: pid, name: parent)
                    }
                    usleep(120_000)
                }
                let winsAfter = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
                if ["Greater Than...", "Less Than...", "Between...", "Equal To...", "Text that Contains...", "A Date Occurring...", "Duplicate Values..."].contains(name) {
                    if !winsAfter.contains(where: { title($0) == "Highlight Cells Rules" }) {
                        _ = pressAXNamedItem(pid: pid, name: "Highlight Cells Rules")
                        usleep(120_000)
                    }
                } else if ["Top 10 Items...", "Top 10 %...", "Top 10%...", "Bottom 10 Items...", "Bottom 10 %...", "Bottom 10%...", "Above Average...", "Below Average..."].contains(name) {
                    if !winsAfter.contains(where: { title($0) == "Top/Bottom Rules" }) {
                        _ = pressAXNamedItem(pid: pid, name: "Top/Bottom Rules")
                        usleep(120_000)
                    }
                } else if ["Clear Rules from Selected Cells", "Clear Rules from Entire Sheet", "Clear Rules from This Table", "Clear Rules from This PivotTable"].contains(name) {
                    if !winsAfter.contains(where: { title($0) == "Clear Rules" }) {
                        _ = pressAXNamedItem(pid: pid, name: "Clear Rules")
                        usleep(120_000)
                    }
                } else if ["Hide Rows", "Hide Columns", "Hide Sheet", "Unhide Rows", "Unhide Columns", "Unhide Sheet..."].contains(name) {
                    if !winsAfter.contains(where: { title($0) == "Hide & Unhide" }) {
                        _ = pressAXNamedItem(pid: pid, name: "Hide & Unhide")
                        usleep(120_000)
                    }
                } else if name.hasPrefix("Place in Cell > ") {
                    if !winsAfter.contains(where: { title($0) == "Place in Cell" }) {
                        _ = pressAXNamedItem(pid: pid, name: "Pictures > Place in Cell")
                        usleep(120_000)
                    }
                } else if name.hasPrefix("Place over Cells > ") {
                    if !winsAfter.contains(where: { title($0) == "Place over Cells" }) {
                        _ = pressAXNamedItem(pid: pid, name: "Pictures > Place over Cells")
                        usleep(120_000)
                    }
                } else if name.hasPrefix("MoreFnStatistical > ") {
                    if !winsAfter.contains(where: { title($0) == "Statistical" }) {
                        _ = pressAXNamedItem(pid: pid, name: "More Functions > Statistical")
                        usleep(120_000)
                    }
                } else if name.hasPrefix("MoreFnEngineering > ") {
                    if !winsAfter.contains(where: { title($0) == "Engineering" }) {
                        _ = pressAXNamedItem(pid: pid, name: "More Functions > Engineering")
                        usleep(120_000)
                    }
                } else if name.hasPrefix("MoreFnCube > ") {
                    if !winsAfter.contains(where: { title($0) == "Cube" }) {
                        _ = pressAXNamedItem(pid: pid, name: "More Functions > Cube")
                        usleep(120_000)
                    }
                } else if name.hasPrefix("MoreFnInformation > ") {
                    if !winsAfter.contains(where: { title($0) == "Information" }) {
                        _ = pressAXNamedItem(pid: pid, name: "More Functions > Information")
                        usleep(120_000)
                    }
                } else if name.hasPrefix("MoreFnCompatibility > ") {
                    if !winsAfter.contains(where: { title($0) == "Compatibility" }) {
                        _ = pressAXNamedItem(pid: pid, name: "More Functions > Compatibility")
                        usleep(120_000)
                    }
                } else if name.hasPrefix("MoreFnWeb > ") {
                    if !winsAfter.contains(where: { title($0) == "Web" }) {
                        _ = pressAXNamedItem(pid: pid, name: "More Functions > Web")
                        usleep(120_000)
                    }
                } else if name.hasPrefix("Compatibility Version > ") {
                    if !winsAfter.contains(where: { title($0) == "Compatibility Version" }) {
                        _ = pressAXNamedItem(pid: pid, name: "Calculation Options > Compatibility Version")
                        usleep(120_000)
                    }
                }
            } else if !name.hasPrefix("ShowPopover > ") && !name.hasPrefix("MacrosPopover > ") {
                let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
                let hasPopupMenu = wins.contains { isPopupMenuWindow($0) }
                if !hasPopupMenu && hasExcelKeyTips(wins) {
                    // Dismiss Excel KeyTips before clicking direct ribbon buttons (e.g. Increase/Decrease Font Size, Wrap Text)
                    postKeyToPid(53, pid: pid); usleep(30_000)
                }
            }
            var success = false
            for attempt in 0..<20 {
                if attempt == 4, let parent = parentMenuForPopupItem(name) {
                    if parent == "Focus Cell" {
                        openFocusCellMenu(pid: pid)
                    } else {
                        openRibbonMenu(pid: pid, name: parent)
                    }
                    usleep(60_000)
                }
                if pressAXNamedItem(pid: pid, name: name) {
                    success = true
                    break
                }
                usleep(30_000)
            }
            if !success {
                print("[AltKeys] Failed to press AX item: \(name)")
            }
            if name == "Focus Cell > Focus Cell Color" {
                usleep(80_000)
                let wColor = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
                if let colorWin = wColor.first(where: { isPopupMenuWindow($0) && title($0) == "Focus Cell Color" }) {
                    focusFirstGalleryItemIfNeeded(colorWin, menuName: "Focus Cell Color")
                }
            } else if name.hasPrefix("Focus Cell > ") || name.hasPrefix("ShowPopover > ") || name.hasPrefix("MacrosPopover > ") {
                usleep(40_000)
                if name != "MacrosPopover > View Macros" && name != "MacrosPopover > Record Macro" {
                    let wNow = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
                    if hasExcelKeyTips(wNow) {
                        postKeyToPid(53, pid: pid)
                        usleep(30_000)
                    }
                }
                closeShowPopovers(pid: pid)
            }
            let popupItemsToDismiss = [
                "Bottom Border", "Top Border", "Left Border", "Right Border", "No Border",
                "All Borders", "Outside Borders", "Thick Box Border", "Bottom Double Border",
                "Thick Bottom Border", "Top and Bottom Border", "Top and Thick Bottom Border",
                "Top and Double Bottom Border",
                "Lock Cell",
                "Clear All", "Clear Formats", "Clear Contents",
                "Clear Comments and Notes", "Clear Comments", "Clear Hyperlinks", "Remove Hyperlinks",
                "Merge & Center", "Merge Across", "Merge Cells", "Unmerge Cells", "Center Across Selection"
            ]
            if popupItemsToDismiss.contains(name) {
                usleep(40_000)
                let winsAfter = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
                let popupStillOpen = winsAfter.contains { isPopupMenuWindow($0) }
                if popupStillOpen {
                    postKeyToPid(53, pid: pid)
                    usleep(30_000)
                }
            }
        case .menu(let path):
            let app = AXUIElementCreateApplication(pid)
            let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
            if hasExcelKeyTips(wins) {
                postKeyToPid(53, pid: pid); usleep(30_000)
            }
            usleep(30_000)
            pressMenu(pid: pid, path: path)
        case .keys(let list):
            let app = AXUIElementCreateApplication(pid)
            let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
            if hasExcelKeyTips(wins) {
                postKeyToPid(53, pid: pid); usleep(30_000)
            }
            usleep(30_000)
            for (code, flags) in list { send(code, flags); usleep(120_000) }
        case .focusRibbon(let descPrefix):
            let app = AXUIElementCreateApplication(pid)
            let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
            if hasExcelKeyTips(wins) {
                postKeyToPid(53, pid: pid); usleep(30_000)
            }
            usleep(30_000)
            focusRibbonControl(pid: pid, descPrefix: descPrefix)
            return
        case .custom(let fn):
            let app = AXUIElementCreateApplication(pid)
            let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
            if hasExcelKeyTips(wins) {
                postKeyToPid(53, pid: pid); usleep(30_000)
            }
            usleep(30_000)
            fn(pid)
        }
        if shouldRestoreGrid {
            usleep(60_000)
            restoreGridFocus(pid: pid)
        }
    }
}

// MARK: - Grid Focus Restoration

let ribbonRoles: Set<String> = ["AXButton", "AXMenuButton", "AXPopUpButton", "AXRadioButton",
                                "AXCheckBox", "AXToolbar", "AXTabGroup", "AXComboBox", "AXMenuItem"]

func focusedRole(_ app: AXUIElement) -> String {
    guard let f = attr(app, kAXFocusedUIElementAttribute) else { return "none" }
    return role(f as! AXUIElement)
}

func findContentArea(_ e: AXUIElement, depth: Int = 0) -> AXUIElement? {
    if depth > 6 { return nil }
    let r = role(e)
    if r == "AXLayoutArea" { return e }
    for c in children(e) {
        if let found = findContentArea(c, depth: depth + 1) { return found }
    }
    return nil
}

func findFormulaBar(_ e: AXUIElement, depth: Int = 0) -> AXUIElement? {
    if depth > 8 { return nil }
    if role(e) == "AXTextArea" { return e }
    for c in children(e) {
        if let fb = findFormulaBar(c, depth: depth + 1) { return fb }
    }
    return nil
}

func restoreGridFocus(pid: pid_t, force: Bool = false) {
    let app = AXUIElementCreateApplication(pid)
    let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
    
    // If a floating dropdown/gallery popup is open and this isn't a forced Escape restore, do not steal focus!
    if !force && wins.contains(where: { isPopupMenuWindow($0) }) {
        return
    }
    
    // NEVER steal focus if any modal dialog or sheet is open (e.g. Format Cells, Conditional Formatting Rules, Find, Sparklines, etc.)
    for w in wins {
        let sr = subrole(w)
        if sr == "AXUnknown" || role(w) != "AXWindow" { continue } // Ignore floating dropdown menus & KeyTip labels
        let t = title(w)
        if sr == "AXDialog" || sr == "AXSystemDialog" || children(w).contains(where: { role($0) == "AXSheet" }) || t.contains("Rule") || t.contains("Values") || t.contains("Formatting") || t.contains("Manage") || t.contains("Format Cells") || t.contains("Paste Special") || t.contains("Find") || t.contains("Replace") || t.contains("Go To") || t.contains("Border") || t.contains("Formula") || t.contains("Function") || t.contains("Sort") || t.contains("Height") || t.contains("Width") || t.contains("Move or Copy") || t.contains("Protect") || t.contains("Sparklines") || t.contains("Table") || t.contains("Pivot") || t.contains("Link") || t.contains("Object") || t.contains("Picture") || t.contains("Validation") || t.contains("Scenario") || t.contains("Goal Seek") || t.contains("Group") || t.contains("Ungroup") || t.contains("Query") || t.contains("Source") || t.contains("Columns") || t.contains("Duplicates") || t.contains("Consolidate") || t.contains("Subtotal") || t.contains("Solver") || t.contains("Spelling") || t.contains("Statistics") || t.contains("Permission") || t.contains("Access") || t.contains("Password") || t.contains("Custom Views") || t.contains("Arrange") || t.contains("Unhide") || t.contains("Macro") {
            return
        }
    }
    
    // Check current focused role
    if let curFocus = attr(app, kAXFocusedUIElementAttribute) {
        let fe = curFocus as! AXUIElement
        let r = role(fe)
        // If already focused on Content Area (cell grid), nothing to do!
        if r == "AXLayoutArea" { return }
        let d = ((attr(fe, kAXDescriptionAttribute) as? String) ?? "") + title(fe)
        if !force && r == "AXTextArea" && (d.localizedCaseInsensitiveContains("formula") || d.localizedCaseInsensitiveContains("edit") || d.isEmpty) {
            return
        }
    }
    
    guard let mainWin = activeStandardWindow(app, wins) else { return }
    
    // Primary: Direct native focus on spreadsheet Content Area (AXLayoutArea) — zero side effects, never triggers Formula Bar edit mode!
    if let ca = findContentArea(mainWin) {
        AXUIElementSetAttributeValue(ca, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        usleep(15_000)
        if let cur = attr(app, kAXFocusedUIElementAttribute), role(cur as! AXUIElement) == "AXLayoutArea" {
            return
        }
    }
    
    // Fallback: Silent formula bar + Escape restore only if direct Content Area focus did not succeed
    if let bar = findFormulaBar(mainWin) {
        let res = AXUIElementSetAttributeValue(bar, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        if res == .success {
            usleep(20_000)
            postKeyToPid(53, pid: pid)
            usleep(20_000)
        }
    }
}

// MARK: - State Machine

var optionDown = false
var otherKeyUsed = false
var armed = false
var buffer = ""
var armedAt = Date()
var statusItem: NSStatusItem!
var tap: CFMachPort!
var baselineWindows = 0

func excelWindowCount(_ pid: pid_t) -> Int {
    let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
    return list.filter { ($0[kCGWindowOwnerPID as String] as? Int32) == pid }.count
}

// MARK: - Windows-style Badges on Excel Ribbon & Menus

var badgeWindows: [NSPanel] = []
var currentDrawnBuffer: String = ""
var currentMenuRect: CGRect = .zero

let tabKeyTips: [String: String] = [
    "Home": "H",
    "Insert": "N",
    "Draw": "JI",
    "Page Layout": "P",
    "Formulas": "M",
    "Data": "A",
    "Review": "R",
    "View": "W",
    "Automate": "U",
]

let homeRibbonKeyTips: [String: String] = [
    "Conditional Formatting": "L",
    "Format as Table": "T",
    "Cell Styles": "J",
    "Insert": "I",
    "Delete": "D",
    "Format": "O",
    "Paste": "V",
    "Copy": "C",
    "Cut": "X",
    "Bold": "1",
    "Italic": "2",
    "Underline": "3",
    "Borders": "B",
    "Shading": "H",
    "Font Color": "FC",
    "Increase Font Size": "FG",
    "Decrease Font Size": "FK",
    "Orientation": "FQ",
    "Wrap Text": "W",
    "Merge & Center": "M",
    "AutoSum": "U",
    "Sort & Filter": "S",
    "Clear": "E",
    "Find & Select": "FD",
    "Fill": "FI",
    "Accounting Number Format": "AN",
    "Percent Style": "P",
    "Comma Style": "K",
    "Increase Decimal": "0",
    "Decrease Decimal": "9",
    "Top Align": "AT",
    "Middle Align": "AM",
    "Bottom Align": "AB",
    "Align Left": "AL",
    "Center": "AC",
    "Align Right": "AR",
    "Decrease Indent": "5",
    "Increase Indent": "6",
    "Add-ins": "AS",
    "Add\u{2011}ins": "AS",
]

let insertRibbonKeyTips: [String: String] = [
    "PivotTable": "V",
    "Recommended PivotTables": "Y1",
    "Table": "T",
    "Forms": "FR",
    "From Picture": "F1",
    "Pictures": "P1",
    "Shapes": "SH",
    "Icons": "Y2",
    "3D Models": "S3",
    "SmartArt": "M",
    "Screenshot": "SC",
    "Checkbox": "C1",
    "Recommended Charts": "R",
    "Column": "C2",
    "Line": "N",
    "Pie": "Q",
    "Hierarchy": "HI",
    "Statistical": "SA",
    "X Y (Scatter)": "D",
    "Waterfall": "Y3",
    "Combo": "SD",
    "Maps": "Y4",
    "PivotChart": "PC",
    "Sparklines": "Y5",
    "Slicer": "SF",
    "Timeline": "ST",
    "Link": "I",
    "New Comment": "C3",
    "Text Box": "X",
    "Header & Footer": "H1",
    "WordArt": "W",
    "Object": "J",
    "Equation": "E",
    "Symbol": "Y6",
]

let drawRibbonKeyTips: [String: String] = [
    "Draw": "D",
    "Eraser": "E",
    "Lasso Select": "L",
    "Add": "A",
    "Draw with\nTrackpad": "Y",
    "Draw with Trackpad": "Y",
]

// Accessibility title-to-badge mappings for Home, Insert & Draw Tab Popup Menus
let axTitleBadges: [String: String] = [
    // Main Conditional Formatting Menu
    "Highlight Cells Rules": "H",
    "Top/Bottom Rules": "T",
    "Data Bars": "D",
    "Color Scales": "S",
    "Icon Sets": "I",
    "New Rule...": "N",
    "Clear Rules": "C",
    "Manage Rules...": "R",
    
    // Highlight Cells Rules Submenu
    "Greater Than...": "G",
    "Less Than...": "L",
    "Between...": "B",
    "Equal To...": "E",
    "Text that Contains...": "T",
    "A Date Occurring...": "A",
    "Duplicate Values...": "D",
    "More Rules...": "M",
    
    // Top/Bottom Rules Submenu
    "Top 10 Items...": "T",
    "Top 10 %...": "P",
    "Top 10%...": "P",
    "Bottom 10 Items...": "B",
    "Bottom 10 %...": "O",
    "Bottom 10%...": "O",
    "Above Average...": "A",
    "Below Average...": "U",
    
    // Clear Rules Submenu
    "Clear Rules from Selected Cells": "S",
    "Clear Rules from Entire Sheet": "E",
    "Clear Rules from This Table": "T",
    
    // Borders Menu (HB)
    "Bottom Border": "O",
    "Top Border": "P",
    "Left Border": "L",
    "Right Border": "R",
    "No Border": "N",
    "All Borders": "A",
    "Outside Borders": "S",
    "Thick Box Border": "T",
    "Bottom Double Border": "B",
    "Thick Bottom Border": "H",
    "Top and Bottom Border": "D",
    "Top and Thick Bottom Border": "C",
    "Top and Double Bottom Border": "U",
    "Draw Border": "W",
    "Draw Border Grid": "G",
    "Erase Border": "E",
    "Line Color": "I",
    "Line Style": "Y",
    "More Borders...": "M",
    
    // Shading / Fill Color Menu (HH)
    "No Fill": "N",
    "More Colors...": "M",
    
    // Font Color Menu (HFC)
    "Automatic": "A",
    
    // Merge & Center Menu (HM)
    "Merge & Center": "C",
    "Merge Across": "A",
    "Merge Cells": "M",
    "Unmerge Cells": "U",
    "Center Across Selection": "S",
    
    // AutoSum Menu (HU)
    "Sum": "S",
    "Average": "A",
    "Count Numbers": "C",
    "Max": "M",
    "Min": "I",
    "More Functions...": "F",
    
    // Format Menu (HO)
    "Row Height...": "H",
    "AutoFit Row Height": "A",
    "Column Width...": "W",
    "AutoFit Column Width": "I",
    "Default Width...": "D",
    "Hide & Unhide": "U",
    "Rename Sheet": "R",
    "Move or Copy Sheet...": "M",
    "Tab Color": "T",
    "Protect Sheet...": "P",
    "Lock Cell": "L",
    "Format Cells...": "E",

    // Hide & Unhide Submenu (HOU)
    "Hide Rows": "R",
    "Hide Columns": "C",
    "Hide Sheet": "S",
    "Unhide Rows": "O",
    "Unhide Columns": "L",
    "Unhide Sheet...": "H",

    // Sort & Filter Menu (HS)
    "Sort A to Z": "S",
    "Sort Smallest to Largest": "S",
    "Sort Oldest to Newest": "S",
    "Sort Z to A": "O",
    "Sort Largest to Smallest": "O",
    "Sort Newest to Oldest": "O",
    "Custom Sort...": "U",
    "Filter": "T",
    "Clear": "C",
    "Reapply": "A",
    
    // Clear Menu (HE)
    "Clear All": "A",
    "Clear Formats": "F",
    "Clear Contents": "C",
    "Clear Comments and Notes": "M",
    "Clear Comments": "M",
    "Clear Hyperlinks": "L",
    "Remove Hyperlinks": "R",
    
    // Find & Select Menu (HFD)
    "Find...": "F",
    "Replace...": "R",
    "Go To...": "G",
    "Go To Special...": "S",
    "Formulas": "U",
    "Notes": "N",
    "Conditional Formatting": "C",
    "Constants": "O",
    "Data Validation": "V",
    "Select Objects": "B",
    "Selection Pane...": "P",
    
    // Orientation Menu (HFQ)
    "Angle Counterclockwise": "O",
    "Angle Clockwise": "L",
    "Vertical Text": "V",
    "Rotate Text Up": "U",
    "Rotate Text Down": "D",
    "Format Cell Alignment": "M",
    
    // Format as Table Menu (HT)
    "New Table Style...": "N",
    "New PivotTable Style...": "P",
    
    // Cell Styles Menu (HJ)
    "New Cell Style...": "N",
    "Merge Styles...": "M",
    
    // Wrap Text Menu (HW)
    "Wrap Text": "W",
    "Shrink Text to Fit": "S",
    
    // Underline Menu (H3)
    "Underline": "U",
    "Double Underline": "D",
    
    // Fill Menu (HFI)
    "Down": "D",
    "Right": "R",
    "Up": "U",
    "Left": "L",
    "Across Worksheets...": "A",
    "Series...": "S",
    "Justify": "J",
    "Flash Fill": "E",

    // =========================================================================
    // INSERT TAB POPUP MENUS (Alt + N)
    // =========================================================================

    // 1. Forms Menu (NFR)
    "New Form": "N",
    "Preview Form": "P",
    "Edit Form": "E",
    "Send Form": "S",

    // 2. From Picture Menu (NF1)
    "Picture From File...": "F",
    "Picture From Clipboard": "C",

    // 3. Pictures Menu (NP1) & Submenus (Place in Cell / Place over Cells)
    "Place in Cell": "C",
    "Place over Cells": "O",
    "Photo Browser…": "B",
    "Photo Browser...": "B",
    "Picture from File...": "F",
    "Stock Images...": "S",
    "Online Pictures...": "O",

    // 4. 3D Models Menu (NS3)
    "This Device...": "D",
    "Stock 3D Models...": "S",

    // 5. SmartArt Menu (NM)
    "List": "L",
    "Process": "P",
    "Cycle": "C",
    "Hierarchy": "H",
    "Relationship": "R",
    "Matrix": "M",
    "Pyramid": "Y",
    "Picture": "I",
    "Timeline": "T",
    "Meet The Team": "E",
    "Text Card": "X",

    // 6. Sparklines Menu (NY5)
    "Line": "L",
    "Column": "C",
    "Win/Loss": "W",

    // =========================================================================
    // DRAW TAB POPUP MENUS (Alt + JI)
    // =========================================================================

    // 1. Eraser Menu (JIE)
    "Stroke Eraser": "S",
    "Small Eraser": "L",
    "Medium Eraser": "M",
    "Segment Eraser": "G",

    // 2. Add Pen/Highlighter/Pencil Menu (JIA)
    "Pen": "P",
    "Highlighter": "H",
    "Pencil": "C",

    // =========================================================================
    // PAGE LAYOUT TAB POPUP MENUS (Alt + P)
    // =========================================================================

    // 1. Themes Menu (PTH)
    "Browse for Themes...": "B",
    "Save Current Theme...": "S",

    // 2. Margins Menu (PM)
    "Normal": "N",
    "Wide": "W",
    "Narrow": "R",
    "Last Custom Setting": "L",
    "Custom Margins...": "C",

    // 3. Orientation Menu (PO)
    "Portrait": "P",
    "Landscape": "L",

    // 4. Print Area Menu (PR)
    "Set Print Area": "S",
    "Clear Print Area": "C",
    "Add to Print Area": "A",

    // 5. Breaks Menu (PB)
    "Insert Page Break": "I",
    "Remove Page Break": "R",
    "Reset All Page Breaks": "A",

    // =========================================================================
    // FORMULAS TAB POPUP MENUS (Alt + M)
    // =========================================================================

    // 1. Insert Function item across Function Library Dropdowns & Submenus
    "Insert Function...": "F",

    // 2. More Functions Menu (MQ)
    "Statistical": "S",
    "Engineering": "E",
    "Cube": "C",
    "Information": "I",
    "Compatibility": "M",
    "Web": "W",

    // 3. Define Name Menu (MM)
    "Define Name...": "D",
    "Apply Names...": "A",

    // 4. Remove Arrows Menu (MA)
    "Remove Arrows": "A",
    "Remove Precedent Arrows": "P",
    "Remove Dependent Arrows": "D",

    // 5. Error Checking Menu (MK)
    "Error Checking...": "E",
    "Trace Error": "T",
    "Circular References": "C",

    // 6. Calculation Options Menu (MX) & Compatibility Version Submenu (MXC)
    "Partial": "P",
    "Manual": "M",
    "Format Stale Values": "F",
    "Compatibility Version": "C",
    "Version 1": "1",
    "Version 2 (Recommended)": "2",
    "Learn More": "L",

    // =========================================================================
    // DATA TAB POPUP MENUS (Alt + A)
    // =========================================================================

    // 1. Get Data (Power Query) Menu (APN)
    "Get Data (Power Query)...": "G",
    "Launch Power Query Editor...": "L",
    "Data Source Settings...": "D",
    "From Database (Microsoft Query)": "B",
    "From HTML": "H",
    "From Text (Legacy)": "T",
    "From SQL Server ODBC": "S",

    // 2. From Picture Menu (AF1) -> uses existing "Picture From File...": "F", "Picture From Clipboard": "C"

    // 3. Refresh All Menu (AR)
    "Refresh All": "A",
    "Refresh": "R",
    "Refresh Status": "S",
    "Cancel Refresh": "C",
    "Properties": "P",

    // 4. Data Validation Menu (AV1)
    "Data Validation...": "V",
    "Circle Invalid Data": "I",
    "Clear Validation Circles": "R",

    // 5. What-If Analysis Menu (AW)
    "Scenario Manager...": "S",
    "Goal Seek...": "G",
    "Data Table...": "T",

    // 6. Group Menu (AG)
    "Group...": "G",
    "Auto Outline": "A",

    // 7. Ungroup Menu (AU)
    "Ungroup...": "U",
    "Clear Outline": "C",

    // =========================================================================
    // REVIEW TAB POPUP MENUS (Alt + R)
    // =========================================================================

    // 1. Check Accessibility Menu (RA) — reuses "Unmerge Cells": "U"
    "Check Accessibility": "A",
    "Alt Text": "T",
    "Format as Table": "F",
    "Accessibility Help": "H",

    // 2. Notes Menu (RT)
    "New Note": "N",
    "Edit Note": "E",
    "Previous Note": "P",
    "Next Note": "X",
    "Show/Hide Note": "H",
    "Show All Notes": "A",
    "Convert to Comments": "C",

    // 3. Restrict Permission Menu (RR)
    "No Restrictions": "N",
    "Restricted Access...": "R",

    // 4. Hide Ink Menu (RH2)
    "Hide Ink": "H",
    "Delete All Ink on Sheet": "S",
    "Delete All Ink in Workbook": "W",

    // =========================================================================
    // VIEW TAB POPUP MENUS (Alt + W)
    // =========================================================================

    // 1. Show -> Focus Cell Menu (WZSE1)
    "Focus Cell": "F",
    "Focus Cell Color": "C",
    "Show Auto-Highlight": "A",

    // 2. Freeze Panes Menu (WF)
    "Freeze Panes": "F",
    "Unfreeze Panes": "F",
    "Freeze Top Row": "R",
    "Freeze First Column": "C",

    // 3. Switch Windows Menu (WW) -> Badges 1..N generated dynamically by collectSwitchWindowsBadges()

    // =========================================================================
    // AUTOMATE TAB POPUP MENUS (Alt + U)
    // =========================================================================

    // 1. New Script Menu (UN)
    "Create in Code Editor": "C",
    "Create from Recording": "R",

    // 2. View Scripts Menu (UV)
    "Recent Scripts": "R",
    "Scripts from this Workbook": "W",
    "Samples": "S",
]

let formatMenuLayout: [(String, CGFloat)] = [
    ("H", 0.075), ("A", 0.131), ("W", 0.209), ("I", 0.266), ("D", 0.319), ("U", 0.453),
    ("R", 0.588), ("M", 0.641), ("T", 0.694), ("P", 0.825), ("L", 0.881), ("E", 0.966),
]

let insertMenuLayout: [(String, CGFloat)] = [
    ("I", 0.14), ("R", 0.38), ("C", 0.62), ("S", 0.86),
]

let deleteMenuLayout: [(String, CGFloat)] = [
    ("D", 0.14), ("R", 0.38), ("C", 0.62), ("S", 0.86),
]

let hideMenuLayout: [(String, CGFloat)] = [
    ("R", 0.10), ("C", 0.26), ("S", 0.42), ("O", 0.58), ("L", 0.74), ("H", 0.90),
]

func findMenuWindow(pid: pid_t, preferSubmenu: Bool = false) -> CGRect? {
    guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else { return nil }
    var wins: [CGRect] = []
    for w in list {
        let owner = w[kCGWindowOwnerName as String] as? String ?? "?"
        let opid = w[kCGWindowOwnerPID as String] as? Int32 ?? 0
        guard opid == pid || owner.contains("Microsoft") || owner.contains("Excel"),
              let bd = w[kCGWindowBounds as String] as? NSDictionary,
              let r = CGRect(dictionaryRepresentation: bd as CFDictionary) else { continue }
        wins.append(r)
    }
    let biggest = wins.map { $0.width * $0.height }.max() ?? 0
    let candidates = wins.filter { r in
        let ratio = r.width / r.height
        return r.width * r.height < biggest && r.height > 60 && r.width > 100 && r.width < 500 && ratio > 0.2 && ratio < 2.5
    }
    if preferSubmenu && candidates.count > 1 {
        return candidates.max(by: { $0.minX < $1.minX })
    }
    return candidates.first
}

func collectRibbonBadges(pid: pid_t, mode: String) -> [(String, CGRect)] {
    let app = AXUIElementCreateApplication(pid)
    let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
    guard let main = activeStandardWindow(app, wins) else { return [] }
    
    var tabGroup: AXUIElement? = nil
    for c in children(main) {
        if role(c) == "AXTabGroup" { tabGroup = c; break }
    }
    guard let tg = tabGroup else { return [] }
    
    var hits: [(String, CGRect)] = []
    if mode == "tabs" {
        for c in children(tg) {
            let t = title(c)
            let r = role(c)
            if r == "AXRadioButton", let badge = tabKeyTips[t], let f = frameOf(c), f.height > 0 {
                let w: CGFloat = badge.count > 1 ? 22 : 16
                let badgeFrame = CGRect(x: f.midX - w/2, y: f.maxY - 8, width: w, height: 16)
                hits.append((badge, badgeFrame))
            }
        }
    } else if mode == "home" || mode == "insert" || mode == "draw" {
        let map: [String: String]
        if mode == "insert" {
            map = insertRibbonKeyTips
        } else if mode == "draw" {
            map = drawRibbonKeyTips
        } else {
            map = homeRibbonKeyTips
        }
        func scan(_ e: AXUIElement, depth: Int = 0) {
            if depth > 8 { return }
            let t = title(e)
            let d = (attr(e, kAXDescriptionAttribute) as? String) ?? ""
            let r = role(e)
            var badge = map[t]
            if badge == nil {
                let tNorm = t.replacingOccurrences(of: "\u{2011}", with: "-")
                badge = map[tNorm]
            }
            if mode == "home" {
                if badge == nil && r == "AXComboBox" {
                    if d.hasPrefix("Font Size:") { badge = "FS" }
                    else if d.hasPrefix("Font:") { badge = "FF" }
                    else if d.hasPrefix("Number Format") { badge = "N" }
                }
                if badge == nil && r == "AXCheckBox" && t == "Format" {
                    badge = "FP"
                }
            }
            if r != "AXRadioButton", let b = badge, let f = frameOf(e), f.height > 0 {
                let w: CGFloat = b.count > 1 ? 22 : 16
                let badgeFrame = CGRect(x: f.midX - w/2, y: f.maxY - 14, width: w, height: 16)
                hits.append((b, badgeFrame))
            }
            for c in children(e) { scan(c, depth: depth + 1) }
        }
        scan(tg)
    }
    return hits
}

let functionLibraryWindows: Set<String> = [
    "Recently Used", "Financial", "Logical", "Text", "Date & Time",
    "Lookup & Reference", "Math & Trig",
    "Statistical", "Engineering", "Cube", "Information", "Compatibility", "Web"
]

func collectAXBadges(pid: pid_t, windowTitle: String) -> [(String, CGRect)] {
    let app = AXUIElementCreateApplication(pid)
    let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
    var hits: [(String, CGRect)] = []
    let onlyInsertFunction = functionLibraryWindows.contains(windowTitle)
    for w in wins {
        if subrole(w) == "AXStandardWindow" { continue }
        let wt = title(w)
        if popupWindowMatches(wt, windowTitle) {
            func walk(_ e: AXUIElement, depth: Int = 0) {
                if depth > 8 { return }
                let r = role(e)
                if r != "AXWindow" && r != "AXMenu" {
                    let t = title(e)
                    let d = (attr(e, kAXDescriptionAttribute) as? String) ?? ""
                    let rawKey = !t.isEmpty ? t : d
                    let firstLine = rawKey.components(separatedBy: "\n").first ?? rawKey
                    let letter: String?
                    if onlyInsertFunction {
                        letter = (rawKey == "Insert Function..." || firstLine == "Insert Function...") ? "F" : nil
                    } else {
                        letter = axTitleBadges[rawKey] ?? axTitleBadges[firstLine]
                    }
                    if let letter = letter, let f = frameOf(e), f.width > 0 && f.height > 0 {
                        if windowTitle == "Themes" && r != "AXMenuButton" {
                            // Only badge the bottom menu buttons in Themes gallery
                        } else {
                            let w: CGFloat = letter.count > 1 ? 22 : 16
                            let badgeFrame = CGRect(x: f.minX + 8, y: f.midY - 8, width: w, height: 16)
                            hits.append((letter, badgeFrame))
                        }
                    }
                }
                for c in children(e) { walk(c, depth: depth + 1) }
            }
            walk(w)
        }
    }
    return hits
}

func collectMenuBadges(pid: pid_t, buffer: String) -> [(String, CGRect)] {
    let isSubmenu = (buffer == "HOU")
    guard let m = findMenuWindow(pid: pid, preferSubmenu: isSubmenu) else { return [] }
    let layout: [(String, CGFloat)]
    switch buffer {
    case "HO":   layout = formatMenuLayout
    case "HI":   layout = insertMenuLayout
    case "HD":   layout = deleteMenuLayout
    case "HOU":  layout = hideMenuLayout
    default:     layout = []
    }
    return layout.map { (letter, frac) -> (String, CGRect) in
        let cy = m.minY + frac * m.height
        let w: CGFloat = letter.count > 1 ? 22 : 16
        return (letter, CGRect(x: m.minX + 8, y: cy - 8, width: w, height: 16))
    }
}

func clearBadges() {
    DispatchQueue.main.async {
        badgeWindows.forEach { $0.orderOut(nil) }
        badgeWindows.removeAll()
        currentDrawnBuffer = ""
        currentMenuRect = .zero
    }
}

func drawBadges(_ hits: [(String, CGRect)], forBuffer buf: String, menuRect: CGRect) {
    if currentDrawnBuffer == buf && currentMenuRect.equalTo(menuRect) && !badgeWindows.isEmpty {
        return
    }
    
    badgeWindows.forEach { $0.orderOut(nil) }
    badgeWindows.removeAll()
    
    guard armed, let primary = NSScreen.screens.first(where: { $0.frame.origin == .zero }) ?? NSScreen.screens.first else {
        currentDrawnBuffer = ""
        currentMenuRect = .zero
        return
    }
    
    currentDrawnBuffer = buf
    currentMenuRect = menuRect
    
    for (letter, f) in hits {
        let w: CGFloat = f.width > 0 ? f.width : (letter.count > 1 ? 22 : 16)
        let h: CGFloat = f.height > 0 ? f.height : 16
        let p = NSPanel(contentRect: NSRect(x: 0, y: 0, width: w, height: h),
                        styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        p.level = .screenSaver
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = false
        p.ignoresMouseEvents = true
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        let box = NSView(frame: NSRect(x: 0, y: 0, width: w, height: h))
        box.wantsLayer = true
        box.layer?.backgroundColor = NSColor(white: 0.15, alpha: 0.85).cgColor
        box.layer?.borderColor = NSColor(white: 1.0, alpha: 0.40).cgColor
        box.layer?.borderWidth = 0.5
        box.layer?.cornerRadius = 2
        
        let l = NSTextField(labelWithString: letter)
        l.font = NSFont.boldSystemFont(ofSize: letter.count > 1 ? 10 : 11)
        l.textColor = NSColor.white
        l.alignment = .center
        l.frame = NSRect(x: 0, y: 0, width: w, height: h - 1)
        box.addSubview(l)
        
        p.contentView = box
        let screenY = primary.frame.height - f.minY - h
        p.setFrameOrigin(NSPoint(x: f.minX, y: screenY))
        p.orderFrontRegardless()
        badgeWindows.append(p)
    }
}

func refreshBadges(pid: pid_t, currentBuffer: String, after delay: Double) {
    DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
        guard armed, buffer == currentBuffer else { return }
        
        if currentDrawnBuffer == currentBuffer && !badgeWindows.isEmpty {
            if currentBuffer == "" || currentBuffer == "H" || currentBuffer == "N" {
                let app = AXUIElementCreateApplication(pid)
                let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
                if hasExcelKeyTips(wins) {
                    clearBadges()
                }
            }
            return
        }
        
        var hits: [(String, CGRect)] = []
        var menuBounds: CGRect = .zero
        
        switch currentBuffer {
        case "":
            let app = AXUIElementCreateApplication(pid)
            let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
            if !hasExcelKeyTips(wins) {
                hits = collectRibbonBadges(pid: pid, mode: "tabs")
            } else if !badgeWindows.isEmpty {
                clearBadges()
            }
        case "H":
            let app = AXUIElementCreateApplication(pid)
            let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
            if !hasExcelKeyTips(wins) {
                hits = collectRibbonBadges(pid: pid, mode: "home")
            } else if !badgeWindows.isEmpty {
                clearBadges()
            }
        case "N":
            let app = AXUIElementCreateApplication(pid)
            let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
            if !hasExcelKeyTips(wins) {
                hits = collectRibbonBadges(pid: pid, mode: "insert")
            } else if !badgeWindows.isEmpty {
                clearBadges()
            }
        case "HL":
            hits = collectAXBadges(pid: pid, windowTitle: "Conditional Formatting")
        case "HLH":
            hits = collectAXBadges(pid: pid, windowTitle: "Highlight Cells Rules")
        case "HLT":
            hits = collectAXBadges(pid: pid, windowTitle: "Top/Bottom Rules")
        case "HLC":
            hits = collectAXBadges(pid: pid, windowTitle: "Clear Rules")
        case "HO":
            hits = collectAXBadges(pid: pid, windowTitle: "Format")
            if hits.isEmpty { hits = collectMenuBadges(pid: pid, buffer: currentBuffer) }
        case "HOU":
            hits = collectAXBadges(pid: pid, windowTitle: "Hide & Unhide")
            if hits.isEmpty { hits = collectMenuBadges(pid: pid, buffer: currentBuffer) }
        case "HI", "HD":
            hits = collectMenuBadges(pid: pid, buffer: currentBuffer)
        case "HB":
            hits = collectAXBadges(pid: pid, windowTitle: "Borders")
        case "HH":
            hits = collectAXBadges(pid: pid, windowTitle: "Shading")
        case "HM":
            hits = collectAXBadges(pid: pid, windowTitle: "Merge & Center")
        case "HU":
            hits = collectAXBadges(pid: pid, windowTitle: "AutoSum")
        case "HS":
            hits = collectAXBadges(pid: pid, windowTitle: "Sort & Filter")
        case "HE", "HEE":
            hits = collectAXBadges(pid: pid, windowTitle: "Clear")
        case "HFD":
            hits = collectAXBadges(pid: pid, windowTitle: "Find & Select")
        case "HFQ":
            hits = collectAXBadges(pid: pid, windowTitle: "Orientation")
        case "HT":
            hits = collectAXBadges(pid: pid, windowTitle: "Format as Table")
        case "HJ":
            hits = collectAXBadges(pid: pid, windowTitle: "Cell Styles")
        case "HW":
            hits = collectAXBadges(pid: pid, windowTitle: "Wrap Text")
        case "HFC":
            hits = collectAXBadges(pid: pid, windowTitle: "Font Color")
        case "HFI":
            hits = collectAXBadges(pid: pid, windowTitle: "Fill")
        case "H3":
            hits = collectAXBadges(pid: pid, windowTitle: "Underline")
        case "NFR":
            hits = collectAXBadges(pid: pid, windowTitle: "Forms")
        case "NF1":
            hits = collectAXBadges(pid: pid, windowTitle: "From Picture")
        case "NP1":
            hits = collectAXBadges(pid: pid, windowTitle: "Pictures")
        case "NP1C", "NP1I":
            hits = collectAXBadges(pid: pid, windowTitle: "Place in Cell")
        case "NP1O", "NP1V":
            hits = collectAXBadges(pid: pid, windowTitle: "Place over Cells")
        case "NS3":
            hits = collectAXBadges(pid: pid, windowTitle: "3D Models")
        case "NM":
            hits = collectAXBadges(pid: pid, windowTitle: "SmartArt")
        case "NY5":
            hits = collectAXBadges(pid: pid, windowTitle: "Sparklines")
        case "JIE":
            hits = collectAXBadges(pid: pid, windowTitle: "Eraser")
        case "JIA":
            hits = collectAXBadges(pid: pid, windowTitle: "Add")
        case "PTH":
            hits = collectAXBadges(pid: pid, windowTitle: "Themes")
        case "PM":
            hits = collectAXBadges(pid: pid, windowTitle: "Margins")
        case "PO":
            hits = collectAXBadges(pid: pid, windowTitle: "Orientation")
        case "PR":
            hits = collectAXBadges(pid: pid, windowTitle: "Print Area")
        case "PB":
            hits = collectAXBadges(pid: pid, windowTitle: "Breaks")
        case "MU":
            hits = collectAXBadges(pid: pid, windowTitle: "AutoSum")
        case "MR":
            hits = collectAXBadges(pid: pid, windowTitle: "Recently Used")
        case "MI":
            hits = collectAXBadges(pid: pid, windowTitle: "Financial")
        case "ML":
            hits = collectAXBadges(pid: pid, windowTitle: "Logical")
        case "MT":
            hits = collectAXBadges(pid: pid, windowTitle: "Text")
        case "ME":
            hits = collectAXBadges(pid: pid, windowTitle: "Date & Time")
        case "MO":
            hits = collectAXBadges(pid: pid, windowTitle: "Lookup & Reference")
        case "MG":
            hits = collectAXBadges(pid: pid, windowTitle: "Math & Trig")
        case "MQ":
            hits = collectAXBadges(pid: pid, windowTitle: "More Functions")
        case "MQS":
            hits = collectAXBadges(pid: pid, windowTitle: "Statistical")
        case "MQE":
            hits = collectAXBadges(pid: pid, windowTitle: "Engineering")
        case "MQC":
            hits = collectAXBadges(pid: pid, windowTitle: "Cube")
        case "MQI":
            hits = collectAXBadges(pid: pid, windowTitle: "Information")
        case "MQM", "MQO":
            hits = collectAXBadges(pid: pid, windowTitle: "Compatibility")
        case "MQW":
            hits = collectAXBadges(pid: pid, windowTitle: "Web")
        case "MM":
            hits = collectAXBadges(pid: pid, windowTitle: "Define Name")
        case "MA":
            hits = collectAXBadges(pid: pid, windowTitle: "Remove Arrows")
        case "MK":
            hits = collectAXBadges(pid: pid, windowTitle: "Error Checking")
        case "MX":
            hits = collectAXBadges(pid: pid, windowTitle: "Calculation Options")
        case "MXC", "MXV":
            hits = collectAXBadges(pid: pid, windowTitle: "Compatibility Version")
        case "APN":
            hits = collectAXBadges(pid: pid, windowTitle: "Get Data (Power Query)")
        case "AF1":
            hits = collectAXBadges(pid: pid, windowTitle: "From Picture")
        case "AR":
            hits = collectAXBadges(pid: pid, windowTitle: "Refresh All")
        case "AV1":
            hits = collectAXBadges(pid: pid, windowTitle: "Data Validation")
        case "AW":
            hits = collectAXBadges(pid: pid, windowTitle: "What-If Analysis")
        case "AG":
            hits = collectAXBadges(pid: pid, windowTitle: "Group")
        case "AU":
            hits = collectAXBadges(pid: pid, windowTitle: "Ungroup")
        case "RA":
            hits = collectAXBadges(pid: pid, windowTitle: "Check Accessibility")
        case "RT":
            hits = collectAXBadges(pid: pid, windowTitle: "Notes")
        case "RR":
            hits = collectAXBadges(pid: pid, windowTitle: "Restrict Permission")
        case "RH2":
            hits = collectAXBadges(pid: pid, windowTitle: "Hide Ink")
        case "WZSE1":
            hits = collectAXBadges(pid: pid, windowTitle: "Focus Cell")
        case "WF":
            hits = collectAXBadges(pid: pid, windowTitle: "Freeze Panes")
        case "WW":
            hits = collectSwitchWindowsBadges(pid: pid)
        case "UN":
            hits = collectAXBadges(pid: pid, windowTitle: "New Script")
        case "UV":
            hits = collectAXBadges(pid: pid, windowTitle: "View Scripts")
        default:
            break
        }
        
        if !hits.isEmpty {
            let minX = hits.map { $0.1.minX }.min() ?? 0
            let minY = hits.map { $0.1.minY }.min() ?? 0
            let maxX = hits.map { $0.1.maxX }.max() ?? 0
            let maxY = hits.map { $0.1.maxY }.max() ?? 0
            menuBounds = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        }
        
        guard !hits.isEmpty else { return }
        
        DispatchQueue.main.async {
            guard armed, buffer == currentBuffer else { return }
            drawBadges(hits, forBuffer: currentBuffer, menuRect: menuBounds)
        }
    }
}

func setStatus(_ s: String) {
    DispatchQueue.main.async { statusItem?.button?.title = s }
}

func disarm(dismissKeyTips: Bool = true) {
    let wasRibbon = buffer.hasPrefix("H") || buffer.hasPrefix("N") || buffer.hasPrefix("J") || buffer.hasPrefix("P") || buffer.hasPrefix("M") || buffer.hasPrefix("A") || buffer.hasPrefix("R") || buffer.hasPrefix("W") || buffer.hasPrefix("U")
    armed = false
    buffer = ""
    setStatus("⌥")
    clearBadges()
    if dismissKeyTips && wasRibbon {
        if let front = NSWorkspace.shared.frontmostApplication,
           let bid = front.bundleIdentifier, targetApps.contains(bid) {
            let pid = front.processIdentifier
            actionQueue.async {
                let app = AXUIElementCreateApplication(pid)
                let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
                if hasExcelKeyTips(wins) || wins.contains(where: { isPopupMenuWindow($0) }) {
                    postKeyToPid(53, pid: pid)
                }
                closeShowPopovers(pid: pid)
            }
        }
    }
}

func finish(_ seq: String) {
    armed = false
    buffer = ""
    print("[AltKeys] Executed \(seq)")
    setStatus("⌥ " + seq + " ✓")
    clearBadges()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
        if !armed { statusItem?.button?.title = "⌥" }
    }
}

let callback: CGEventTapCallBack = { _, type, event, _ in
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        print("[AltKeys] Re-enabling keyboard tap...")
        optionDown = false
        otherKeyUsed = false
        if armed { disarm(dismissKeyTips: false) }
        if let tap = tap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return Unmanaged.passUnretained(event)
    }

    guard let front = NSWorkspace.shared.frontmostApplication,
          let bid = front.bundleIdentifier, targetApps.contains(bid) else {
        if armed { disarm() }
        return Unmanaged.passUnretained(event)
    }

    if armed && Date().timeIntervalSince(armedAt) > 5 { disarm() }

    if type == .flagsChanged {
        let f = event.flags
        let onlyOption = f.contains(.maskAlternate) &&
            !f.contains(.maskCommand) && !f.contains(.maskControl) && !f.contains(.maskShift)
        if onlyOption {
            optionDown = true
            otherKeyUsed = false
        } else if optionDown && !f.contains(.maskAlternate) {
            optionDown = false
            if !otherKeyUsed {
                let pid = front.processIdentifier
                baselineWindows = excelWindowCount(pid)
                armed = true
                buffer = ""
                armedAt = Date()
                setStatus("⌥…")
                clearBadges()
                for d in [0.06, 0.18, 0.35] {
                    refreshBadges(pid: pid, currentBuffer: "", after: d)
                }
            }
        }
        return Unmanaged.passUnretained(event)
    }

    if type == .keyDown {
        if optionDown {
            let keycode = event.getIntegerValueField(.keyboardEventKeycode)
            if (keycode == 4 || keycode == 45 || keycode == 38 || keycode == 35 || keycode == 46 || keycode == 0 || keycode == 15 || keycode == 13 || keycode == 32) && !armed { // 'H' (4), 'N' (45), 'J' (38), 'P' (35), 'M' (46), 'A' (0), 'R' (15), 'W' (13), or 'U' (32) pressed while holding Option
                let tabLetter: String
                switch keycode {
                case 4:  tabLetter = "H"
                case 45: tabLetter = "N"
                case 38: tabLetter = "J"
                case 35: tabLetter = "P"
                case 46: tabLetter = "M"
                case 0:  tabLetter = "A"
                case 15: tabLetter = "R"
                case 13: tabLetter = "W"
                default: tabLetter = "U"
                }
                otherKeyUsed = true
                armed = true
                buffer = tabLetter
                let pid = front.processIdentifier
                baselineWindows = excelWindowCount(pid)
                armedAt = Date()
                setStatus("⌥ " + tabLetter)
                clearBadges()
                
                if keycode != 38 {
                    let tabName: String
                    switch keycode {
                    case 4:  tabName = "Home"
                    case 45: tabName = "Insert"
                    case 35: tabName = "Page Layout"
                    case 46: tabName = "Formulas"
                    case 0:  tabName = "Data"
                    case 15: tabName = "Review"
                    case 13: tabName = "View"
                    default: tabName = "Automate"
                    }
                    // Select tab cleanly via Accessibility without posting synthetic keystrokes that can type into a cell
                    actionQueue.async {
                        selectRibbonTab(pid: pid, name: tabName)
                    }
                    if keycode == 4 || keycode == 45 {
                        for d in [0.04, 0.12, 0.25] {
                            refreshBadges(pid: pid, currentBuffer: tabLetter, after: d)
                        }
                    }
                }
                return nil
            }
            if !armed {
                otherKeyUsed = true
                return Unmanaged.passUnretained(event)
            }
        }

        let keycode = event.getIntegerValueField(.keyboardEventKeycode)
        
        // Return/Enter key (36/76) while focused on ribbon ComboBox or Focus Cell Color picker: restore grid focus
        if keycode == 36 || keycode == 76 {
            let app = AXUIElementCreateApplication(front.processIdentifier)
            let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
            if wins.contains(where: { isPopupMenuWindow($0) && title($0) == "Focus Cell Color" }) {
                let pid = front.processIdentifier
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.12) {
                    closeShowPopovers(pid: pid)
                    restoreGridFocus(pid: pid, force: true)
                }
            } else if keycode == 36, let f = attr(app, kAXFocusedUIElementAttribute) {
                let fe = f as! AXUIElement
                if role(fe) == "AXComboBox" {
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.12) {
                        restoreGridFocus(pid: front.processIdentifier, force: true)
                    }
                }
            }
        }
        
        // Navigation keys: Left (123), Right (124), Down (125), Up (126), Tab (48), Home (115), PageUp (116), End (119), PageDown (121)
        let isNavKey = (keycode >= 123 && keycode <= 126) || keycode == 48 || keycode == 115 || keycode == 116 || keycode == 119 || keycode == 121
        if isNavKey {
            let app = AXUIElementCreateApplication(front.processIdentifier)
            let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
            let hasPopup = wins.contains { isPopupMenuWindow($0) }
            if armed { disarm(dismissKeyTips: !hasPopup) }
            if !hasPopup {
                if let f = attr(app, kAXFocusedUIElementAttribute) {
                    let fe = f as! AXUIElement
                    let r = role(fe)
                    let d = ((attr(fe, kAXDescriptionAttribute) as? String) ?? "") + title(fe)
                    // If focused on Content Area (cell grid), allow native navigation directly
                    if r != "AXLayoutArea" {
                        let isCellEditor = r == "AXTextArea" && (d.localizedCaseInsensitiveContains("formula") || d.localizedCaseInsensitiveContains("edit") || d.isEmpty)
                        if !isCellEditor {
                            restoreGridFocus(pid: front.processIdentifier, force: true)
                        }
                    }
                } else {
                    restoreGridFocus(pid: front.processIdentifier, force: true)
                }
            }
            return Unmanaged.passUnretained(event)
        }

        // Escape key (53): Cancel shortcut, dismiss badges, and restore grid focus with ZERO BEEP!
        if keycode == 53 {
            let wasArmed = armed
            let wasRibbon = buffer.hasPrefix("H") || buffer.hasPrefix("N") || buffer.hasPrefix("J") || buffer.hasPrefix("P") || buffer.hasPrefix("M") || buffer.hasPrefix("A") || buffer.hasPrefix("R") || buffer.hasPrefix("W") || buffer.hasPrefix("U")
            let pid = front.processIdentifier
            let app = AXUIElementCreateApplication(pid)
            let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
            let hasPopup = wins.contains { isPopupMenuWindow($0) }
            let hasShowPop = wins.contains { subrole($0) == "AXStandardWindow" && hasShowPopover($0) }
            let hasDialog = wins.contains {
                (role($0) == "AXWindow" && (subrole($0) == "AXDialog" || subrole($0) == "AXSystemDialog")) ||
                children($0).contains(where: { role($0) == "AXSheet" })
            }
            
            if armed {
                disarm(dismissKeyTips: false)
            }
            
            if hasDialog {
                // If a real modal dialog is open (e.g. Format Cells), forward Escape natively so dialog closes!
                return Unmanaged.passUnretained(event)
            } else if hasPopup {
                // An Excel popup menu or dropdown is open: post 1 Escape to close it!
                postKeyToPid(53, pid: pid)
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.08) {
                    closeShowPopovers(pid: pid)
                    restoreGridFocus(pid: pid, force: true)
                }
                return nil // Swallow event so Excel never receives an extra/unhandled Escape to beep!
            } else if hasShowPop {
                if hasExcelKeyTips(wins) {
                    postKeyToPid(53, pid: pid)
                }
                closeShowPopovers(pid: pid)
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.05) {
                    restoreGridFocus(pid: pid, force: true)
                }
                return nil
            } else if wasArmed && wasRibbon {
                // KeyTips badges are showing on ribbon: post 1 Escape to dismiss native KeyTips if active!
                if hasExcelKeyTips(wins) {
                    postKeyToPid(53, pid: pid)
                }
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.05) {
                    restoreGridFocus(pid: pid, force: true)
                }
                return nil // Swallow event to avoid duplicate Escape beep!
            } else {
                // No popup and no KeyTips.
                // Check if user was editing a cell/formula bar:
                if !wasArmed, let curFocus = attr(app, kAXFocusedUIElementAttribute) {
                    let fe = curFocus as! AXUIElement
                    let r = role(fe)
                    let d = ((attr(fe, kAXDescriptionAttribute) as? String) ?? "") + title(fe)
                    let isCellEditing = (r == "AXTextArea" && (d.localizedCaseInsensitiveContains("formula") || d.localizedCaseInsensitiveContains("edit") || d.isEmpty)) || ((r == "AXGroup" || r == "AXUnknown") && d.isEmpty)
                    if isCellEditing {
                        // User is actively editing a cell or Note/Shape object: forward Escape natively to exit edit without beep
                        return Unmanaged.passUnretained(event)
                    }
                    if r != "AXLayoutArea" {
                        restoreGridFocus(pid: pid, force: true)
                    }
                } else if wasArmed {
                    restoreGridFocus(pid: pid, force: true)
                }
                // SWALLOW Escape on the grid to prevent macOS/Excel from playing alert beep!
                return nil
            }
        }

        guard armed else { return Unmanaged.passUnretained(event) }

        let keycodeMap: [Int64: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
            11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 18: "1", 19: "2",
            20: "3", 21: "4", 22: "6", 23: "5", 25: "9", 26: "7", 28: "8", 29: "0", 31: "O",
            32: "U", 34: "I", 35: "P", 37: "L", 38: "J", 40: "K", 45: "N", 46: "M"
        ]
        var ch: String
        if let mapped = keycodeMap[keycode] {
            ch = mapped
        } else {
            var chars = [UniChar](repeating: 0, count: 4)
            var len = 0
            event.keyboardGetUnicodeString(maxStringLength: 4, actualStringLength: &len, unicodeString: &chars)
            ch = String(utf16CodeUnits: chars, count: len).uppercased()
        }

        guard ch.count == 1, ch.first!.isLetter || ch.first!.isNumber else {
            if keycode == 36 || keycode == 76 { // Return or Enter key
                if buffer == "HW" {
                    finish("HW")
                    run(.pressAX("Wrap Text"), pid: front.processIdentifier)
                    return nil
                } else if buffer == "HU" {
                    finish("HU")
                    run(.pressAX("Sum"), pid: front.processIdentifier)
                    return nil
                } else if buffer == "HM" {
                    finish("HM")
                    run(.pressAX("Merge & Center"), pid: front.processIdentifier)
                    return nil
                } else if buffer == "HB" {
                    finish("HB")
                    run(.pressAX("Bottom Border"), pid: front.processIdentifier)
                    return nil
                } else if buffer == "JIE" {
                    finish("JIE")
                    run(.pressAX("Eraser > Stroke Eraser"), pid: front.processIdentifier)
                    return nil
                } else if buffer == "JIA" {
                    finish("JIA")
                    run(.pressAX("Add > Pen"), pid: front.processIdentifier)
                    return nil
                } else if buffer == "PTH" {
                    finish("PTH")
                    run(.pressAX("Themes > Office"), pid: front.processIdentifier)
                    return nil
                } else if buffer == "PM" {
                    finish("PM")
                    run(.pressAX("Margins > Normal"), pid: front.processIdentifier)
                    return nil
                } else if buffer == "PO" {
                    finish("PO")
                    run(.pressAX("PageOrientation > Portrait"), pid: front.processIdentifier)
                    return nil
                } else if buffer == "PR" {
                    finish("PR")
                    run(.pressAX("Print Area > Set Print Area"), pid: front.processIdentifier)
                    return nil
                } else if buffer == "PB" {
                    finish("PB")
                    run(.pressAX("Breaks > Insert Page Break"), pid: front.processIdentifier)
                    return nil
                } else if buffer == "MU" {
                    finish("MU")
                    run(.pressAX("FormulasAutoSum > Sum"), pid: front.processIdentifier)
                    return nil
                } else if buffer == "MM" {
                    finish("MM")
                    run(.pressAX("Define Name > Define Name..."), pid: front.processIdentifier)
                    return nil
                } else if buffer == "MA" {
                    finish("MA")
                    run(.pressAX("Remove Arrows > Remove Arrows"), pid: front.processIdentifier)
                    return nil
                } else if buffer == "MK" {
                    finish("MK")
                    run(.pressAX("Error Checking > Error Checking..."), pid: front.processIdentifier)
                    return nil
                } else if buffer == "MX" {
                    finish("MX")
                    run(.pressAX("Calculation Options > Automatic"), pid: front.processIdentifier)
                    return nil
                } else if buffer == "APN" {
                    finish("APN")
                    run(.pressAX("Get Data (Power Query) > Get Data (Power Query)..."), pid: front.processIdentifier)
                    return nil
                } else if buffer == "AF1" {
                    finish("AF1")
                    run(.pressAX("DataFromPicture > Picture From File..."), pid: front.processIdentifier)
                    return nil
                } else if buffer == "AR" {
                    finish("AR")
                    run(.pressAX("Refresh All > Refresh All"), pid: front.processIdentifier)
                    return nil
                } else if buffer == "AV1" {
                    finish("AV1")
                    run(.pressAX("Data Validation > Data Validation..."), pid: front.processIdentifier)
                    return nil
                } else if buffer == "AW" {
                    finish("AW")
                    run(.pressAX("What-If Analysis > Scenario Manager..."), pid: front.processIdentifier)
                    return nil
                } else if buffer == "AG" {
                    finish("AG")
                    run(.pressAX("Group > Group..."), pid: front.processIdentifier)
                    return nil
                } else if buffer == "AU" {
                    finish("AU")
                    run(.pressAX("Ungroup > Ungroup..."), pid: front.processIdentifier)
                    return nil
                } else if buffer == "RA" {
                    finish("RA")
                    run(.pressAX("Check Accessibility > Check Accessibility"), pid: front.processIdentifier)
                    return nil
                } else if buffer == "RT" {
                    finish("RT")
                    run(.pressAX("ReviewNotes > New Note"), pid: front.processIdentifier)
                    return nil
                } else if buffer == "RR" {
                    finish("RR")
                    run(.pressAX("Restrict Permission > No Restrictions"), pid: front.processIdentifier)
                    return nil
                } else if buffer == "RH2" {
                    finish("RH2")
                    run(.pressAX("Hide Ink > Hide Ink"), pid: front.processIdentifier)
                    return nil
                } else if buffer == "WZSE1" {
                    finish("WZSE1")
                    run(.pressAX("Focus Cell > Focus Cell"), pid: front.processIdentifier)
                    return nil
                } else if buffer == "WF" {
                    finish("WF")
                    run(.pressAX("Freeze Panes > Freeze Panes"), pid: front.processIdentifier)
                    return nil
                } else if buffer == "WW" {
                    finish("WW")
                    switchExcelWindowByKey(pid: front.processIdentifier, key: "1")
                    return nil
                } else if buffer == "WZM" {
                    finish("WZM")
                    run(.pressAX("MacrosPopover > View Macros"), pid: front.processIdentifier)
                    return nil
                } else if buffer == "UN" {
                    finish("UN")
                    run(.pressAX("New Script > Create in Code Editor"), pid: front.processIdentifier)
                    return nil
                } else if buffer == "UV" {
                    finish("UV")
                    run(.pressAX("View Scripts > Recent Scripts"), pid: front.processIdentifier)
                    return nil
                }
            }
            disarm()
            return Unmanaged.passUnretained(event)
        }

        buffer += ch
        armedAt = Date()
        setStatus("⌥ " + buffer)
        
        let buf = buffer
        let pid = front.processIdentifier
        
        // Single letter (e.g. "H" or "N"): top-level tab key.
        // NEVER pass raw 'H' or 'N' through to Excel when native KeyTips aren't active (otherwise Excel types into the active cell
        // and enters Cell Edit Mode!).
        if buf.count == 1 {
            clearBadges()
            if buf == "H" || buf == "N" || buf == "P" || buf == "M" || buf == "A" || buf == "R" || buf == "W" || buf == "U" {
                let tabName: String
                let vk: CGKeyCode
                switch buf {
                case "H": tabName = "Home";        vk = 4
                case "N": tabName = "Insert";      vk = 45
                case "P": tabName = "Page Layout"; vk = 35
                case "M": tabName = "Formulas";    vk = 46
                case "A": tabName = "Data";        vk = 0
                case "R": tabName = "Review";      vk = 15
                case "W": tabName = "View";        vk = 13
                default:  tabName = "Automate";    vk = 32
                }
                actionQueue.async {
                    let app = AXUIElementCreateApplication(pid)
                    let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
                    if let main = activeStandardWindow(app, wins) {
                        commitCellEditIfNeeded(main)
                    }
                    let winsAfter = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
                    if hasExcelKeyTips(winsAfter) && armed && buffer.hasPrefix(buf) {
                        postKeyToPid(vk, pid: pid)
                    } else {
                        selectRibbonTab(pid: pid, name: tabName)
                    }
                }
                if buf == "H" || buf == "N" {
                    for d in [0.08, 0.18, 0.30] {
                        refreshBadges(pid: pid, currentBuffer: buf, after: d)
                    }
                }
                return nil
            } else if buf == "J" {
                actionQueue.async {
                    let app = AXUIElementCreateApplication(pid)
                    let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
                    if let main = activeStandardWindow(app, wins) {
                        commitCellEditIfNeeded(main)
                    }
                    let winsAfter = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
                    if hasExcelKeyTips(winsAfter) && armed && buffer.hasPrefix("J") {
                        postKeyToPid(38, pid: pid) // J
                    }
                }
                return nil
            } else if sequences.keys.contains(where: { $0.hasPrefix(buf) }) {
                return nil
            } else {
                disarm(dismissKeyTips: false)
                return Unmanaged.passUnretained(event)
            }
        }
        
        // Directly trigger menu/submenu opening via Accessibility on serialized actionQueue so event tap never stalls
        actionQueue.async {
            if buf == "HO" {
                openRibbonMenu(pid: pid, name: "Format")
            } else if buf == "HI" {
                openRibbonMenu(pid: pid, name: "Insert")
            } else if buf == "HD" {
                openRibbonMenu(pid: pid, name: "Delete")
            } else if buf == "HOU" {
                _ = pressAXNamedItem(pid: pid, name: "Hide & Unhide")
            } else if buf == "HL" {
                openRibbonMenu(pid: pid, name: "Conditional Formatting")
            } else if buf == "HLH" {
                _ = pressAXNamedItem(pid: pid, name: "Highlight Cells Rules")
            } else if buf == "HLT" {
                _ = pressAXNamedItem(pid: pid, name: "Top/Bottom Rules")
            } else if buf == "HLC" {
                _ = pressAXNamedItem(pid: pid, name: "Clear Rules")
            } else if buf == "HLD" {
                _ = pressAXNamedItem(pid: pid, name: "Data Bars")
            } else if buf == "HLS" {
                _ = pressAXNamedItem(pid: pid, name: "Color Scales")
            } else if buf == "HLI" {
                _ = pressAXNamedItem(pid: pid, name: "Icon Sets")
            } else if buf == "HB" {
                openRibbonMenu(pid: pid, name: "Borders")
            } else if buf == "HH" {
                openRibbonMenu(pid: pid, name: "Shading")
            } else if buf == "HM" {
                openRibbonMenu(pid: pid, name: "Merge & Center")
            } else if buf == "HU" {
                openRibbonMenu(pid: pid, name: "AutoSum")
            } else if buf == "HS" {
                openRibbonMenu(pid: pid, name: "Sort & Filter")
            } else if buf == "HE" || buf == "HEE" {
                openRibbonMenu(pid: pid, name: "Clear")
            } else if buf == "HFD" {
                openRibbonMenu(pid: pid, name: "Find & Select")
            } else if buf == "HFQ" {
                openRibbonMenu(pid: pid, name: "Orientation")
            } else if buf == "HT" {
                openRibbonMenu(pid: pid, name: "Format as Table")
            } else if buf == "HJ" {
                openRibbonMenu(pid: pid, name: "Cell Styles")
            } else if buf == "HW" {
                openRibbonMenu(pid: pid, name: "Wrap Text")
            } else if buf == "HFC" {
                openRibbonMenu(pid: pid, name: "Font Color")
            } else if buf == "HFI" {
                openRibbonMenu(pid: pid, name: "Fill")
            } else if buf == "H3" {
                openRibbonMenu(pid: pid, name: "Underline")
            } else if buf == "NFR" {
                openRibbonMenu(pid: pid, name: "Forms", tab: "Insert")
            } else if buf == "NF1" {
                openRibbonMenu(pid: pid, name: "From Picture", tab: "Insert")
            } else if buf == "NP1" {
                openRibbonMenu(pid: pid, name: "Pictures", tab: "Insert")
            } else if buf == "NP1C" || buf == "NP1I" {
                openRibbonMenu(pid: pid, name: "Pictures", tab: "Insert")
                for _ in 0..<10 {
                    if pressAXNamedItem(pid: pid, name: "Pictures > Place in Cell") { break }
                    usleep(25_000)
                }
            } else if buf == "NP1O" || buf == "NP1V" {
                openRibbonMenu(pid: pid, name: "Pictures", tab: "Insert")
                for _ in 0..<10 {
                    if pressAXNamedItem(pid: pid, name: "Pictures > Place over Cells") { break }
                    usleep(25_000)
                }
            } else if buf == "NS3" {
                openRibbonMenu(pid: pid, name: "3D Models", tab: "Insert")
            } else if buf == "NM" {
                openRibbonMenu(pid: pid, name: "SmartArt", tab: "Insert")
            } else if buf == "NY5" {
                openRibbonMenu(pid: pid, name: "Sparklines", tab: "Insert")
            } else if buf == "JI" {
                clearBadges()
                let app = AXUIElementCreateApplication(pid)
                let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
                if hasExcelKeyTips(wins) && armed && buffer.hasPrefix("JI") {
                    postKeyToPid(34, pid: pid) // I
                } else {
                    selectRibbonTab(pid: pid, name: "Draw")
                }
            } else if buf == "JIE" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "Eraser", tab: "Draw")
            } else if buf == "JIA" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "Add", tab: "Draw")
            } else if buf == "PTH" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "Themes", tab: "Page Layout")
            } else if buf == "PM" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "Margins", tab: "Page Layout")
            } else if buf == "PO" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "PageOrientation", tab: "Page Layout")
            } else if buf == "PR" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "Print Area", tab: "Page Layout")
            } else if buf == "PB" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "Breaks", tab: "Page Layout")
            } else if buf == "MU" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "FormulasAutoSum", tab: "Formulas")
            } else if buf == "MR" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "Recently Used", tab: "Formulas")
            } else if buf == "MI" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "Financial", tab: "Formulas")
            } else if buf == "ML" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "Logical", tab: "Formulas")
            } else if buf == "MT" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "Text", tab: "Formulas")
            } else if buf == "ME" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "Date & Time", tab: "Formulas")
            } else if buf == "MO" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "Lookup & Reference", tab: "Formulas")
            } else if buf == "MG" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "Math & Trig", tab: "Formulas")
            } else if buf == "MQ" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "More Functions", tab: "Formulas")
            } else if buf == "MQS" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "More Functions", tab: "Formulas")
                for _ in 0..<10 {
                    if pressAXNamedItem(pid: pid, name: "More Functions > Statistical") { break }
                    usleep(25_000)
                }
            } else if buf == "MQE" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "More Functions", tab: "Formulas")
                for _ in 0..<10 {
                    if pressAXNamedItem(pid: pid, name: "More Functions > Engineering") { break }
                    usleep(25_000)
                }
            } else if buf == "MQC" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "More Functions", tab: "Formulas")
                for _ in 0..<10 {
                    if pressAXNamedItem(pid: pid, name: "More Functions > Cube") { break }
                    usleep(25_000)
                }
            } else if buf == "MQI" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "More Functions", tab: "Formulas")
                for _ in 0..<10 {
                    if pressAXNamedItem(pid: pid, name: "More Functions > Information") { break }
                    usleep(25_000)
                }
            } else if buf == "MQM" || buf == "MQO" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "More Functions", tab: "Formulas")
                for _ in 0..<10 {
                    if pressAXNamedItem(pid: pid, name: "More Functions > Compatibility") { break }
                    usleep(25_000)
                }
            } else if buf == "MQW" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "More Functions", tab: "Formulas")
                for _ in 0..<10 {
                    if pressAXNamedItem(pid: pid, name: "More Functions > Web") { break }
                    usleep(25_000)
                }
            } else if buf == "MM" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "Define Name", tab: "Formulas")
            } else if buf == "MA" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "Remove Arrows", tab: "Formulas")
            } else if buf == "MK" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "Error Checking", tab: "Formulas")
            } else if buf == "MX" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "Calculation Options", tab: "Formulas")
            } else if buf == "MXC" || buf == "MXV" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "Calculation Options", tab: "Formulas")
                for _ in 0..<10 {
                    if pressAXNamedItem(pid: pid, name: "Calculation Options > Compatibility Version") { break }
                    usleep(25_000)
                }
            } else if buf == "APN" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "Get Data (Power Query)", tab: "Data")
            } else if buf == "AF1" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "DataFromPicture", tab: "Data")
            } else if buf == "AR" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "Refresh All", tab: "Data")
            } else if buf == "AV1" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "Data Validation", tab: "Data")
            } else if buf == "AW" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "What-If Analysis", tab: "Data")
            } else if buf == "AG" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "Group", tab: "Data")
            } else if buf == "AU" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "Ungroup", tab: "Data")
            } else if buf == "RA" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "Check Accessibility", tab: "Review")
            } else if buf == "RT" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "ReviewNotes", tab: "Review")
            } else if buf == "RR" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "Restrict Permission", tab: "Review")
            } else if buf == "RH2" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "Hide Ink", tab: "Review")
            } else if buf == "WZ" {
                clearBadges()
                let app = AXUIElementCreateApplication(pid)
                let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
                if hasExcelKeyTips(wins) && armed && buffer.hasPrefix("WZ") {
                    postKeyToPid(6, pid: pid) // Z
                }
            } else if buf == "WZS" {
                clearBadges()
                let app = AXUIElementCreateApplication(pid)
                let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
                if hasExcelKeyTips(wins) && armed && buffer.hasPrefix("WZS") {
                    postKeyToPid(1, pid: pid) // S — opens Show popover with native Excel KeyTips (K, R1, VG, VF, VH, VI, E1)
                } else {
                    openShowPopover(pid: pid)
                }
            } else if buf == "WZSE1" {
                clearBadges()
                openFocusCellMenu(pid: pid)
            } else if buf == "WZM" {
                clearBadges()
                let app = AXUIElementCreateApplication(pid)
                let wins = (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
                if hasExcelKeyTips(wins) && armed && buffer.hasPrefix("WZM") {
                    postKeyToPid(46, pid: pid) // M — opens Macros popover once with native Excel KeyTips (PM, R2, U2), zero blinking!
                } else {
                    openMacrosPopover(pid: pid)
                }
            } else if buf == "WF" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "Freeze Panes", tab: "View")
            } else if buf == "WW" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "Switch Windows", tab: "View")
            } else if buf == "UN" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "New Script", tab: "Automate")
            } else if buf == "UV" {
                clearBadges()
                openRibbonMenu(pid: pid, name: "View Scripts", tab: "Automate")
            }
        }
        
        for d in [0.04, 0.12, 0.25, 0.45, 0.8, 1.2] {
            refreshBadges(pid: pid, currentBuffer: buf, after: d)
        }

        // Dynamic Switch Windows (Alt + W + W -> 1..N based on exact open Excel windows)
        if buffer == "WW" {
            return nil
        } else if buffer.hasPrefix("WW") {
            let subKey = String(buffer.dropFirst(2))
            let validKeys = validSwitchWindowsKeys(pid: pid)
            let exactMatch = validKeys.contains { $0.caseInsensitiveCompare(subKey) == .orderedSame }
            let extendable = validKeys.contains { $0.count > subKey.count && $0.uppercased().hasPrefix(subKey.uppercased()) }
            if exactMatch && !extendable {
                finish(buffer)
                switchExcelWindowByKey(pid: pid, key: subKey)
                return nil
            } else if exactMatch || extendable {
                return nil
            } else {
                // Non-existent window shortcut: ignore invalid key and keep Switch Windows open at "WW"
                buffer = "WW"
                setStatus("⌥ WW")
                return nil
            }
        }

        if let action = sequences[buffer] {
            let extendable = sequences.keys.contains { $0.count > buffer.count && $0.hasPrefix(buffer) }
            if !extendable {
                finish(buffer)
                run(action, pid: pid)
                return nil
            }
            return nil // Swallow intermediate completed key if extendable
        } else if sequences.keys.contains(where: { $0.hasPrefix(buffer) }) {
            // Buffer is a valid prefix of an existing sequence (e.g. "HL", "HLH", "HO", "HI", "HD", etc.)
            // Swallow key event so Excel never receives raw keystrokes or emits alert beeps
            return nil
        } else {
            disarm(dismissKeyTips: false)
            return Unmanaged.passUnretained(event)
        }
    }
    return Unmanaged.passUnretained(event)
}

// MARK: - Main & Menu Bar AppDelegate

var statusHeaderItem: NSMenuItem!
var permissionTimer: Timer?
var globalMouseMonitor: Any?

@discardableResult
func tryAttachEventTap() -> Bool {
    if tap != nil { return true }
    guard AXIsProcessTrusted() else { return false }
    let mask = CGEventMask((1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue))
    guard let createdTap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
                                             options: .defaultTap, eventsOfInterest: mask,
                                             callback: callback, userInfo: nil) else {
        return false
    }
    let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, createdTap, 0)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), src, .commonModes)
    tap = createdTap
    CGEvent.tapEnable(tap: createdTap, enable: true)

    if globalMouseMonitor == nil {
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { _ in
            if armed {
                DispatchQueue.main.async {
                    disarm(dismissKeyTips: false)
                }
            }
        }
    }

    permissionTimer?.invalidate()
    permissionTimer = nil
    statusItem?.button?.title = "⌥"
    statusHeaderItem?.title = "AltKeysLite — Active ✓"
    print("[AltKeys] Started! Monitoring shortcuts for Excel & PowerPoint.")
    return true
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the ⌥ menu bar indicator inside applicationDidFinishLaunching so macOS docks it immediately in the top menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.isVisible = true
        if let btn = statusItem.button {
            btn.title = "⌥"
            btn.toolTip = "AltKeysLite — Excel & PowerPoint Alt Shortcuts"
        }

        let menu = NSMenu()
        statusHeaderItem = NSMenuItem(title: "AltKeysLite — Starting…", action: nil, keyEquivalent: "")
        statusHeaderItem.isEnabled = false
        menu.addItem(statusHeaderItem)
        menu.addItem(NSMenuItem.separator())

        let axItem = NSMenuItem(title: "Open Accessibility Settings…", action: #selector(openAccessibilitySettings), keyEquivalent: "")
        axItem.target = self
        menu.addItem(axItem)

        let imItem = NSMenuItem(title: "Open Input Monitoring Settings…", action: #selector(openInputMonitoringSettings), keyEquivalent: "")
        imItem.target = self
        menu.addItem(imItem)

        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit AltKeysLite", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu

        // Attempt immediate event tap attach; if permissions are not yet granted on a new Mac,
        // trigger macOS's native Accessibility prompt, keep ⌥ visible in the menu bar, and auto-activate live as soon as toggled ON!
        if !tryAttachEventTap() {
            let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(opts)
            statusItem.button?.title = "⌥"
            statusHeaderItem.title = "AltKeysLite — Enable in Accessibility Settings…"

            let timer = Timer(timeInterval: 1.0, repeats: true) { _ in
                _ = tryAttachEventTap()
            }
            RunLoop.main.add(timer, forMode: .common)
            permissionTimer = timer
        }
    }

    @objc func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc func openInputMonitoringSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// Set a strict 1.5s Accessibility IPC timeout so a busy Excel UI never stalls our worker queue
AXUIElementSetMessagingTimeout(AXUIElementCreateSystemWide(), 1.5)

// Safely terminate any older AltKeysLite instance via NSRunningApplication (zero shell subprocesses)
let myPid = ProcessInfo.processInfo.processIdentifier
for running in NSWorkspace.shared.runningApplications where running.processIdentifier != myPid {
    let exe = running.executableURL?.lastPathComponent ?? ""
    let bid = running.bundleIdentifier ?? ""
    if bid == "com.altkeyslite.excel" || exe == "AltKeysLite" || exe.hasPrefix("AltKeysLite_") {
        running.forceTerminate()
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let appDelegate = AppDelegate()
app.delegate = appDelegate
app.run()
