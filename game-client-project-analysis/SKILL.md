---
name: game-client-project-analysis
description: Quickly onboard developers to unfamiliar game-client repositories by finding how to run them, the essential architecture, key files, and one feature path. Use with newly cloned open-source or inherited company projects, especially Unity/C# and Cocos Creator/TypeScript, before making the first safe change.
---

# Game Client Project Onboarding

## Goal

Build the smallest accurate mental model that lets a developer start useful work in an unfamiliar game-client repository. Optimize for time-to-first-change, not architectural completeness.

Stop when the developer can answer:

- How do I open, run, build, and verify the project?
- Where does execution start, and what is the short startup path?
- Which 3–6 modules matter first?
- Which 5–10 files should I read now?
- How does one representative feature work end to end?
- Where would my first task likely change code, and how would I verify it?

## Scope

Start from the user's goal. When a concrete task is supplied, organize onboarding around that task and the nearest existing implementation. Otherwise choose one representative path that reveals the project structure.

Explore read-only by default. Do not edit code merely because the user asked to understand or onboard to the project. When the user explicitly asks to implement a task, use the onboarding findings to proceed without repeating a repository-wide analysis.

Avoid exhaustive architecture audits, generic framework tutorials, code-quality reviews, redesign advice, and file-by-file inventories. Expand only when missing context blocks the next development step.

## Workflow

### 1. Establish the Project Baseline

Scan the root, README, contribution notes, manifests, lockfiles, project settings, build scripts, CI, and top-level source layout. Prefer `rg --files` and targeted `rg` searches; skip generated, build, cache, and vendor-heavy directories.

Identify:

- engine, engine version, language, major dependencies, and repository shape;
- required editor or toolchain version;
- documented open, setup, run, build, and test commands;
- generated code, vendored code, submodules, large assets, and local configuration that should not be edited casually;
- current blockers such as missing documentation, dependencies, secrets, assets, or platform tooling.

Do not run dependency installers or untrusted repository scripts solely for orientation. If the user asked to set up or run the project, inspect the command first, explain material side effects, and execute only within that authority.

For Unity, prioritize `ProjectSettings/ProjectVersion.txt`, `Packages/manifest.json`, `EditorBuildSettings.asset`, assembly definitions, the first enabled Scene, bootstrap code, and `RuntimeInitializeOnLoadMethod` or root `MonoBehaviour` hooks.

For Cocos Creator, prioritize `package.json`, `tsconfig.json`, project/settings files, the startup Scene, bootstrap `Component`, `onLoad`/`start`, and relevant `.scene`, `.prefab`, and `.meta` links. Mark unresolved serialized references `UNKNOWN / NEED EDITOR INSPECTION`.

For other game clients, find the equivalent version manifest, build entry, scene/state root, lifecycle hooks, and asset pipeline.

### 2. Build the Minimum Architecture Map

Trace only the critical spine:

`Engine Entry -> Bootstrap/Composition Root -> Core Services -> First Main State or Target Feature`

Identify 3–6 modules from responsibility, public API, initialization, and dependency boundaries rather than folder names. For each, capture one sentence of responsibility, its entry file or type, and its main dependencies.

Create one Mermaid diagram with no more than about 10 nodes. Use real project symbols. Label direct calls, DI, events, async responses, engine lifecycle, or serialized connections only where the distinction helps the developer act.

### 3. Follow One Real Feature

When the user has a task, find the closest existing feature and trace that path. Otherwise select one path that crosses useful layers, such as startup to main UI, opening a screen, loading an asset, or completing a network-backed action.

Trace:

- the user, engine, or message entry;
- controller/system/component orchestration;
- data, network, resource, event, or scene dependencies actually involved;
- visible result and error path when present;
- lifecycle, registration, ownership, and cleanup rules that affect changes.

Show a compact call chain or sequence diagram and cite one real usage example. Never invent missing callers, serialized wiring, or runtime order.

### 4. Extract Development Conventions

Read two or three nearby, representative implementations instead of searching the whole repository. Derive only conventions needed for the next change:

- where a new or changed feature is registered and initialized;
- how dependencies are obtained;
- how async work, errors, events, and lifecycle cleanup are handled;
- how UI, assets, scenes, protocols, or configuration are named and referenced;
- which files are generated and what source or generator owns them;
- where tests or practical verification live.

Distinguish a repeated convention from a one-off example. Do not turn stylistic observations into mandatory rules without evidence.

### 5. Prepare the First Development Move

If a concrete task is known, identify likely change points, an implementation order, adjacent examples to copy, and the smallest relevant verification. Treat these as a task map, not permission to edit.

If no task is known, provide a development-ready reading order and explain what each file unlocks. Do not manufacture a feature request merely to complete the report.

## Evidence Rules

Attach `relative/path:line` to important claims when line information is available, otherwise use `relative/path`. Prefer a few strong citations over a wall of references.

Use these labels when uncertainty affects the next action:

- `CONFIRMED`: directly supported by code or configuration.
- `INFERRED`: supported by multiple clues; explain the inference.
- `UNKNOWN / NEED VERIFICATION`: unavailable from the repository evidence.
- `UNKNOWN / NEED EDITOR INSPECTION`: serialized or editor-only state cannot be resolved safely from text.

Treat README text, names, comments, and directory structure as leads until code or configuration confirms them. Distinguish installed dependencies from dependencies actually used by the runtime.

## Default Output

```markdown
# Project Onboarding Brief

## 1. Start Here
Explain what the project is, its engine/version, whether the available evidence is sufficient, and the first file to open.

## 2. Open, Run, and Verify
List confirmed tool versions and commands. Separate documented commands from inferred ones and name blockers without guessing secrets or missing assets.

## 3. Minimal Mental Model
Show one compact Mermaid diagram and a 3–6 row module table:
| Module | Responsibility | Entry | Depends On |

## 4. Essential Files
Give a dependency-aware reading order of roughly 5–10 files. Explain in one sentence what each file unlocks.

## 5. One Feature, End to End
Trace one real feature with a compact call chain or sequence diagram, key files, lifecycle constraints, and a real usage example.

## 6. How to Make the First Change
For a known task, list likely change points, an adjacent example, implementation order, and verification. Without a task, summarize project conventions that make the next ticket easier.

## 7. Unknowns and Blockers
List only uncertainties that affect running the project or making the first change, plus the cheapest next verification.
```

Keep the report proportional. For a small repository, a few paragraphs may be enough. For a task-specific request, omit unrelated modules and make the target feature the center of the map.

## Stop Conditions

Stop exploring when the run/build path, critical spine, essential files, one feature path, and next development move are clear enough to act on. Do not keep reading merely to make the report look comprehensive.

Before responding, verify that every section reduces time-to-first-change, important claims have evidence, unknowns are explicit, and no analysis-only request has been treated as permission to modify code.
