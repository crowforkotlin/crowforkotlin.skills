# Repository Instructions

## CodeGraph

If `.codegraph/` exists at the repository root, use CodeGraph before `rg`, `find`, or reading source files when locating or understanding code. Use the `codegraph_explore` MCP tool when available, otherwise run `codegraph explore "<question>"`.

## Execution Boundaries

- Implement the requested change without running validation, tests, lint, check, type check, formatting, compilation, builds, packaging, application servers, device commands, APK installation, or screenshots unless the user explicitly requests that exact operation.
- This rule applies to all languages and tools, including indirect execution through scripts, task runners, Gradle, Make, npm, Python, Rust, Go, C++, Kotlin, Java, JavaScript, TypeScript, HTML, and CSS workflows.
- Authorization for one operation does not authorize related operations. For example, authorization to compile does not authorize APK installation or screenshots.
- Report only commands actually run. When validation was not requested, provide manual verification commands separately and label them as not executed.
