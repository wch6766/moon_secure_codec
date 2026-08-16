# Contributing

提交前请在本地运行：

```bash
moon check --deny-warn
moon test --deny-warn
moon fmt --check
moon info
```

新功能应包含真实输入向量、正常路径、错误输入和边界情况测试。涉及供应链或许可证的功能还应补充可解释的错误代码和修复建议。请保持 MoonBit 包边界清晰，不提交 `_build/`、缓存、凭据或未说明来源的第三方材料。
