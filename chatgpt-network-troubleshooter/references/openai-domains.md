# OpenAI / ChatGPT 网络基线

核对日期：2026-08-01。

执行修复前，应重新检查 OpenAI 官方资料，因为域名和网络要求可能变化：

- https://help.openai.com/en/articles/9247338-network-recommendations-for-chatgpt-errors-on-web-and-apps
- https://help.openai.com/en/articles/7996703-troubleshooting-chatgpt-error-messages
- https://status.openai.com

## 官方建议中的常见域名

代理、防火墙、DNS 和内容过滤规则应优先使用域名或域名后缀，不要固定 IP。

- `*.auth.openai.com`
- `*.chatgpt.com`
- `*.ct.sendgrid.net`
- `*.intercom.io`
- `*.intercomcdn.com`
- `*.oaistatic.com`
- `*.oaiusercontent.com`
- `*.openai.com`
- `*.oaistatsig.com`
- `android.chat.openai.com`
- `auth0.openai.com`
- `cdn.openaimerge.com`
- `cdn.workos.com`
- `challenges.cloudflare.com`
- `chat.openai.com`
- `desktop.chat.openai.com`
- `forwarder.workos.com`
- `humb.apple.com`
- `images.workoscdn.com`
- `ios.chat.openai.com`
- `js.intercomcdn.com`
- `js.stripe.com`
- `o207216.ingest.sentry.io`
- `o33249.ingest.sentry.io`
- `rum.browser-intake-datadoghq.com`
- `setup.auth.openai.com`
- `setup.workos.com`
- `tcr9i.chat.openai.com`
- `workos.imgix.net`

## WebSocket

- ChatGPT WebSocket 相关连接使用安全 WebSocket 和 TCP 443。
- 代理或防火墙需允许标准 WebSocket Upgrade。
- 不应改写握手、提前关闭长连接或设置过短空闲超时。
- 无法按 URL 路径放行时，应根据当前官方文档对 `chatgpt.com` 的 WebSocket Upgrade 进行允许。

## TLS

- 网络过滤或 SSL/TLS inspection 可能导致替代证书、证书链错误或桌面端“网络配置”错误。
- 个人设备上应使用最小范围例外，而不是关闭全局 TLS 验证。
- 企业或学校受管网络应由管理员根据官方域名清单调整策略。

## 解释原则

- 域名列表可能变化，执行时以最新官方文档为准。
- HTTP 401、403 或 404 仍可能说明 DNS、TCP 和 TLS 已到达远端。
- 普通 HTTPS 请求不能完整验证 WebSocket；必须结合浏览器或客户端实际连接。
- OpenAI 主站、认证、静态资源、文件和 WebSocket 应避免被分配到不一致的出口路径。
