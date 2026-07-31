# ChatGPT Network Troubleshooter Skill

用于诊断 ChatGPT 网页端和桌面端的网络故障。Skill 不依赖特定用户名、文件路径、代理软件、VPN 品牌或代理内核。

## 特点

- 支持 Windows、macOS 和 Linux 的排查流程。
- 自动检查系统代理、环境变量、PAC、DNS、IPv4/IPv6、路由、TCP 443、TLS 和本地监听端口。
- 区分网页端、桌面端、浏览器配置和网络路径问题。
- 将代理、VPN、TUN 和企业网关视为可选环境，不预设具体软件。
- 默认只读采证，修复必须最小化、可验证、可回滚。
- 附带 Windows PowerShell 与 macOS/Linux Shell 诊断脚本。

## 目录结构

```text
chatgpt-network-troubleshooter/
├─ SKILL.md
├─ README.md
├─ scripts/
│  ├─ collect-chatgpt-network.ps1
│  ├─ test-chatgpt-connectivity.ps1
│  ├─ collect-chatgpt-network.sh
│  └─ test-chatgpt-connectivity.sh
└─ references/
   └─ openai-domains.md
```

## 使用示例

```text
使用 $chatgpt-network-troubleshooter 排查这台电脑为什么只有 ChatGPT 间歇性无法访问。先只读采证，自动识别操作系统、系统代理、PAC、DNS、IPv4/IPv6、TLS、WebSocket，以及网页端和桌面端的网络路径差异。不要假定我使用任何特定代理软件；证据充分后只执行最小且可回滚的修复。
```

## 脚本安全性

脚本默认只读，不修改：

- 系统代理或 PAC
- DNS、路由或 hosts
- 防火墙或证书存储
- 浏览器和 ChatGPT 应用数据
- 任意代理、VPN 或网络工具配置

诊断结果可能包含本机路径、IP、DNS、网络接口、证书颁发者和进程信息。分享前应人工检查。
