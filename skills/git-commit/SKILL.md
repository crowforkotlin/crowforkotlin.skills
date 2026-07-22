---
name: git-commit
description: 根据 git 变更自动生成规范的 commit 提交信息，支持中文/英文输出及剪贴板复制。
---

# Git Commit 提交信息生成器

## 触发命令

| 命令 | 说明 |
|------|------|
| `/commit_zh` | 生成**中文** commit 提交信息 |
| `/commit_zh_copy` | 生成**中文** commit 提交信息并复制到剪贴板 |
| `/commit_en` | 生成**英文** commit 提交信息 |
| `/commit_en_copy` | 生成**英文** commit 提交信息并复制到剪贴板 |

## 执行流程

当用户触发上述任一命令时，按以下步骤执行：

### 1. 获取变更信息

依次执行以下命令获取完整变更上下文：

```bash
git status
git -P diff HEAD
```

> **重要**: Diff 内容**必须**通过 `git -P diff HEAD` 获取；严禁使用 `git diff HEAD`。

### 2. 生成 Commit 信息

根据获取到的 `git status` 完整文件变更状态（新增 A / 修改 M / 删除 D / 重命名 R / 复制 C / 未合并 U / 未追踪 ?? 等）以及 `git -P diff HEAD` 的完整 diff 内容，**仅生成一条完整的、可直接用于 `git commit -m` 的 commit 提交信息**。

### 3. 语言选择

- `/commit_zh` 或 `/commit_zh_copy`：提交信息**必须**完全使用**中文**编写。
- `/commit_en` 或 `/commit_en_copy`：提交信息**必须**完全使用**英文**编写。

### 4. 剪贴板复制（仅 `_copy` 后缀命令）

- `/commit_zh_copy` 和 `/commit_en_copy`：在输出 commit 信息后，将**纯文本**（不含代码块标记）复制到系统剪贴板。
  - Linux: `echo "<commit_msg>" | xclip -selection clipboard` 或 `wl-copy`
  - macOS: `echo "<commit_msg>" | pbcopy`

## 硬性约束

1. **绝对不能**修改任何代码或文件。
2. **绝对不能**输出提交信息以外的任何内容（无标题、无解释、无注释、无多余空行、无引用标记）。
3. **必须**将最终的 commit 提交信息包裹在单个 Markdown 代码块中。
4. 无论代码注释、提交历史或 diff 内容使用何种语言，最终输出语言仅由命令后缀决定（`_zh` = 中文，`_en` = 英文）。

## 生成规范

### 步骤 0 — 变更规模评估 (Change-Scale Triage)

计算 $N$（变更文件数量）和 $L$（状态中新增与删除的总行数，即 $+x$ 与 $-y$ 的绝对值之和）。

- **微小变更**（$N \le 2$ 且 $L \le 15$；纯结构重排 / 注释清理 / 版本升级 / 导入语句增删，无行为变更）：
  仅输出标题行以及最多 2 个概要要点，**跳过详细描述**。
- **常规变更**：完整执行标题 + 概要 + 详细描述。
- **复杂变更**（$N \ge 5$，或包含新增/删除/重命名文件，或涉及核心逻辑）：完整执行所有步骤；根据需要展开详细描述。

> 规模评估仅影响详细程度，不影响前缀选择逻辑。

### 步骤 1 — 解析与意图识别

- 逐行解析 `git status` 的输出；按变更类型和文件路径构建统计表，计算各变更类型的比例。
- 应用业务价值权重（由高到低）：**feature（特性） > fix（修复） > refactor（重构） > config（配置） > docs（文档） > style（样式） > build（构建） > misc（杂项）**。

### 步骤 2 — 前缀选择

根据最高权重的变更类型选择 commit 前缀：

| 类型 | 前缀 | 示例 |
|------|------|------|
| 新特性 | `feat` | `feat(认证模块): 新增用户登录功能` |
| 修复 | `fix` | `fix(支付): 修复金额计算精度问题` |
| 重构 | `refactor` | `refactor(数据库): 重构连接池管理` |
| 配置 | `config` | `config: 更新 CI 构建配置` |
| 文档 | `docs` | `docs: 补充 API 接口说明` |
| 样式 | `style` | `style: 统一代码缩进格式` |
| 构建 | `build` | `build: 升级 Gradle 至 8.5` |
| 杂项 | `chore` | `chore: 清理无用资源文件` |

### 步骤 3 — 标题行

格式: `<type>(<scope>): <subject>`

- `type`: 上表中的前缀
- `scope`: 可选，受影响的模块/组件名
- `subject`: 简明描述变更目的（中文命令用中文，英文命令用英文）

### 步骤 4 — 概要要点

使用 `- ` 列出 2~5 个关键变更要点，每条一行。

### 步骤 5 — 详细描述（常规/复杂变更）

对重要变更进行补充说明，包括：
- 变更动机与背景
- 关键实现细节
- 潜在影响或注意事项

## 输出格式示例

### 中文示例 (`/commit_zh`)

```
feat(用户模块): 新增用户注册与邮箱验证功能

- 新增 UserRegistrationService 处理注册逻辑
- 集成邮件发送服务实现邮箱验证码
- 添加注册表单参数校验
- 新增相关单元测试覆盖

实现用户自助注册流程，通过邮箱验证码确认身份，
注册成功后自动创建默认用户配置。
```

### 英文示例 (`/commit_en`)

```
feat(auth): add user registration with email verification

- Add UserRegistrationService for registration logic
- Integrate email service for verification codes
- Add form validation for registration parameters
- Add unit tests for registration flow

Implement self-service user registration with email
verification. Default user config is created upon success.
```
