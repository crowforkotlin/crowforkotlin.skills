# Vocabulary Reference

Referenced by `direct-engineering-communication`. The rules live in `SKILL.md`; this file holds the term table those rules apply to.

## Replace Chinese Buzzwords

When writing Chinese, do not use these terms as vague labels. Write the concrete referent instead.

| Term | Write instead |
| --- | --- |
| `链路` | The actual call or data path, such as `LoginViewModel.login()` → `AuthRepository.login()` → `POST /api/login` |
| `闭环` | The completion condition and the step that confirms it |
| `沉淀` | Where the result is recorded: the file, function, or document section |
| `抓手` | The specific action, owner, or metric |
| `护栏` | The specific check or limit and what it rejects |
| `赋能` | Which component or person gains which capability |
| `编排` | The execution order, the dependencies, and the tool that runs them |
| `对齐` | Who confirmed what, or which value now matches which source |
| `打通` | Which component now calls or reads which other component, and through which interface |
| `门面` | The wrapping class or module and the calls it hides, such as `PaymentClient` wrapping SDK setup, signing, and retries |
| `守卫` | The concrete check, where it runs, and what happens when it fails, such as `require(amount > 0)` at the start of `pay()` |
| `兜底` | The fallback branch and the value it returns, such as `?: DEFAULT_KEY` in `releaseVerificationKeys()` |
| `收口` | The comparison or assignment that now exists, with the file and symbol |
| `落地` | The file and symbol the change lands in |
| `收敛` | Which value changed to which, in which file |
| `痛点` | The specific failure, its trigger, and who hits it |
| `颗粒度` | The level of detail: which fields, which files |
| `心智负担` | The rule or state field a reader must hold in mind |
| `体感` | The measured latency, error rate, or step count |
| `优雅` / `健壮` / `强大` | The specific property or measured value |
| `无缝` / `丝滑` / `开箱即用` | The step count or dependency count |
| `本质上` / `说白了` / `归根结底` / `核心在于` | Delete; the sentence already states the fact |
| `值得注意的是` / `不难发现` / `显而易见` | Delete |
| `整体而言` / `综上所述` | Delete |
| `深入` / `全方位` / `系统性` | State the scope |

A listed term is allowed only inside the exact name of a technical concept that applies in the current context, such as `门面模式` for a Facade pattern implemented in the code or `导航守卫` for Vue Router navigation guards. Name the implementing code when using it.

Do not write these English words as stand-ins for a check, a module, or a call either.

| Term | Write instead |
| --- | --- |
| `gate` / `guard` / `guardrail` | The job that fails, the condition, and the exit status, such as the `package` job failing when `secretPub != EVILO_PUBLIC_KEY_HEX` |
| `sentinel` | The command, interval, condition, and timeout action |
| `seam` / `plumbing` / `wiring` | The module or function and the call it makes |
| `wire up` / `plumb through` / `land` | The concrete verb: which function is added, which line assigns the value |
| `scaffold` / `harness` / `skeleton` | The file or module name |
| `hygiene` / `posture` | The specific files and the specific rule |
| `source of truth` | The file that is authoritative |
| `blast radius` | The list of affected files or services |

Examples:

- Avoid: `打通了登录链路，形成闭环。`
- Write: `LoginViewModel.login()` 调用 `AuthRepository.login()`，后者请求 `POST /api/login`；服务端返回 401 时界面显示 `LoginUiState.Error`。
- Avoid: `加了一层门面和守卫，更安全了。`
- Write: 新增 `PaymentClient`，封装 SDK 初始化、签名和重试；`pay()` 开头用 `require(amount > 0)` 拒绝非正数金额。
