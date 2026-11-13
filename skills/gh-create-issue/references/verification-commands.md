# Verification Commands

Commands that work unchanged in zsh and bash, plus the harness patterns used to
confirm a defect before filing it.

## Shell Quoting

zsh expands an unquoted glob before the command sees it, so
`grep -rn x --include=*.kt .` fails with `no matches found: --include=*.kt`
when the pattern matches nothing in the current directory. Quote the glob:

```bash
grep -rn 'pattern' --include='*.kt' --include='*.md' --exclude-dir=build .
```

Prefer `git grep`, which searches tracked files only and needs no exclusions:

```bash
git grep -n 'pattern' -- '*.kt' '*.cpp' '*.h'
git grep -n 'pattern' -- ':!*Test.kt' '*.kt'
```

Use `rg` when installed; it skips `.gitignore`d paths by default:

```bash
rg -n 'pattern' -g '*.kt' -g '!build'
```

## Repository Root

Start every block with the root, so a reader can paste the block anywhere:

```bash
cd "$(git rev-parse --show-toplevel)"
```

## File Facts

```bash
stat -c '%a %n' path/to/file          # mode on GNU coreutils
stat -f '%Lp %N' path/to/file         # mode on BSD/macOS
wc -c path/to/file
sha256sum path/to/file                # shasum -a 256 on macOS
```

## HTTP Behavior

Start the server in its own process group so the shell keeps the prompt, then
poll instead of sleeping a fixed time:

```bash
setsid <server command> > /tmp/server.log 2>&1 < /dev/null &
for _ in $(seq 1 30); do curl -sf -o /dev/null http://127.0.0.1:PORT/ && break; sleep 1; done
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:PORT/path
curl -s http://127.0.0.1:PORT/ | grep -o 'href="[^"]*"'
```

Stop it by port, not by name, so an unrelated process is never killed:

```bash
kill "$(ss -ltnp | sed -n 's/.*:PORT .*pid=\([0-9]*\).*/\1/p' | head -1)"
```

## Gradle

Run one test class, not the full suite, and read the machine-readable result:

```bash
./gradlew --offline :module:jvmTest --tests 'com.example.ClassName' --console=plain
grep -o 'message="[^"]*"' module/build/test-results/jvmTest/TEST-com.example.ClassName.xml
```

`--offline` avoids a network fetch during a read-only investigation. Drop it only
when the build genuinely needs a download.

A throwaway JUnit test is the cheapest harness when the defect lives in an
`internal` class: add the test, run it, capture the assertion message, then
delete the file and confirm `git status --short` is clean.

## Direct Java Harness

When a Gradle test cycle is too slow and the class is already compiled, call it
from Java against the build output:

```bash
JAVA=/usr/lib/jvm/java-21-openjdk/bin/java
javac -cp build/classes/kotlin/jvm/main -d /tmp/harness /tmp/harness/Probe.java
java -cp "/tmp/harness:build/classes/kotlin/jvm/main:$STDLIB" Probe
```

Resolve `$STDLIB` from the project output rather than hardcoding a path in the
issue: a maintainer on another machine will not have it.

## Report Only What Ran

State the command and its observed output. If a command was not run, write that
it was not run and put the command under a manual-validation heading. Never
present an expected output as an observed one.
