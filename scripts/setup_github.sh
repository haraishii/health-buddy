#!/usr/bin/env bash
# Creates the initial Health Buddy labels, milestones and issues on GitHub.
#
# Requires the GitHub CLI (https://cli.github.com), logged in with: gh auth login
# Run from inside the repo folder after it has been pushed to GitHub:
#   ERWIN_GH=usernameErwin TERESA_GH=usernameTeresa FADHIL_GH=usernameFadhil bash scripts/setup_github.sh
# The *_GH variables are optional; when set, issues are assigned right away.
# Safe to run again: anything that already exists is skipped.
set -euo pipefail

REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
echo "Repo: $REPO"

echo "== Labels =="
gh label create erwin --color 16A34A --description 'Erwin · lead & foundation' --force >/dev/null && echo "  erwin"
gh label create teresa --color 2563EB --description 'Teresa · data & charts' --force >/dev/null && echo "  teresa"
gh label create fadhil --color 7C3AED --description 'Fadhil · interaction & animation' --force >/dev/null && echo "  fadhil"
gh label create task --color 0E8A16 --description 'Work from the timeline' --force >/dev/null && echo "  task"
gh label create bug --color D73A4A --description 'Something is broken' --force >/dev/null && echo "  bug"
gh label create design --color F59E0B --description 'Needs a check against the mockup' --force >/dev/null && echo "  design"
gh label create blocked --color 6B7280 --description 'Waiting on other work' --force >/dev/null && echo "  blocked"
gh label create phase-2 --color BFD4F2 --description 'Out of scope for the hardcoded version' --force >/dev/null && echo "  phase-2"

echo "== Milestones =="
make_milestone() {
  local title="$1" due="$2" desc="$3"
  if gh api "repos/$REPO/milestones?state=all&per_page=100" -q ".[].title" | grep -Fxq "$title"; then
    echo "  (exists) $title"
  else
    gh api "repos/$REPO/milestones" -f title="$title" -f due_on="$due" -f description="$desc" >/dev/null
    echo "  $title"
  fi
}
make_milestone 'M1 · Foundation' 2026-10-09T23:59:59Z 'App runs on a phone: correct theme & font, 5-tab bar, base components ready.'
make_milestone 'M2 · Core screens' 2026-10-16T23:59:59Z 'Home, Analytics and AI Coach complete with dummy data.'
make_milestone 'M3 · All screens' 2026-10-23T23:59:59Z 'All 8 screens complete and every navigation button connected.'
make_milestone 'M4 · Release' 2026-10-30T23:59:59Z 'APK ready to share; logged data updates Home & Analytics.'

echo "== Issues =="
make_issue() {
  local title="$1" label="$2" milestone="$3" assignee="$4" body="$5"
  if gh issue list --state all --limit 200 --json title -q ".[].title" | grep -Fxq "$title"; then
    echo "  (exists) $title"; return
  fi
  local args=(--title "$title" --label "task,$label" --milestone "$milestone" --body "$body")
  if [ -n "$assignee" ]; then args+=(--assignee "$assignee"); fi
  gh issue create "${args[@]}" >/dev/null
  echo "  $title"
}
make_issue '[Erwin] Create Git repo, Flutter project, folder structure (screens/, widgets/, data/, theme.dart)' erwin 'M1 · Foundation' "${ERWIN_GH:-}" '**Owner:** Erwin
**Estimate:** 1 working day
**Week:** 1

### Done when
- Everyone can clone and run the app on their own phone.
'
make_issue '[Erwin] Theme: colors, Figtree font, text styles, motion curves' erwin 'M1 · Foundation' "${ERWIN_GH:-}" '**Owner:** Erwin
**Estimate:** 1 working day
**Week:** 1

### Done when
- Colors & font match the mockup; used through AppColors and ts().
'
make_issue '[Erwin] Shared components: AppCard, buttons, ProgressBar, toast, back header' erwin 'M1 · Foundation' "${ERWIN_GH:-}" '**Owner:** Erwin
**Estimate:** 2 working days
**Week:** 1

### Done when
- Reused on every screen, with examples on a test page.
'
make_issue '[Erwin] 5-tab bar + tab switching + push transition' erwin 'M1 · Foundation' "${ERWIN_GH:-}" '**Owner:** Erwin
**Estimate:** 1 working day
**Week:** 1

### Done when
- Tabs switch with a 220 ms crossfade; pushed screens slide in from the right.
'
make_issue '[Teresa] Data models: User, Goal, HealthScore, Meal, Exercise, StressLog, ChatMessage' teresa 'M1 · Foundation' "${TERESA_GH:-}" '**Owner:** Teresa
**Estimate:** 1 working day
**Week:** 1

### Done when
- Simple Dart classes, no backend.
'
make_issue '[Teresa] dummy_data.dart with all sample numbers from the mockup' teresa 'M1 · Foundation' "${TERESA_GH:-}" '**Owner:** Teresa
**Estimate:** 1 working day
**Week:** 1

### Done when
- No numbers are hardcoded in screens; everything comes from this file.
'
make_issue '[Teresa] Chart widgets: score ring, line, bar, radar' teresa 'M1 · Foundation' "${TERESA_GH:-}" '**Owner:** Teresa
**Estimate:** 3 working days
**Week:** 1

### Done when
- Take data as input, animate on appear, not clipped on a 360 px phone.
'
make_issue '[Fadhil] Base animation widgets: FadeUp (staggered entrance), PressScale (press effect)' fadhil 'M1 · Foundation' "${FADHIL_GH:-}" '**Owner:** Fadhil
**Estimate:** 2 working days
**Week:** 1

### Done when
- Used in Erwin'"'"'s components; switch off automatically when "reduce motion" is on.
'
make_issue '[Fadhil] Robot mascot (floating & blinking) + "typing" dots' fadhil 'M1 · Foundation' "${FADHIL_GH:-}" '**Owner:** Fadhil
**Estimate:** 2 working days
**Week:** 1

### Done when
- Looping animations without making the phone hot or laggy.
'
make_issue '[Erwin] Home: greeting, Health Score card, daily goals, quick log, AI Coach tip' erwin 'M2 · Core screens' "${ERWIN_GH:-}" '**Owner:** Erwin
**Estimate:** 5 working days
**Week:** 2

### Done when
- Matches the mockup; +250 ml increases water; quick log opens the right screens.
'
make_issue '[Teresa] Analytics: score trend, Balance (radar), Nutrition, Stress, Exercise, AI Insights, Trends' teresa 'M2 · Core screens' "${TERESA_GH:-}" '**Owner:** Teresa
**Estimate:** 4 working days
**Week:** 2

### Done when
- All charts use dummy data; the week picker shows (it may not change data yet).
'
make_issue '[Fadhil] AI Coach: mascot card, today summary, 4 quick questions, chat, input field' fadhil 'M2 · Core screens' "${FADHIL_GH:-}" '**Owner:** Fadhil
**Estimate:** 5 working days
**Week:** 2

### Done when
- Tapping a question shows the message, typing dots, then a template answer; the "not medical advice" note is visible.
'
make_issue '[Erwin] Profile: personal info, daily goals, connected data, settings toggles' erwin 'M3 · All screens' "${ERWIN_GH:-}" '**Owner:** Erwin
**Estimate:** 3 working days
**Week:** 3

### Done when
- Toggles switch on and off; other buttons show a "coming soon" toast.
'
make_issue '[Erwin] Wire up all quick actions on Home, AI Coach and Food' erwin 'M3 · All screens' "${ERWIN_GH:-}" '**Owner:** Erwin
**Estimate:** 2 working days
**Week:** 3

### Done when
- No button does nothing when tapped.
'
make_issue '[Teresa] Food: calorie ring, macros, Scan Meal button, meal list, add meal' teresa 'M3 · All screens' "${TERESA_GH:-}" '**Owner:** Teresa
**Estimate:** 3 working days
**Week:** 3

### Done when
- Total calories are calculated from the meal list in dummy data.
'
make_issue '[Teresa] Scan Meal: Photo/Barcode/Search modes, scan line, result bottom sheet' teresa 'M3 · All screens' "${TERESA_GH:-}" '**Owner:** Teresa
**Estimate:** 3 working days
**Week:** 3

### Done when
- Scan result is a fixed sample; Search mode can pick from a popular foods list.
'
make_issue '[Fadhil] Stress Check: 1–10 scale, changing face, factor chips, breathing exercise' fadhil 'M3 · All screens' "${FADHIL_GH:-}" '**Owner:** Fadhil
**Estimate:** 3 working days
**Week:** 3

### Done when
- Breathing circle 4 s in / 4 s out; Save returns to the previous screen + toast.
'
make_issue '[Fadhil] Log Exercise: activity type, duration, intensity, calorie estimate' fadhil 'M3 · All screens' "${FADHIL_GH:-}" '**Owner:** Fadhil
**Estimate:** 3 working days
**Week:** 3

### Done when
- Calories update when options change; Save returns + toast.
'
make_issue '[Erwin] Merge all branches, fix bugs, clean up code' erwin 'M4 · Release' "${ERWIN_GH:-}" '**Owner:** Erwin
**Estimate:** 3 working days
**Week:** 4

### Done when
- No errors in flutter analyze; no screen overflows.
'
make_issue '[Erwin] Release APK build, app icon & name, install README' erwin 'M4 · Release' "${ERWIN_GH:-}" '**Owner:** Erwin
**Estimate:** 2 working days
**Week:** 4

### Done when
- The APK installs on Android phones other than the developers'"'"' own.
'
make_issue '[Teresa] In-memory state: Log Exercise / Stress / Food results update Home & Analytics' teresa 'M4 · Release' "${TERESA_GH:-}" '**Owner:** Teresa
**Estimate:** 3 working days
**Week:** 4

### Done when
- Numbers update while the app is open (resetting on close is expected in the hardcoded version).
'
make_issue '[Teresa] Test all screens & fix own bugs' teresa 'M4 · Release' "${TERESA_GH:-}" '**Owner:** Teresa
**Estimate:** 2 working days
**Week:** 4

### Done when
- All bugs from the M3 demo are closed.
'
make_issue '[Fadhil] Polish animations per the Animation Flow board + reduce motion support' fadhil 'M4 · Release' "${FADHIL_GH:-}" '**Owner:** Fadhil
**Estimate:** 3 working days
**Week:** 4

### Done when
- Durations & curves match the spec table.
'
make_issue '[Fadhil] Test on 3 phone sizes (small 360 px, medium, large) + log bugs' fadhil 'M4 · Release' "${FADHIL_GH:-}" '**Owner:** Fadhil
**Estimate:** 2 working days
**Week:** 4

### Done when
- No clipped text; touch targets at least 44 px.
'

echo
echo "Done. Next steps (manual, one time):"
echo "  1. Create the Projects board: Projects tab > New project > Board, then add all issues."
echo "  2. Protect the main branch: Settings > Branches > Add rule (see docs/SETUP_GITHUB.md)."
