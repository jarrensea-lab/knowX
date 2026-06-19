# knowX — AI Agent 编排工程师学习平台

> 基于飞书 + Claude Code 的 AI Agent 编排工程师学习系统

## 核心架构

```
┌──────────────────────────────────────┐
│        飞书群「内阁」                  │
│  knowX（学习助手）  │  lark-agent    │
└────────┬─────────────────────────────┘
         │
         ▼
  ┌──────────────┐
  │  knowX 系统   │
  │ SYSTEM.md    │
  └──────┬───────┘
         │
         ▼
  ┌──────────────┐
  │ data/graph.db│
  │ 知识图谱      │
  └──────────────┘
```

## 功能

### 知识图谱学习

- 节点驱动的个性化学习路径
- 每日课程卡片 + 自动简报推送
- 测验 + 实践代码评判训练
- 文章投喂 → 自动关联知识点
- 技术新闻筛选

### 飞书交互指令

| 指令 | 功能 |
|------|------|
| `knowX 今天学什么` | 生成课程卡片 |
| `knowX 我学会了 <知识点>` | 标记掌握，推荐下一课 |
| `knowX 图谱` | 查看知识图谱全貌 |
| `knowX 进度` | 查看学习进度 |
| `knowX 简报` | 生成日报 |
| `knowX 考我` | 知识测验 |
| `knowX 实操` | 代码评判训练 |

### n8n 自动化课程

完整的 AI 自动化大师课笔记（6 模块 29 课）。

## 项目结构

```
knowX/
├── data/
│   ├── graph.db              # 知识图谱 (SQLite)
│   ├── courses/              # 课程笔记 (n8n)
│   ├── mypkg/                # 工具模块
│   └── news_cache/           # 新闻缓存
├── docs/                     # 文档
│   ├── architecture/         # 架构设计
│   ├── strategies/           # 交易策略
│   ├── trading-knowledge/    # 交易知识
│   └── superpowers/          # 系统设计文档
├── scripts/                  # 运维脚本
│   ├── polling-agent.sh      # 飞书消息轮询
│   └── knowx-news.sh         # 新闻抓取
├── SYSTEM.md                 # knowX 行为规则
├── AGENTS.md                 # Claude Code 入口配置
└── ROADMAP.md                # 开发路线图
```

## 运行方式

1. Claude Code 打开本目录，自动加载 `SYSTEM.md` 作为系统提示词
2. 运行 `./scripts/polling-agent.sh start` 启动飞书消息轮询
3. 在飞书群中向 knowX 发送指令即可交互
4. 自动简报：每天早上 7:00 推送

## 技术栈

| 层级 | 技术 |
|------|------|
| AI 模型 | Claude Code + DeepSeek |
| 数据库 | SQLite（知识图谱） |
| 交互层 | 飞书全通道 |
| Agent 框架 | Claude Code + MCP |
| 自动化 | n8n（工作流引擎） |

## 数据文件

| 文件 | 说明 |
|------|------|
| `data/graph.db` | 知识图谱 SQLite（nodes / edges / progress） |
| `config.json` | 群 ID、推送时间、新闻源 |
| `SYSTEM.md` | 完整行为规则 |
