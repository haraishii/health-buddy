"""Combine lib/ into a single file for DartPad (dartpad.dev).

Run: python3 tool/make_dartpad.py  ->  dartpad_main.dart
"""
import pathlib, re, sys

root = pathlib.Path(__file__).resolve().parent.parent
order = [
    "theme.dart", "widgets/common.dart", "widgets/charts.dart", "widgets/animated.dart",
    "screens/log_exercise_screen.dart", "screens/scan_meal_screen.dart", "screens/stress_check_screen.dart",
    "screens/home_screen.dart", "screens/analytics_screen.dart", "screens/ai_coach_screen.dart",
    "screens/food_screen.dart", "screens/profile_screen.dart", "main.dart",
]
imports, bodies = [], []
for rel in order:
    text = (root / "lib" / rel).read_text()
    out = []
    for line in text.splitlines():
        m = re.match(r"^import '([^']+)'( as \w+)?;$", line)
        if m:
            target = m.group(1)
            if target.startswith("package:flutter") or target.startswith("dart:"):
                if line not in imports:
                    imports.append(line)
            continue
        out.append(line)
    bodies.append(f"// ───────────── {rel} ─────────────\n" + "\n".join(out).strip() + "\n")

src = "\n".join(bodies)
font_block = re.compile(r"  // FONT_START.*?// FONT_END\n", re.S)
dartpad_font = (
    "  // DartPad: Figtree font is loaded from Google Fonts.\n"
    "  final base = ThemeData(\n"
    "    useMaterial3: true,\n"
    "    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.green, surface: AppColors.bg),\n"
    "    scaffoldBackgroundColor: AppColors.bg,\n"
    "  );\n"
    "  final textTheme = GoogleFonts.figtreeTextTheme(base.textTheme);\n"
)
src, n = font_block.subn(dartpad_font, src)
if n != 1:
    sys.exit("FONT block not found")
imports.append("import 'package:google_fonts/google_fonts.dart';")

# Private names must stay unique after merging.
names = re.findall(r"^(?:class|enum|mixin|const|final)\s+(_\w+)", src, re.M)
names += re.findall(r"^\w[\w<>, ]*\s+(_\w+)\(", src, re.M)
dupes = {n for n in names if names.count(n) > 1}
if dupes:
    sys.exit(f"Duplicate private names: {dupes}")

header = "// Health Buddy - UI prototype (single-file version for DartPad).\n// Generated from lib/ by tool/make_dartpad.py.\n\n"
(root / "dartpad_main.dart").write_text(header + "\n".join(sorted(imports, key=lambda s: (not s.startswith("import 'dart:"), s))) + "\n\n" + src)
print("ok", len(src.splitlines()), "lines")
