# MoonSecureCodec

MoonSecureCodec 是一个使用 MoonBit 实现的软件供应链完整性工具库。它面向构建产物、依赖清单和发布包校验，提供可复用 API、确定性审计报告和可运行 CLI 示例。

## 能力范围

- `lib/codec`：Hex、Base32、Base64、Base64URL、Base58、Multibase、CRC32 和规范 LEB128/Varint 编解码。
- `lib/digest`：XXHash64、Murmur3-32、SHA-256、HMAC-SHA256、批量摘要和恒时摘要比较。
- `lib/merkle`：带叶子/节点域分离的 Merkle 树、包含证明、全量证明自检和 RFC 6962 风格根计算。
- `lib/manifest`：文件快照、确定性序列化、Merkle 根、版本差异、增量清单选择，以及路径/哈希/重复项/生成物审计。
- `lib/manifest` 依赖策略：版本固定、许可证允许列表、上游来源和内容摘要检查。
- `cmd/cli`：端到端演示编码、摘要、Merkle 证明、Manifest 差异和完整性校验。

项目不是密码学签名系统，也不替代正式 SBOM 标准或法律许可证审查。XXHash64 和 Murmur3 仅用于快速索引/去重，不能用于安全认证；发布完整性应使用 SHA-256、HMAC 或外部签名系统。

## 目录结构

| 路径 | 作用 |
| --- | --- |
| `top.mbt` | 面向使用者的顶层门面 API |
| `lib/codec` | 编码、解码和 Multibase 内容标识 |
| `lib/digest` | 快速指纹、密码学摘要和恒时比较 |
| `lib/merkle` | Merkle 树、包含证明和发布前自检 |
| `lib/manifest` | 文件清单、差异、结构审计和依赖政策 |
| `cmd/cli` | 可直接运行的工作流演示 |
| `.github/workflows/test.yml` | Linux/macOS/Windows CI 质量门禁 |

## 本地使用

需要 MoonBit 0.10.3 或更新版本。本项目没有运行时第三方依赖，模块名是 `Wchch/MoonSecureCodec`；发布到 mooncakes.io 时应保持该命名空间与仓库信息一致。

```bash
moon version --all
moon check --deny-warn
moon test --deny-warn
moon fmt --check
moon info
moon run cmd/cli
```

如果本机尚未安装 MoonBit，请按 [MoonBit 官方安装说明](https://www.moonbitlang.com/download/) 安装 CLI，然后在仓库根目录执行上述命令。项目不需要额外的包管理器、环境变量或数据库服务。

当前本地验收基线：1036 个测试全部通过；项目 MoonBit 源码约 11275 行（不含 `_build/` 和备份目录），其中生产实现达到 3000 行，测试覆盖约 8275 行。`moon check --deny-warn`、`moon test --deny-warn`、`moon fmt --check` 和 `moon info` 均通过。测试包含官方 XXHash64 向量、RFC 6962 单叶/双叶/三叶向量、Varint 边界、空输入、非 ASCII 数据、非 2 的幂次叶子数、错误输入、越界证明、路径穿越、重复项、损坏根、发布策略、审批绑定和依赖合规边界。

## 快速示例

```moonbit
// In a package importing Wchch/MoonSecureCodec/lib/manifest:
let artifact : Bytes = b"release artifact bytes"
let file = @manifest.FileSnapshot::from_bytes("dist/app.bin", artifact)
let manifest = @manifest.Manifest::new(
  "example-app",
  "1.2.3",
  "2026-08-12T00:00:00Z",
  [file],
)
let report = manifest.audit_with_policy([".bin"], 50_000_000L)
if report.has_errors() {
  println(report.to_text())
}
```

依赖审计使用显式许可证和来源策略，避免把“代码能编译”误认为“可以合法发布”：

```moonbit
// Each record should be populated from the reviewed dependency lock data.
let dependencies : Array[@manifest.Dependency] = [
  {
    name: "moonbitlang/core",
    version: "0.10.3",
    license: "Apache-2.0",
    source: "https://github.com/moonbitlang/core",
    digest: "0123456789abcdef0123456789abcdef",
  },
]
let policy = @manifest.LicensePolicy::strict(["Apache-2.0", "MIT"])
let result = @manifest.audit_dependencies(dependencies, policy)
assert_false(result.has_errors())
```

## 可复现验收

CI 在三个操作系统上执行以下步骤：安装 MoonBit、输出工具链版本、`moon check --deny-warn`、`moon fmt --check`、`moon info`、`git diff --exit-code` 和 `moon test --deny-warn`。任何警告、格式变化或测试失败都会使 CI 失败。

本地构建目录 `_build/`、MoonBit 缓存和生成接口文件已被 `.gitignore` 排除，仓库提交中不包含构建产物。

## 标准兼容性

`lib/digest` 的 XXHash64 实现通过官方参考向量（空字节串、`a`、`abc`）。`lib/merkle` 按 RFC 6962 使用 `SHA-256(0x00 || leaf)`、`SHA-256(0x01 || left || right)` 和最大二次幂分割规则；非 2 的幂次叶子不会重复末节点。对应向量和包含证明回归测试位于 `lib/digest/digest_test.mbt` 与 `lib/merkle/merkle_test.mbt`。

## 开源与第三方材料

项目代码采用 Apache License 2.0，许可证全文见 [LICENSE](LICENSE)。当前实现为本仓库 MoonBit 源码；没有把外部项目的源代码、私有代码或不可再分发测试夹具复制进仓库。若未来引入第三方实现、生成代码、测试数据或新的依赖，必须在提交前记录来源、版本、许可证和再分发条件，并更新依赖审计记录。

安全问题请参阅 [SECURITY.md](SECURITY.md)，贡献流程请参阅 [CONTRIBUTING.md](CONTRIBUTING.md)。
