# MoonDatalog 🌙📊 (`moonbit-community/moon_datalog`)

[![MoonBit](https://img.shields.io/badge/Made%20with-MoonBit-purple.svg)](https://www.moonbitlang.com/)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Target: WASM-GC / JS / Native](https://img.shields.io/badge/Target-WASM--GC%20%7C%20JS%20%7C%20Native-success.svg)]()
[![OSC 2026 Track 1](https://img.shields.io/badge/OSC%202026-Track%201%20Submission-orange.svg)](https://www.gitlink.org.cn/competitions/track1_2026MoonBit)

**MoonDatalog** is an enterprise-grade, high-performance **Deductive Relational Database & Declarative Rule Engine** implemented entirely in [MoonBit](https://www.moonbitlang.com/). 

Designed from the ground up to bridge **Relational Databases**, **Graph Analytics**, and **Cloud Security Access Control (RBAC/ABAC)**, MoonDatalog delivers pure functional evaluation with zero memory leaks, lightning-fast compilation to WebAssembly (WASM-GC), and rigorous formal verification.

---

## 🌟 Why MoonDatalog? (项目背景与特色)

In modern software architecture, complex querying, transitive closure computations (e.g., knowledge graph reachability, recursive organizational chains), and authorization policies (e.g., AWS IAM, Kubernetes RBAC, Open Policy Agent) often require cumbersome recursive code or heavy external database dependencies.

**MoonDatalog** solves this by providing a lightweight, embedded deductive engine in MoonBit:
1. **Zero Overlap on Mooncakes**: As verified via the MoonBit package registry (`mooncakes.io`), MoonDatalog is the **first and only** Datalog and deductive database engine in the MoonBit ecosystem.
2. **Semi-Naive Fixpoint Evaluation**: Implements differential evaluation ($\Delta$-driven iteration) to guarantee optimal performance without re-deriving existing facts across recursive loops.
3. **Stratified Negation ($\neg$)**: Supports negation as failure (NAF) with automatic dependency graph analysis and Bellman-Ford cycle detection to reject unstratifiable negative loops.
4. **Mature Domain Applications**: Includes out-of-the-box domain libraries for **Graph Analytics** (`lib/graph`) and **Declarative Access Control** (`lib/policy`).
5. **Formal Spec-Driven Development**: Built with declarative contract invariance testing (`spec.mbt`) to guarantee fixpoint termination and set deduplication.

---

## 🏗️ Architecture & Subsystem Packages (系统架构)

MoonDatalog is modularly organized into 7 cohesive packages:

```
moon_datalog/
├── lib/core      # Relational Primitives: Value, Tuple, Relation (Set-semantics)
├── lib/algebra   # Relational Algebra: Select, Project, Rename, Union, Diff, Intersect, Hash Join
├── lib/ast       # Datalog AST: Term, Literal, Rule, Program, Stratification & Safety Verification
├── lib/engine    # Evaluation Engine: Naive & Semi-Naive Fixpoint Evaluators
├── lib/parser    # Lexer, Recursive-Descent Parser & EXPLAIN Query Planner
├── lib/graph     # Domain Package: Graph Reachability, Connected Components, Cycle Detection
└── lib/policy    # Domain Package: Declarative RBAC / ABAC Cloud Security Authorization Engine
```

---

## 📦 Installation (快速安装)

Add MoonDatalog to your MoonBit project using the official CLI:

```bash
moon add moonbit-community/moon_datalog
```

In your `moon.pkg`:
```json
{
  "import": [
    "moonbit-community/moon_datalog",
    "moonbit-community/moon_datalog/lib/core"
  ]
}
```

---

## 🚀 Quickstart & Usage (快速上手)

### 1. Unified Top-Level API (`top.mbt`)

You can execute Datalog programs directly from text and inspect the extracted relational database:

```moonbit
import {
  "moonbit-community/moon_datalog",
  "moonbit-community/moon_datalog/lib/core"
}

fn main {
  let program_text =
    #|// EDB Facts: Parent relationships
    #|parent("Alice", "Bob").
    #|parent("Bob", "Charlie").
    #|
    #|// IDB Rules: Transitive Ancestor inference
    #|ancestor(X, Y) :- parent(X, Y).
    #|ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).

  // Print EXPLAIN query plan
  match @moon_datalog.explain_query_plan(program_text) {
    Ok(plan) => println(plan)
    Err(e) => println("Error: " + e)
  }

  // Evaluate to fixpoint
  match @moon_datalog.parse_and_eval(program_text) {
    Ok(db) => {
      let ancestor_rel = db.get("ancestor").unwrap()
      println(ancestor_rel.to_string())
      // Output contains: (Alice, Bob), (Bob, Charlie), (Alice, Charlie)
    }
    Err(e) => println("Evaluation Error: " + e)
  }
}
```

### 2. Declarative RBAC/ABAC Security Policy Engine (`lib/policy`)

Model complex cloud authorization rules cleanly:

```moonbit
fn check_security {
  let engine = @moon_datalog.new_policy_engine()
  
  // Assign roles & permissions
  engine.add_role("alice", "developer")
  engine.add_role("bob", "guest")
  engine.add_admin("charlie")

  engine.add_permission("developer", "repo", "push")
  engine.add_permission("guest", "repo", "pull")

  // Verify authorization
  assert_eq(engine.check_access("alice", "repo", "push"), true)
  assert_eq(engine.check_access("bob", "repo", "push"), false)
  assert_eq(engine.check_access("charlie", "repo", "delete"), true) // Admin override

  // Revoke via stratified negation
  engine.block_user("alice")
  assert_eq(engine.check_access("alice", "repo", "push"), false)
}
```

### 3. Graph Analytics (`lib/graph`)

```moonbit
fn analyze_graph {
  let edges = @core.Relation::new("edge", ["from", "to"])
  edges.insert(@core.Tuple::new([@core.Value::from_int(1), @core.Value::from_int(2)]))
  edges.insert(@core.Tuple::new([@core.Value::from_int(2), @core.Value::from_int(3)]))

  assert_eq(@moon_datalog.query_reachability(edges, 1L, 3L), true)
}
```

---

## ⚡ Benchmarks & Demos (运行演示与性能测试)

MoonDatalog comes with two runnable command executables in `cmd/`:

### Run Interactive Enterprise Rule Demo (`cmd/main`)
Simulates an enterprise organizational hierarchy with recursive supervision chains and security authorization rules:
```bash
moon run cmd/main
```

### Run Evaluation Performance Benchmark (`cmd/bench`)
Compares Naive vs. Semi-Naive evaluation across a 50-node linear chain graph (1,225 derived pairs):
```bash
moon run cmd/bench
```

---

## 🧪 Verification & Spec-Driven Testing (测试与质量保证)

MoonDatalog maintains a strict zero-warning, 100% test pass guarantee:

```bash
# Run type checking and lints across all subsystems
moon check

# Run all 19 unit test suites and formal specifications
moon test
```

---

## 📜 License

This project is licensed under the **Apache License 2.0**. See the [LICENSE](LICENSE) file for details.

---

## 🏆 OSC 2026 Competition Declaration (参赛说明与自我审查)

1. **选题成熟与扩展性**: 本项目选择了数据库核心（Datalog 演绎关系数据库）与企业级应用（RBAC/ABAC 权限控制、图谱分析）的深度交叉领域。不仅填补了目前 MoonBit 开源生态在逻辑编程与推演引擎方面的空白，且具有极高的工业界实用价值与横向扩展能力。
2. **零依赖纯手工打造**: 全库代码均由 MoonBit 原生语法严格实现，不依赖任何外部第三方库，充分发挥了 MoonBit 在 WASM-GC 内存管理、模式匹配及高阶函数上的卓越性能。
3. **符合规范**: 包含完整的 `moon.mod.json`、`moon.pkg.json` 结构定义、`Apache-2.0` 开源协议、自动化 CI 工作流以及丰富的单测与验证案例。
