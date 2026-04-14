---
name: snareshot
description: Record, verify, and browse SnareShot screenshot tests. Use when running snapshot tests, viewing gallery reports, or checking failure diffs. Triggered by /snareshot.
---

# SnareShot Skill

Run SnareShot screenshot tests and view reports.

## Commands

The user will invoke this skill with one of:
- `/snareshot record` -- record golden images
- `/snareshot verify` -- verify against golden images
- `/snareshot gallery` -- open the gallery report
- `/snareshot failures` -- open the failure report

## Behavior

### `/snareshot record`

1. Find the Xcode workspace or project in the current directory:
   ```bash
   ls *.xcworkspace *.xcodeproj 2>/dev/null
   ```
2. Find the test scheme:
   ```bash
   xcodebuild -list 2>/dev/null | grep -A 100 "Schemes:" | tail -n +2 | sed 's/^[[:space:]]*//'
   ```
3. Find the latest available iPhone simulator:
   ```bash
   xcrun simctl list devices available | grep "iPhone" | tail -1
   ```
4. Run the record command:
   ```bash
   SNARESHOT_RECORD=1 xcodebuild test -scheme <SCHEME> -destination 'platform=iOS Simulator,name=<SIMULATOR>' 2>&1
   ```
5. Find and open the gallery report:
   ```bash
   find . -name "gallery.html" -path "*__Snapshots__*" | head -1 | xargs open
   ```

### `/snareshot verify`

1. Same scheme and simulator detection as record.
2. Run without the env var:
   ```bash
   xcodebuild test -scheme <SCHEME> -destination 'platform=iOS Simulator,name=<SIMULATOR>' 2>&1
   ```
3. On success: open gallery. On failure: open failure report:
   ```bash
   find . -name "report.html" -path "*__Failures__*" | head -1 | xargs open
   ```

### `/snareshot gallery`

```bash
find . -name "gallery.html" -path "*__Snapshots__*" | head -1 | xargs open
```

### `/snareshot failures`

```bash
find . -name "report.html" -path "*__Failures__*" | head -1 | xargs open
```

## Device Override

If the user provides `--device "iPhone SE"`, use that simulator name instead of auto-detecting.

## Error Handling

- If xcodebuild fails with a build error (not a test failure), show the error output and do NOT attempt to open reports.
- If no workspace/project is found, tell the user to navigate to the project directory.
- If no simulator is available, tell the user to install one via Xcode.
