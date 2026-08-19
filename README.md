# AI 辅助开发资料库

这是一个面向 AI 辅助开发的个人资料库，主要收集 Codex Skill、游戏客户端项目分析规范、ChatGPT 网络排障工具，以及日常使用的高效提示词。

## 内容概览

| 目录/文件 | 简介 |
|---|---|
| `chatgpt-network-troubleshooter/` | ChatGPT 网页端和桌面端网络故障诊断 Skill，附带跨平台采证脚本。 |
| `game-client-project-analysis/` | 用于熟悉 Unity/C# 或 Cocos Creator/TypeScript 游戏客户端项目的分析 Skill。 |
| `prompt/` | 记录简单、可复用的 AI 提示词及其适用场景。 |
| `游戏客户端-AI输出代码规范.md` | 游戏客户端项目的 AI 代码生成规范模板，包含项目背景、指令优先级和命名约定。 |

## 文件目录

```text
my_skill/
├─ README.md
├─ 游戏客户端-AI输出代码规范.md
├─ chatgpt-network-troubleshooter/
│  ├─ README.md
│  ├─ SKILL.md
│  ├─ references/
│  │  └─ openai-domains.md
│  └─ scripts/
│     ├─ collect-chatgpt-network.ps1
│     ├─ collect-chatgpt-network.sh
│     ├─ test-chatgpt-connectivity.ps1
│     └─ test-chatgpt-connectivity.sh
├─ game-client-project-analysis/
│  ├─ SKILL.md
│  ├─ 技能（中文版）.md
│  └─ agents/
│     └─ openai.yaml
└─ prompt/
   └─ README.md
```

## 文件夹说明

### `chatgpt-network-troubleshooter/`

ChatGPT 网络故障排查 Skill。用于分析网页端或桌面端无法打开、无限加载、登录循环、TLS/证书错误、WebSocket 断连，以及代理、PAC、VPN、TUN、DNS、IPv4/IPv6 等网络路径问题。

- `SKILL.md`：Skill 的完整诊断流程、证据要求、修复原则和验证标准。
- `README.md`：该 Skill 的功能、目录和安全性说明。
- `references/`：网络排查时使用的参考资料。
- `references/openai-domains.md`：OpenAI/ChatGPT 相关域名、WebSocket 和 TLS 排查基线。
- `scripts/`：跨平台诊断脚本目录。
  - `collect-chatgpt-network.ps1`：Windows PowerShell 网络环境采集脚本。
  - `collect-chatgpt-network.sh`：macOS/Linux 网络环境采集脚本。
  - `test-chatgpt-connectivity.ps1`：Windows PowerShell 连通性测试脚本。
  - `test-chatgpt-connectivity.sh`：macOS/Linux 连通性测试脚本。

### `game-client-project-analysis/`

游戏客户端项目熟悉 Skill。用于从游戏类型、引擎、插件、Scene 关系、运行时系统、可复用脚本组件和核心 Gameplay 流程等方面，建立 Unity 或 Cocos Creator 项目的整体认知。

- `SKILL.md`：英文版 Skill 定义和分析工作流。
- `技能（中文版）.md`：中文版 Skill 定义，内容包括分析边界、证据规则和默认输出格式。
- `agents/`：Skill 的 Agent 配置目录。
- `agents/openai.yaml`：OpenAI Agent 显示信息及相关配置。

### `prompt/`

日常 AI 协作提示词收集目录，记录适合需求澄清、方案评审、游戏客户端教学、最小改动和 HTML 输出等场景的提示词。

- `README.md`：提示词清单，并附带每条提示词的使用说明。

## 根目录文件说明

### `游戏客户端-AI输出代码规范.md`

游戏客户端项目的代码生成规范模板。可作为项目级 `AGENTS.md` 或类似规则文件的基础，当前包含项目背景占位信息、指令优先级、C# 命名规范，以及事件注册与取消注册等代码要求。

## 使用建议

1. 需要排查 ChatGPT 网络问题时，先阅读 `chatgpt-network-troubleshooter/SKILL.md`，再根据操作系统选择 `scripts/` 下的脚本。
2. 需要快速理解陌生游戏客户端时，使用 `game-client-project-analysis/SKILL.md` 或中文版文档作为分析框架。
3. 开始一次 AI 协作前，可从 `prompt/README.md` 选择合适的提示词，并结合具体项目上下文补充约束。
4. 在具体游戏项目中使用代码生成规范时，先填写 `游戏客户端-AI输出代码规范.md` 中的项目背景和技术栈信息。

## 注意事项

- 网络诊断脚本默认以只读采证为主；分享诊断结果前，应检查其中可能出现的本机路径、IP、DNS、进程和证书信息。
- Skill 文档描述的是分析或排障方法，不代表当前仓库包含实际的游戏客户端源码或 ChatGPT 客户端源码。
- `游戏客户端-AI输出代码规范.md` 中的项目背景仍是模板内容，需要按实际项目填写。
