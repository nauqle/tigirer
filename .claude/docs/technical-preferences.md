# Technical Preferences

<!-- project.yaml at the repo root is the machine-readable source of truth for
     engine, specialists, naming, performance, platform, and testing.framework.
     This file is the human-readable LEGACY FALLBACK: agents and skills resolve
     each key from project.yaml first and fall back here only when the
     project.yaml key is absent. /setup-engine dual-writes both.
     Forbidden patterns and allowed libraries are NOT migrated — they live only
     in this file. Populated by /setup-engine; updated as decisions are made. -->

## Engine & Language

- **Engine**: Godot 4.7.2
- **Language**: GDScript (fully statically typed — owner rule, see Forbidden Patterns)
- **Rendering**: Compatibility (OpenGL). Android 2D target; broadest device support; the only renderer verifiable in the cloud sandbox (no GPU)
- **Physics**: Godot Physics 2D

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: Mobile (Android)
- **Input Methods**: Touch
- **Primary Input**: Touch (swipe-to-harvest)
- **Gamepad Support**: None
- **Touch Support**: Full
- **Platform Notes**: Portrait only, 1080x1920 base, `stretch/aspect = keep_width` (tall phones get extra height, never extra width). No hover-only interactions; primary controls in thumb reach. The UI rule that asks for keyboard/mouse AND gamepad on every control does not apply to this mobile-only project (Gamepad Support: None).

## Naming Conventions

- **Classes**: PascalCase (e.g., `PlantGene`)
- **Variables**: snake_case for variables and functions (e.g., `growth_speed`)
- **Signals/Events**: snake_case past tense (e.g., `plant_harvested`)
- **Files**: snake_case matching the class (e.g., `plant_gene.gd`)
- **Scenes/Prefabs**: snake_case matching the file (e.g., `plant_instance.tscn`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_MUTATIONS`)

## Performance Budgets

- **Target Framerate**: [TO BE CONFIGURED]
- **Frame Budget**: [TO BE CONFIGURED]
- **Draw Calls**: [TO BE CONFIGURED]
- **Memory Ceiling**: [TO BE CONFIGURED]

## Testing

- **Framework**: gdUnit4 (`res://addons/gdUnit4/`), run with `commands.test` in `project.yaml`
- **Minimum Coverage**: [TO BE CONFIGURED]
- **Required Tests**: Balance formulas, gameplay systems, networking (if applicable)

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- Untyped variables, parameters or return values in GDScript. Every declaration is statically typed (`var health: float = 100.0`, `func calculate_yield() -> int:`). Owner rule.
- Cross-system node-to-node references. Systems talk through the `SignalBus` autoload; no `get_node("../../Other")` reaches across systems. Owner rule.
- Genetic, economy or growth numbers hardcoded in scripts. They live in `Resource` classes / `.tres` files. Owner rule (also `.claude/rules/gameplay-code.md`).

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- [None configured yet — add as dependencies are approved]

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]

## Engine Specialists

<!-- Written by /setup-engine when engine is configured. -->
<!-- Read by /code-review, /architecture-decision, /architecture-review, and team skills -->
<!-- to know which specialist to spawn for engine-specific validation. -->

- **Primary**: godot-specialist
- **Language/Code Specialist**: godot-gdscript-specialist (all .gd files)
- **Shader Specialist**: godot-shader-specialist (.gdshader files, VisualShader resources)
- **UI Specialist**: godot-specialist (no dedicated UI specialist — primary covers all UI)
- **Additional Specialists**: godot-gdextension-specialist (GDExtension / native C++ bindings only)
- **Routing Notes**: Invoke primary for architecture decisions, ADR validation, and cross-cutting code review. Invoke GDScript specialist for code quality, signal architecture, static typing enforcement, and GDScript idioms. Invoke shader specialist for material design and shader code. Invoke GDExtension specialist only when native extensions are involved.

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->
<!-- If a row says [TO BE CONFIGURED], fall back to Primary for that file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.gd files) | godot-gdscript-specialist |
| Shader / material files (.gdshader, VisualShader) | godot-shader-specialist |
| UI / screen files (Control nodes, CanvasLayer) | godot-specialist |
| Scene / prefab / level files (.tscn, .tres) | godot-specialist |
| Native extension / plugin files (.gdextension, C++) | godot-gdextension-specialist |
| General architecture review | Primary |
