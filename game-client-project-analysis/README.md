---
name: game-client-project-analysis
description: 从游戏类型、插件、Scene 关系、框架系统、常用 API 和可复用脚本组件等方面解释陌生的游戏引擎客户端项目。当需要熟悉 Unity/C# 或 Cocos Creator/TypeScript 项目，理解 Gameplay 代码的组织方式以及项目组件的使用方法时使用。
---

# 游戏客户端项目熟悉指南

## 目标

建立一个关于“游戏如何在引擎中运行”的实用心智模型。

重点关注：

- 游戏自身的定位；
- Scene 结构；
- 运行时系统；
- 框架代码；
- 可复用脚本组件。

不要把游戏项目当作 Web、后端、CLI 或普通应用程序项目来分析。

帮助刚接触项目的游戏客户端开发者回答：

- 这是什么类型的游戏：2D 还是 3D？属于什么玩法类型？核心 Gameplay 循环是什么？
- 项目实际使用了哪些插件或框架？它们各自在项目中发挥什么作用？
- 项目包含哪些 Scene？每个 Scene 的职责是什么？Scene 之间如何跳转或相互依赖？
- 哪些运行时系统构成了客户端框架？最常使用的方法是什么？
- 哪些脚本组件重要且可以复用？如何使用它们？什么 Gameplay 场景或 Scene 需要使用它们？

## 边界

按照项目当前真实存在的状态进行探索和解释。

默认指南中不要提供以下内容：

- 如何打开项目；
- 如何运行项目；
- 如何构建；
- 如何部署；
- CI；
- 测试步骤。

除非用户另外明确要求实现功能，否则不要修改代码。

只分析有项目证据支持的：

- 系统；
- 插件；
- Scene；
- 组件关系。

不要为了填满检查清单而补写游戏中不存在的系统。

如果游戏类型、运行时连接或序列化引用不确定，应明确标记，不要猜测。

## 工作流程

### 1. 识别游戏类型

检查：

- 项目文档；
- 引擎配置；
- Scene 名称与内容；
- Gameplay 脚本；
- 渲染组件；
- 物理系统的使用情况；
- 美术资源；
- 功能术语。

总结：

- 游戏引擎和引擎版本；
- 游戏是 2D、3D 还是混合表现形式，并提供证据；
- 可能的游戏类型，例如 RPG、卡牌、射击、策略、模拟、解谜、平台跳跃或混合类型；
- 项目中能够观察到的核心 Gameplay 循环；
- 只有证据充分时，才说明联网或离线、单人或多人、热更新等特征。

如果游戏类型是根据代码和资源模式判断，而不是由项目文档明确说明，应标记为：

`INFERRED`

通过以下位置发现插件：

- 依赖清单；
- Package；
- DLL；
- 插件目录；
- Assembly 引用；
- import；
- 初始化代码；
- 实际调用位置。

对于每个相关插件，解释：

- 它为这个游戏提供了什么能力；
- 它在哪里初始化或配置；
- 哪些项目系统使用它；
- 它只是存在于项目中，还是能够证明运行时代码确实使用了它。

不要编写通用插件教程。只解释插件在当前项目中的作用。

对于 Unity，检查：

- `ProjectVersion.txt`
- `Packages/manifest.json`
- `*.asmdef`
- `Assets/Plugins`
- 插件专属配置
- 真实 API 调用

仅在项目实际存在时识别以下依赖：

- Addressables
- YooAsset
- UniTask
- DOTween
- Zenject / VContainer
- UniRx / R3
- Cinemachine
- Input System
- HybridCLR
- ILRuntime
- Lua
- Odin
- MessagePipe
- DOTS

对于 Cocos Creator，检查：

- `package.json`
- 项目配置文件
- settings 文件
- extensions
- Asset Bundle
- 原生插件
- import
- 真实 API 调用

### 2. 绘制 Scene 地图

通过以下证据枚举项目自身的运行时 Scene：

- 引擎配置；
- Scene 资源；
- Scene 加载调用；
- Address 或 Bundle 配置；
- Scene 跳转控制器。

排除：

- 编辑器示例；
- 插件 Demo；
- 测试 Scene；
- 已废弃 Scene。

除非项目运行时确实使用它们。

对于每个 Scene，确定：

- 它在游戏中的职责，例如 Bootstrap、登录、大厅、世界、战斗、加载、角色选择或其他有证据支持的作用；
- Scene 如何进入，以及能够跳转到哪些 Scene；
- Scene 依赖哪些系统或持久对象；
- Scene 自己持有哪些重要 UI、Entity、Camera 或 Controller；
- Scene 切换时哪些内容会销毁、保留或带到下一个 Scene。

生成一张 Mermaid Scene 流程图。

使用项目中真实的 Scene 名称。如果能够确定跳转触发条件，则在图中标记。

对于 Unity，检查：

- `EditorBuildSettings.asset`
- `*.unity`
- `SceneManager` 调用
- Addressables 或 AssetBundle Scene 加载
- Bootstrap 钩子
- `DontDestroyOnLoad` 对象

对于 Cocos Creator，检查：

- 启动 Scene 配置
- `*.scene`
- `director.loadScene`
- Bundle
- 持久节点
- `.meta` UUID 关系

如果文本无法证明 Scene 或 Prefab 的序列化引用，标记为：

`UNKNOWN / NEED EDITOR INSPECTION`

### 3. 绘制游戏系统地图

根据以下信息识别完整且职责明确的运行时系统：

- 初始化方式；
- 所有权；
- 公共 API；
- 依赖关系；
- 重复使用情况。

只有一个文件夹或一个以 `Manager` 结尾的类，并不足以证明它构成了一个系统。

检查项目是否存在以下系统：

- UI；
- Scene 或状态；
- Resource 或 Asset；
- Object Pool；
- FSM 或状态机；
- Entity；
- Battle；
- Skill；
- Input；
- Camera；
- Animation；
- Audio；
- Event 或 Message；
- Network；
- Configuration；
- Player Data；
- Save；
- Timer 或 Tick；
- SDK 或 Platform；
- Hot Update。

只报告项目中实际存在的系统。

对于每个重要系统，解释：

- 它在这个游戏中的职责；
- 关键文件和核心类型；
- 谁创建、初始化或持有它；
- 哪些 Scene 和 Gameplay 功能使用它；
- 其他代码如何与它通信，例如直接调用、依赖注入、事件、回调、引擎生命周期或序列化组件连接；
- 根据真实调用位置找出 3–8 个经常使用的 public 方法；
- 开发者必须了解的生命周期、清理、资源释放或注册规则。

如果项目存在以下常见游戏框架系统，应重点分析。

#### UI 系统

识别：

- View 或 Panel 注册；
- `Open` / `Show`
- `Close` / `Hide`
- 参数传递；
- UI 层级；
- UI Prefab 加载；
- UI 释放。

追踪一条真实的 UI 打开调用。

#### 对象池系统

识别：

- 预加载；
- `Spawn` / `Get`
- `Despawn` / `Recycle` / `Release`
- 清空；
- 对象池所有权；
- 使用对象池的 Entity、特效或 Projectile 类型。

#### FSM 或状态机

识别：

- 状态注册；
- `Enter`
- `ChangeState`
- `Update` / `Tick`
- `Exit`
- 状态转换条件；
- 状态机所有者；
- 状态机控制的 Gameplay 对象。


#### Resource 系统

识别：

- 加载；
- 缓存或引用；
- 实例化；
- 卸载或释放；
- 所有权规则。

#### Event 系统

识别：

- 订阅；
- 发布或分发；
- 取消订阅；
- 监听器生命周期；
- 有代表性的发布者和订阅者。

优先列出 Gameplay 功能代码反复调用的方法。

不要列出所有 public 方法，也不要仅根据方法名称推断使用情况。

### 4. 解释重要脚本组件

寻找以下类型的组件：

- 挂载在重要 Scene 对象或 Node 上；
- 挂载在重要 Prefab 上；
- 被多个功能复用；
- 控制引擎生命周期；
- 提供通用 Gameplay 行为。

对于每个重要组件，解释：

- 脚本路径和引擎基类；
- 通常由哪个 GameObject、Node、Prefab 或 Scene 持有；
- 它解决什么 Gameplay 问题；
- 开发者应该在什么情况下使用它；
- 什么情况下不需要使用它；
- 根据项目现有示例说明如何挂载、获取、配置或调用它；
- 重要的序列化字段或 `@property` 字段；
- 经常调用的方法、事件或回调；
- 初始化顺序和生命周期；
- 依赖的系统、同级组件、资源或数据；
- 一个真实使用位置。

对于 Unity，优先分析：

- 有实际意义的 `MonoBehaviour`
- `ScriptableObject`
- 会改变运行时设置的自定义 Inspector 或 Attribute
- 可复用的 Prefab Component

只在相关时追踪：

- `Awake`
- `OnEnable`
- `Start`
- `Update`
- `OnDisable`
- `OnDestroy`

对于 Cocos Creator，优先分析：

- `@ccclass` Component
- `@property` 绑定
- Node 或 Prefab 所有权

只在相关时追踪：

- `onLoad`
- `onEnable`
- `start`
- `update`
- `onDisable`
- `onDestroy`

不能仅仅因为组件是 public，就将其描述为可复用组件。

必须通过实际挂载关系或调用位置确认。

如果无法通过文本证明序列化所有权，应明确说明。

### 5. 追踪一条核心 Gameplay 流程

选择一条最能连接游戏 Scene、系统和组件的流程。

优先选择：

- 游戏核心循环；
- 进入战斗；
- 生成玩家；
- 释放技能；
- 打出卡牌；
- 打开背包；
- 从对象池创建 Projectile。

只能选择项目中实际存在的流程。

按照以下结构追踪：

`Scene 或引擎事件 -> 根 Controller 或 Component -> 游戏系统 -> Data、Resource 或 Event -> Gameplay 或 UI 结果`

使用项目中真实的符号，并引用重要文件。

保持流程简洁。它的目的，是展示框架代码和脚本组件如何协作。

### 6. 推荐游戏代码阅读顺序

推荐一条围绕运行时理解的简短阅读路径：

1. Scene 列表和 Scene 跳转控制器。
2. 持久化 Bootstrap 或框架根节点。
3. 跨 Scene 使用的核心系统。
4. 重要的可复用脚本组件。
5. 一条从入口到结果的代表性 Gameplay 功能。

列出具体文件，并解释每个文件能够帮助开发者理解什么。

不要只按照目录顺序排列文件。

## 证据规则

如果能够获得行号，为重要结论添加：

`relative/path:line`

否则使用：

`relative/path`

优先提供少量但具有决定性的引用。

使用以下标签：

- `CONFIRMED`：具有直接的代码、配置或序列化资源证据。
- `INFERRED`：由多项线索共同支持的结论。
- `UNKNOWN / NEED VERIFICATION`：仓库证据不足。
- `UNKNOWN / NEED EDITOR INSPECTION`：无法解析的引擎编辑器或序列化关系。

在运行时代码、配置或资源确认其作用之前，将以下内容视为线索：

- 名称；
- 文件夹；
- README 描述；
- 已安装的 Package；
- 注释。

## 默认输出格式

# 游戏客户端项目指南

## 1. 游戏总结

说明：

- 引擎及版本；
- 2D、3D 或混合表现形式；
- 游戏类型；
- 核心 Gameplay 循环；
- 其他能够定义这个游戏的特征。

标记通过推断得出的特征。

### 插件与框架

| 插件 | 在本游戏中的作用 | 初始化或配置位置 | 使用方 | 证据 |
|---|---|---|---|---|

## 2. Scene 地图

提供一张 Mermaid Scene 流程图。

| Scene | 作用 | 根脚本或组件 | 从哪里进入 | 跳转到哪里 | 持久依赖 |
|---|---|---|---|---|---|

## 3. 游戏系统框架

提供一张简洁的系统关系图。

| 系统 | 职责 | 所有者或初始化位置 | 主要使用方 | 常用方法 |
|---|---|---|---|---|

展开说明重要系统的：

- 生命周期；
- 使用规则。

如果项目实际存在，应详细说明以下系统的 API：

- UI；
- 对象池；
- FSM；
- Resource；
- Scene；
- Event。

## 4. 重要脚本组件

| 组件 | 挂载位置或所有者 | 作用 | 什么时候使用 | 常用方法 |
|---|---|---|---|---|

对于最实用的组件，进一步解释：

- 配置；
- 依赖；
- 生命周期；
- 一个真实使用示例。

## 5. 一条核心 Gameplay 流程

提供一条简洁的调用链或时序图，连接：

- Scene；
- 游戏系统；
- 脚本组件。

## 6. 推荐阅读顺序

按照依赖关系列出具体的：

- Scene 文件；
- 框架文件；
- 系统文件；
- 组件文件；
- Gameplay 文件。

## 7. 未知事项或需要编辑器检查的内容

只列出会实质性影响以下心智模型的不确定性：

- Scene；
- 系统；
- 组件。

保持指南篇幅与项目规模相称。

相比穷尽式文件覆盖，优先帮助开发者理解：

- 框架；
- 组件；
- Scene 图；
- 核心系统；
- 常用 API；
- 可复用组件；
- 一条代表性的 Gameplay 流程。

当开发者已经理解这些内容时，应停止继续扩大分析。
