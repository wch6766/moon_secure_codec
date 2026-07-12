# MoonSecureCodec 结项说明

## 1. 项目信息

| 项目项 | 内容 |
| --- | --- |
| 项目名称 | MoonSecureCodec |
| 项目标识 | `moonbit-community/moon_secure_codec` |
| 参赛赛道 | 2026 MoonBit 国产基础软件生态开源大赛，Track 1 |
| 开源协议 | Apache License 2.0 |
| GitHub 仓库 | https://github.com/moonbit-community/moon_secure_codec |
| GitLink 仓库 | https://gitlink.org.cn/Wchch/moonbit-community |

## 2. 项目简介

MoonSecureCodec 是一个用 MoonBit 编写的软件供应链安全工具库，核心能力覆盖：

- 多进制编码与解码
- 快速内容指纹与加密摘要
- RFC 6962 风格 Merkle 树和包含证明
- SBOM / 清单快照与差异审计

项目主体由 4 个库包和 1 个 CLI 演示组成，适合用于供应链完整性检查、构建产物校验和轻量级审计。

## 3. 工程结构

| 路径 | 说明 |
| --- | --- |
| `lib/codec` | Hex、Base32、Base64、Base58 编解码 |
| `lib/digest` | XXHash64、Murmur3、SHA-256、HMAC-SHA256 |
| `lib/merkle` | RFC 6962 Merkle 树与包含证明 |
| `lib/manifest` | 文件快照、Manifest 和差异报告 |
| `cmd/cli` | 交互式演示程序 |

## 4. 结项自查

以下检查项已经逐项对照：

- 仓库根目录包含 `README.md`、`LICENSE`、MoonBit 源码和结项说明
- 默认分支为 `main`
- 许可证为 Apache-2.0
- MoonBit 源码文件规模为 11 个
- 当前测试数量为 18 个且全部通过
- 本地已验证 `moon check --deny-warn` 与 `moon test --deny-warn`
- CI 已补充，覆盖 `moon check`、`moon fmt --deny-warn`、`moon info --deny-warn`、`moon test`

## 5. 结项备注

仓库已整理为可提交状态，后续若需要继续扩展，只建议围绕以下方向迭代：

- 增加更完整的输入校验和错误类型
- 扩展更多 Manifest 审计规则
- 为 CLI 增加更清晰的子命令和参数
