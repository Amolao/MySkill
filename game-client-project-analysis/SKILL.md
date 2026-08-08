---
name: game-client-project-analysis
description: Explain unfamiliar game-engine client projects through their game type, plugins, Scene relationships, framework systems, common APIs, and reusable script components. Use when onboarding to Unity/C# or Cocos Creator/TypeScript projects to understand how gameplay code is organized and how project components are used.
---

# Game Client Project Familiarization

## Goal

Build a practical mental model of a game running inside its engine. Focus on the game's identity, Scene structure, runtime systems, framework code, and reusable script components. Do not treat the repository like a web, backend, CLI, or generic application project.

Enable a new game-client developer to answer:

- What kind of game is this: 2D or 3D, and what genre or gameplay loop does it implement?
- Which plugins or frameworks does it actually use, and what role does each play here?
- Which Scenes exist, what does each Scene do, and how do they transition or depend on one another?
- Which runtime systems form the client framework, and which methods are used most often?
- Which script components are important and reusable, how are they used, and in which gameplay situations or Scenes are they needed?

## Boundaries

Explore and explain the project as it exists. Do not provide open, run, build, deployment, CI, or test instructions in the default guide. Do not modify code unless the user separately asks for implementation.

Analyze only systems, plugins, Scenes, and component relationships supported by project evidence. Do not fill a checklist with systems the game does not contain. Mark uncertain genre, runtime wiring, or serialized references instead of guessing.

## Workflow

### 1. Identify the Game

Inspect project documentation, engine configuration, Scene names and contents, gameplay scripts, rendering components, physics usage, art assets, and feature terminology. Summarize:

- engine and engine version;
- 2D, 3D, or hybrid presentation, with evidence;
- likely genre such as RPG, card, shooter, strategy, simulation, puzzle, platformer, or mixed genre;
- the core gameplay loop visible in the project;
- online/offline, single-player/multiplayer, and hot-update characteristics only when evidenced.

Label the genre `INFERRED` when it comes from code and asset patterns rather than explicit project documentation.

Discover plugins through manifests, packages, DLLs, plugin directories, assembly references, imports, initialization code, and call sites. For every relevant plugin, explain:

- what capability it provides to this game;
- where it is initialized or configured;
- which project systems use it;
- whether it is merely present or demonstrably used at runtime.

Do not give a generic plugin tutorial. Explain its role in this project.

For Unity, inspect `ProjectVersion.txt`, `Packages/manifest.json`, `*.asmdef`, `Assets/Plugins`, package-specific settings, and real API calls. Recognize dependencies such as Addressables, YooAsset, UniTask, DOTween, Zenject/VContainer, UniRx/R3, Cinemachine, Input System, HybridCLR, ILRuntime, Lua, Odin, MessagePipe, and DOTS only when present.

For Cocos Creator, inspect `package.json`, project/settings files, extensions, asset bundles, native plugins, imports, and real API calls.

### 2. Map the Scenes

Enumerate project-owned runtime Scenes from engine configuration, Scene assets, loading calls, address/bundle configuration, and transition controllers. Exclude editor samples, plugin demos, tests, and abandoned Scenes unless the project uses them.

For each Scene, determine:

- purpose in the game: bootstrap, login, lobby, world, battle, loading, character selection, or another evidenced role;
- root objects/nodes and the scripts that establish the Scene;
- how the Scene is entered and what it can transition to;
- systems or persistent objects it expects to exist;
- important Scene-owned UI, entities, cameras, or controllers;
- what is destroyed, retained, or carried across the transition.

Produce a Mermaid Scene flow. Use actual Scene names and label transition triggers when known.

For Unity, inspect `EditorBuildSettings.asset`, `*.unity`, `SceneManager` calls, Addressable or asset-bundle Scene loads, bootstrap hooks, and `DontDestroyOnLoad` objects.

For Cocos Creator, inspect the startup Scene setting, `*.scene`, `director.loadScene`, bundles, persistent nodes, and `.meta` UUID links.

If text cannot prove a serialized Scene/Prefab reference, mark it `UNKNOWN / NEED EDITOR INSPECTION`.

### 3. Map the Game Systems

Identify cohesive runtime systems from initialization, ownership, public APIs, dependencies, and repeated use. A folder or a class ending in `Manager` is not sufficient evidence by itself.

Check for systems such as UI, Scene/state, resource/asset, object pool, FSM/state machine, entity, battle, skill, input, camera, animation, audio, event/message, network, configuration, player data, save, timer/tick, SDK/platform, and hot update. Report only those that exist.

For each important system, explain:

- responsibility in this game;
- key files and central types;
- who creates, initializes, or owns it;
- which Scenes and gameplay features use it;
- how other code communicates with it: direct call, DI, event, callback, engine lifecycle, or serialized component link;
- 3–8 frequently used public methods, based on real call sites;
- lifecycle, cleanup, resource release, or registration rules that developers must know.

Give extra attention to these common game-framework systems when present:

- **UI:** identify view/panel registration, `Open`/`Show`, `Close`/`Hide`, parameter passing, layers, UI prefab loading, and release. Trace one real UI opening call.
- **Object pool:** identify preload, `Spawn`/`Get`, `Despawn`/`Recycle`/`Release`, clearing, pool ownership, and the entity/effect/projectile types that use it.
- **FSM/state machine:** identify state registration, `Enter`, `ChangeState`, `Update/Tick`, `Exit`, transition conditions, state owner, and the gameplay object controlled by the machine.
- **Scene system:** identify Scene registration/loading/switching and how framework services survive or reset between Scenes.
- **Resource system:** identify load, cache/reference, instantiate, unload/release, and ownership rules.
- **Event system:** identify subscribe, publish/dispatch, unsubscribe, listener lifetime, and representative publishers/subscribers.

Prefer methods that feature code calls repeatedly. Do not list every public method or infer usage from method names alone.

### 4. Explain Important Script Components

Find components that are attached to important Scene objects/Nodes or Prefabs, reused by multiple features, control engine lifecycle, or expose common gameplay behavior.

For each important component, explain:

- script path and engine base type;
- what GameObject/Node/Prefab or Scene normally owns it;
- what gameplay problem it solves;
- when a developer should use it and when it is not needed;
- how to attach, obtain, configure, or call it according to existing project examples;
- important serialized properties or `@property` fields;
- commonly called methods, events, or callbacks;
- initialization and lifecycle order;
- required systems, sibling components, assets, or data;
- one real usage location.

For Unity, prioritize meaningful `MonoBehaviour`, `ScriptableObject`, custom inspectors/attributes that change runtime setup, and reusable Prefab components. Trace `Awake`, `OnEnable`, `Start`, `Update`, `OnDisable`, and `OnDestroy` only when relevant.

For Cocos Creator, prioritize `@ccclass` Components, `@property` bindings, Node/Prefab ownership, and `onLoad`, `onEnable`, `start`, `update`, `onDisable`, and `onDestroy` only when relevant.

Do not describe a component as reusable merely because it is public. Verify actual attachment or call sites. If serialized ownership cannot be proven from text, say so.

### 5. Trace One Core Gameplay Flow

Choose one flow that best connects the game's Scenes, systems, and components. Prefer the core loop or a representative action such as entering battle, spawning a player, casting a skill, playing a card, opening an inventory, or creating a pooled projectile when that flow actually exists.

Trace:

`Scene/Engine Event -> Root Controller or Component -> Game System -> Data/Resource/Event -> Gameplay or UI Result`

Use real project symbols and cite the important files. Keep the flow compact; its purpose is to show how framework code and script components cooperate.

### 6. Recommend a Game-Code Reading Order

Recommend a short reading path centered on runtime understanding:

1. Scene list and Scene transition controller.
2. Persistent bootstrap/framework root.
3. Core systems used across Scenes.
4. Important reusable script components.
5. One representative gameplay feature from entry to result.

Name concrete files and explain what each unlocks. Do not order files by directory alone.

## Evidence Rules

Attach `relative/path:line` to important claims when available, otherwise use `relative/path`. Prefer a few decisive citations.

Use:

- `CONFIRMED` for direct code, configuration, or serialized-asset evidence;
- `INFERRED` for conclusions supported by multiple clues;
- `UNKNOWN / NEED VERIFICATION` when repository evidence is insufficient;
- `UNKNOWN / NEED EDITOR INSPECTION` for unresolved engine-editor or serialized relationships.

Treat names, folders, README statements, installed packages, and comments as leads until runtime code, configuration, or assets confirm their role.

## Default Output

```markdown
# Game Client Project Guide

## 1. Game Summary
State engine/version, 2D/3D/hybrid, genre, core gameplay loop, and other defining traits. Mark inferred traits.

### Plugins and Frameworks
| Plugin | Role in This Game | Initialized/Configured At | Used By | Evidence |

## 2. Scene Map
Show one Mermaid Scene flow.
| Scene | Purpose | Root Scripts/Components | Entered From | Leads To | Persistent Dependencies |

## 3. Game-System Framework
Show one compact system relationship diagram.
| System | Responsibility | Owner/Initialization | Main Users | Frequently Used Methods |
Expand important systems with lifecycle and usage rules. Detail UI, pool, FSM, resource, Scene, or event APIs when present.

## 4. Important Script Components
| Component | Attached/Owned By | What It Does | Use When | Common Methods |
Explain configuration, dependencies, lifecycle, and one real usage example for the most useful components.

## 5. One Core Gameplay Flow
Show a compact call chain or sequence diagram connecting a Scene, systems, and components.

## 6. Recommended Reading Order
List concrete Scene, framework, system, component, and gameplay files in dependency-aware order.

## 7. Unknown / Needs Editor Inspection
List only uncertainties that materially affect the Scene, system, or component mental model.
```

Keep the guide proportional to the project. Prefer framework and component knowledge over exhaustive file coverage. Stop when the developer understands the Scene graph, central systems, commonly used APIs, reusable components, and one representative gameplay path.
