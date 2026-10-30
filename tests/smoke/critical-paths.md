# Smoke Test: Critical Paths

**Purpose**: Run these 10-15 checks in under 15 minutes before any QA hand-off.
**Run via**: `/smoke-check` (which reads this file)
**Update**: Add new entries when new core systems are implemented.

## Core Stability (always run)

1. Game launches to the first scene without crash (`godot --path . --windowed`, then look at it)
2. The genetics lab scene (FAZ 1) renders parents and offspring without errors in the log
3. Touch / mouse input does not freeze the scene

## Core Mechanic (update per sprint)

4. Crossing two seeds produces a child whose genes come from the parents (FAZ 1: `tests/unit/genetics/`)

## Data Integrity

5. Save game completes without error (once save system is implemented, FAZ 5)
6. Load game restores correct state (once load system is implemented, FAZ 5)

## Performance

7. No visible frame rate drops on target hardware (60fps target, once a budget is set in `project.yaml`)
8. No memory growth over 5 minutes of play (once core loop is implemented)
