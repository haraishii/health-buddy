# GitHub setup (one time, done by Erwin)

Estimated time: 30–45 minutes, on day one (Monday Oct 5).

## 1. Create the repo and push the code

1. On GitHub: **New repository** → name `health-buddy` → **Private** → leave README/.gitignore unchecked (they are already included).
2. On your laptop, from this folder (one time, Erwin only):
   ```bash
   flutter create --platforms=android,ios,web --org com.healthbuddy --project-name health_buddy .
   flutter analyze && flutter test
   dart format .            # format once so CI is green from the first commit
   git init -b main
   git add .
   git commit -m "chore: initial Health Buddy project + android, ios, web folders"
   git remote add origin https://github.com/<org-or-username>/health-buddy.git
   git push -u origin main
   ```

## 2. Invite the team

**Settings → Collaborators → Add people** → invite Teresa and Fadhil with the **Write** role.

Then replace `@erwin`, `@teresa` and `@fadhil` in `.github/CODEOWNERS` and `README.md` with their real GitHub usernames, commit and push.

## 3. Create labels, milestones and the 24 issues automatically

Install the [GitHub CLI](https://cli.github.com), log in once with `gh auth login`, then run:

```bash
ERWIN_GH=usernameErwin TERESA_GH=usernameTeresa FADHIL_GH=usernameFadhil bash scripts/setup_github.sh
```

This creates:

- **Labels:** `erwin`, `teresa`, `fadhil`, `task`, `bug`, `design`, `blocked`, `phase-2`
- **Milestones:** M1 (Oct 9), M2 (Oct 16), M3 (Oct 23), M4 (Oct 30)
- **24 issues** from the timeline PDF, with labels, milestones and assignees

The script is safe to run again: anything that already exists is skipped.

## 4. Create the Projects board

1. **Projects** tab → **New project** → **Board** template, name it "Health Buddy – October".
2. Columns: **To do**, **In progress**, **Review**, **Done**.
3. **Add item** → select all issues from the `health-buddy` repo.
4. (Optional) Add a **Roadmap** view grouped by milestone.
5. In the board's **Workflows**, turn on "Item closed → Done" and "Pull request merged → Done".

## 5. Protect the `main` branch

**Settings → Branches → Add branch ruleset** (or *Add rule*) for `main`:

- [x] Require a pull request before merging, **1 approval**
- [x] Require review from Code Owners
- [x] Require status checks to pass → select **Format, analyze, test**
- [x] Block force pushes

**Settings → General → Pull Requests:** allow only **Squash merging**, and tick **Automatically delete head branches**.

> Note: branch protection on a **private** repo needs GitHub Pro/Team. On a free account, make the repo **public** or agree on the rules manually.

## 6. Check

- [ ] **Actions** tab: the "Flutter CI" workflow is green for the first commit
- [ ] After pushing to `main`, the APK appears under **Artifacts** in the "Build APK" run
- [ ] Every teammate can `git clone`, `flutter pub get`, then `flutter run` (no `flutter create` needed)
- [ ] Links to the design canvas are added to `docs/README.md`
