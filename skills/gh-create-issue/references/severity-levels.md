# Severity Levels

One of four values. Choose the highest level whose condition holds.

Each level states its reach first: what part of the product the defect can
break. The bullets that follow list the concrete conditions that place a defect
at that level.

## `critical`

Reach: core functionality becomes unusable, data is severely damaged, a security
property is violated, or the failure spreads across the whole system.

- Silent data loss or corruption: written output differs from the input, a key or
  artifact is overwritten without a warning, or a successful exit code is
  reported for a failed operation.
- A security property is bypassed on the default path: signature verification
  skipped, path traversal outside the served directory, credentials or private
  keys exposed to other users, remote code execution.
- The default path stops working end to end: startup aborts, every request
  fails, or recovery needs manual repair of persisted state.

## `high`

Reach: core functionality, a critical runtime flow, or a compatibility contract
is affected, and no workaround exists inside the product.

- A documented feature does not work at all, for every user, with no workaround
  inside the product.
- An API contract stated in a KDoc, README, or specification is violated and the
  violation is observable (a size limit exceeded, a version rejected, a
  checksum not checked).
- A change breaks a consumer-visible contract: a public signature, wire format,
  file format, or persisted schema that existing callers or data cannot avoid.
- The failure needs a second component or an external server to work around.

## `medium`

Reach: part of the functionality, one scenario, or one platform is wrong, and a
workaround is available.

- Correct behavior in one configuration, wrong in another: a specific option,
  platform, file-system, or re-run condition.
- Unsafe behavior whose trigger requires an unusual state (a pre-existing file,
  a hand-built manifest, a manually written cache entry).
- An incompatibility confined to one platform, runtime, or dependency version.
- A workaround exists inside the product and is discoverable.

## `low`

Reach: limited. Edge cases, misleading symptoms, or paths outside the main
feature.

- Diagnostics: the failure message names the wrong cause, or a mismatch is
  reported without the value that would identify it.
- Documentation contradicts the implementation, or two documents contradict
  each other.
- A latent hazard guarded by another mechanism today, such as a frame layout
  protected only by an ABI version check.
- A defect that fails closed.
- Wrong behavior on an edge case that the main feature does not reach.

## Adjacent Failures

State the direction of the failure in the `Severity:` line when it matters:

- `Severity: low (fails closed: the input is rejected, never accepted)`
- `Severity: high (fails open: an unverified artifact is loaded)`

A reviewer must be able to check the level against the `## Impact` section
without reading the rest of the body. If the impact does not match the level,
change the level, not the phrasing.
