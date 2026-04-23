# Claude Code Router 多协议多端口开发计划

## 背景

claude-code-router 的核心定位是"协议入口兼容层 + 路由层 + provider 适配层"。当前架构已经支持 Anthropic（`/v1/messages`）和 OpenAI（`/v1/chat/completions`）两种协议的入口，但所有请求都走同一个端口（8082），客户端无法选择性地接入特定协议端口。

### 已完成

- `server.ts` 已添加 `ListenerConfig` / `ListenerProtocol` 类型和 `startListeners()` 方法
- `config.json` 已添加 `Listeners` 配置项（openai-port:8083, anthropic-port:8084）
- `index.d.ts` 已导出类型声明
- 基本路由注册逻辑已实现（`_registerListenerRoutes` / `_shouldRegisterEndpoint`）

### 待解决问题

1. **Listener 路由注册 404 Bug**：8084（anthropic）端口的 `/v1/messages` 返回 404。根因待排查——可能是 Fastify 异步插件注册时序问题，或 `getTransformersWithEndpoint()` 在 listener 上下文中返回空
2. **UI 未集成 Listener 管理**：当前 Web UI 没有任何多端口/多协议的配置和状态展示
3. **UI 的 `api` 字段缺失**：Provider 编辑界面的 `api` 字段（Anthropic/OpenAI）没有被展示和编辑
4. **Vite 代理缺失**：开发模式下 UI 无法访问后端 API（已修复，添加了 proxy 配置）
5. **Listener 缺少认证中间件**：主端口有 API Key 认证，但 listener 端口没有

---

## Phase 1：修复 Listener 核心功能（P0）

### 1.1 排查并修复 404 Bug

**问题**：`_registerListenerRoutes` 中 `fastify.post()` 注册的路由在运行时返回 404

**排查方向**：
- `getTransformersWithEndpoint()` 返回值是否包含正确的 transformer 实例
- Fastify 插件注册时序——`cors` register 是异步的，路由注册是否在 `ready` 之前完成
- Listener Fastify 实例是否缺少必要的 decoration（`providerService` 等）导致路由 handler 执行时找不到依赖
- `handleTransformerEndpoint` 内部是否依赖 `req.server` 上的某些 decoration 而非传入的 `fastify` 实例

**修复方案**：
- 将 listener 的路由注册改为通过 `fastify.register()` 异步插件模式，确保所有 decoration 在路由 handler 之前完成
- 或者在 `listen` 之前调用 `await listenerApp.ready()` 确保插件就绪

### 1.2 Listener 添加认证中间件

**目标**：Listener 端口应支持与主端口相同的 API Key 认证机制

**实现**：
- 在 `_startListener` 中添加与主服务器相同的 `apiKeyAuth` preHandler hook
- 支持 `ListenerConfig.apiKey` 覆盖主服务器的 APIKEY

### 1.3 Listener 添加 API 路由

**目标**：Listener 端口应暴露 `/v1/models` 和健康检查端点

**现状**：已有 `/` 和 `/health` 和 `/v1/models`，需确认功能完整

---

## Phase 2：UI 多协议端口管理（P1）

### 2.1 新增 Listeners 配置组件

**目标**：在 Dashboard 中新增"监听端口"Tab 或面板，可视化管理 Listeners 配置

**设计**：
```
┌─────────────────────────────────────────────┐
│ 监听端口 (Listeners)                    [+] │
├─────────────────────────────────────────────┤
│ ● openai-port     127.0.0.1:8083  OpenAI    │
│   └─ /v1/chat/completions, /v1/responses    │
│ ● anthropic-port  127.0.0.1:8084  Anthropic │
│   └─ /v1/messages                           │
└─────────────────────────────────────────────┘
```

**实现要点**：
- `types.ts` 添加 `ListenerConfig` 和 `ListenerProtocol` 类型
- `Config` 接口添加 `Listeners?: ListenerConfig[]`
- 新增 `Listeners.tsx` 组件
- 在 `App.tsx` 主布局中添加 Listeners 面板
- 支持 CRUD：添加/编辑/删除 listener
- 实时显示每个 listener 的状态（运行中/已停止）

### 2.2 Provider 编辑界面增强

**目标**：Provider 编辑对话框中添加 `api` 字段选择

**当前问题**：`Provider` 类型有 `api` 字段（Anthropic/OpenAI），但 UI 只显示了 `api_base_url`、`api_key`、`models`、`transformer`

**实现**：
- `types.ts` 的 `Provider` 接口添加 `api?: string` 字段
- Provider 编辑对话框添加 `api` 下拉选择（Anthropic/OpenAI）
- 当选择 `api` 时，自动推荐对应的 `api_base_url` 模板
- 在 Provider 列表中用 Tag 展示协议类型

### 2.3 服务器状态面板

**目标**：在 Dashboard 顶部或侧栏显示所有监听端口的状态

**设计**：
```
┌──────────────────────────────────────────┐
│ 服务状态                                  │
│ ● 主端口    127.0.0.1:8082  全协议  运行中  │
│ ● OpenAI   127.0.0.1:8083  OpenAI  运行中  │
│ ● Anthropic 127.0.0.1:8084 Anthropic 运行中│
└──────────────────────────────────────────┘
```

**实现**：
- 后端新增 `/api/listeners/status` API，返回每个 listener 的运行状态
- 前端添加 `ServerStatus.tsx` 组件
- 使用轮询（5s）或 WebSocket 实时更新状态

---

## Phase 3：协议转换可视化与调试（P2）

### 3.1 请求协议流向可视化

**目标**：在 Debug 页面中展示请求从客户端到 provider 的完整协议转换链路

**设计**：
```
客户端 ──[OpenAI]──→ :8083/v1/chat/completions
  ↓ OpenAI→内部格式
路由决策 → arkcode-cc (glm-5.1)
  ↓ 内部格式→下游协议
Provider ──[OpenAI]──→ ark.cn-beijing.volces.com/api/coding/v3
```

### 3.2 协议兼容性矩阵

**目标**：在 Dashboard 中展示各 Provider 支持的协议类型

**设计**：
```
Provider      | 入口协议       | 出口协议    | 转换链
arkcode-cc    | OpenAI/Anthropic | OpenAI    | OpenAI→内部→OpenAI
gemini-cli    | OpenAI/Anthropic | Gemini    | Anthropic→内部→Gemini
```

### 3.3 快速连接测试

**目标**：对每个 Listener 端口提供一键连接测试，确认协议端点可用

**实现**：
- 后端新增 `/api/listeners/:name/test` API
- 前端在 Listener 管理界面添加"测试连接"按钮
- 返回连接延迟、协议兼容性、可用模型列表

---

## Phase 4：配置优化与生产部署（P3）

### 4.1 一键生成客户端配置

**目标**：根据当前 Listeners 配置，生成常见客户端的配置代码

**示例**：
```bash
# OpenAI 兼容客户端
export OPENAI_API_KEY=sk-xxx
export OPENAI_BASE_URL=http://127.0.0.1:8083/v1

# Claude Code (Anthropic)
export ANTHROPIC_API_KEY=sk-xxx
export ANTHROPIC_BASE_URL=http://127.0.0.1:8084
```

### 4.2 生产部署 UI

**目标**：`build:ui` 产物应自动被 server 包的 `/ui/` 路径提供

**当前状态**：已通过 `@fastify/static` 实现，但需要确保 `build:ui` 产物放入正确的 `dist` 目录

### 4.3 生产模式启动 BAT

**目标**：`start-prod.bat` 同时启动 server 并打开浏览器访问 `/ui/` 路径

---

## 实施优先级

| Phase | 优先级 | 预计工时 | 依赖 |
|-------|--------|---------|------|
| 1.1 修复 404 Bug | P0 | 2h | 无 |
| 1.2 认证中间件 | P0 | 1h | 1.1 |
| 1.3 API 路由 | P1 | 0.5h | 1.1 |
| 2.1 Listeners 组件 | P1 | 3h | 1.1 |
| 2.2 Provider api 字段 | P1 | 1.5h | 无 |
| 2.3 服务器状态面板 | P2 | 2h | 1.1 + 后端 API |
| 3.x 协议可视化 | P2 | 4h | Phase 2 |
| 4.x 配置优化 | P3 | 2h | Phase 2 |
