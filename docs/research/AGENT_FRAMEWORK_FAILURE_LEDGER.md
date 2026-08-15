# Agent / Framework Failure Ledger

## Purpose

This ledger records failures in agentic engineering work without hiding attribution.

The goal is to distinguish:

- **framework failure** — the request, architecture, process, or handoff contract was materially insufficient, contradictory, unsafe, or impossible to execute as written;
- **agent execution failure** — the request was actionable and the agent failed to perform or persist the required work;
- **platform/tooling failure** — the agent was prevented from completing the work by an external task/runtime/tool failure;
- **mixed failure** — more than one category materially contributed;
- **unknown** — evidence is insufficient to attribute confidently.

This distinction is important because a framework should not absorb blame for an agent that ignored an explicit finish condition, and an agent should not absorb blame for a broken or impossible framework request.

## Attribution rule

For every failed or partially failed campaign, record:

1. exact request / plan identity;
2. agent and execution environment when known;
3. intended finish condition;
4. observed result;
5. whether the request was executable as written;
6. whether the agent satisfied the explicit persistence / handoff contract;
7. whether an external platform or tool error prevented completion;
8. attribution category;
9. confidence;
10. corrective action.

Attribution must follow evidence, not convenience.

A failed campaign is a **framework failure** only when the framework itself materially caused the failure. A failed campaign is an **agent execution failure** when the request was actionable and the agent failed to perform an explicit required action despite having a viable path to do so. A **platform/tooling failure** is reserved for externally observable execution failures such as task crashes, unavailable tools, permission failures, or infrastructure errors.

## Metrics

Track at minimum:

- total campaigns;
- successful campaigns;
- partial campaigns with preserved handoff;
- agent execution failures;
- framework failures;
- platform/tooling failures;
- mixed/unknown failures;
- campaigns that ended with no externally preserved output;
- campaigns where an explicit commit/push/PR requirement was ignored;
- campaigns recovered by a later salvage/handoff run.

Do not collapse all failures into one number. The point is to learn whether the bottleneck is architecture, prompting, agent execution, or platform reliability.

## Entry 2026-08-13 — Batch 31D PR #66 validation-follow-up persistence failure

**Context:** PR #66 (`Introduce bounded anonymous mapping primitive and handle Linux RV64 mmap(222) pressure`) produced real runtime progress: static musl remained proven, `busybox.static true` remained successful, the first fixed no-access anonymous `mmap(222)` advanced to success, and the next runtime frontier became the zero-length non-fixed RW anonymous mmap argument divergence.

**Known repository state:** GitHub Actions remained red because canonical validation evidence had a stale source digest. The implementation and focused tests were otherwise useful and intentionally preserved as a frontier checkpoint.

**Follow-up request:** the Codex run was explicitly instructed to regenerate the stale canonical validation evidence, commit all required regenerated files, push to the existing PR #66 branch, and make the existing PR visibly change. The request explicitly said that merely running validation locally was not completion.

**Observed result:** PR #66 remained on the same head commit `55d5bd620727b07b8efc91fa10a26007938ddb5f`; no new commit was pushed, the PR still contained one commit, and the stale validation-evidence failure remained unresolved.

**Attribution:** **agent execution failure**.

**Confidence:** high.

**Why:** the follow-up finish condition was concrete, externally verifiable, and technically routine: regenerate repository-owned derived evidence, commit it, push it to the already-existing branch, and verify the PR head changed. No evidence currently shows that the framework request was contradictory or impossible. No external tool/platform failure was surfaced for this specific follow-up. Therefore the failure should be attributed to the Codex run failing to persist the requested cleanup, not to Morphic's engineering framework.

**Checkpoint decision:** PR #66 was intentionally merged red as an explicitly annotated frontier so useful runtime work was not discarded. The merge does **not** imply green CI or Batch 31D completion.

**Corrective action:** future agentic plans must keep the existing handoff discipline: commit/push safe progress early, make persistence an explicit finish condition, and record whether a failure is framework, agent, platform, mixed, or unknown. Fresh follow-up work from main must first close known red validation debt before claiming a new green frontier.

## Entry 2026-08-13 — Batch 31E checkout lacks remote and QEMU tooling

**Context:** Batch 31E required green recovery to be committed, pushed, remote-head verified, and followed immediately by exact BusyBox echo and shell pressure.

**Observed result:** the recovery was regenerated and committed locally as `471d280403b0a87effaf8dfb2d015c28ed1c38e8`. The checkout had no configured `origin`, so push and remote-head verification failed. Node.js was absent, preventing the Node-backed portion of `zig build check`; neither `qemu-system-riscv64` nor `qemu-riscv64` was installed, so the exact runtime retries could not execute. Local commits and the worktree survived.

**Attribution:** **platform/tooling failure** (high confidence). The plan was actionable, and the agent performed the available persistence and focused implementation work; externally required Git and machine-emulation surfaces were absent.

**Corrective action:** supply the repository remote, Node.js, and both RISC-V QEMU executables; rerun the aggregate gate, push the preserved commits, verify the remote SHA, open the draft PR, and immediately execute the exact echo then shell ladder.

## Entry 2026-08-13 — Batch 31G golden oracle and remote persistence surfaces

**Context:** Batch 31G required a Linux-user golden differential, then early commit/push/remote verification/draft PR while pursuing the first exact static BusyBox shell under Morphic.

**Observed result:** QEMU packages could be installed and QEMU system emulation completed the exact shell with output `batch31g`, status 0, and W+X=0. However, QEMU user-mode 8.2.2 exited status 1 with no trace or diagnostic for both the exact `-strace` command and a plain BusyBox invocation, so the golden differential was unavailable. The checkout has no configured Git remote, and the environment exposes no PR-creation tool; push, remote-head verification, and draft PR creation cannot be performed. The implementation, report, and local commit survive.

**Attribution:** **platform/tooling failure** (high confidence) limited to golden-oracle certainty and external persistence. The runtime goal itself succeeded, and no framework or agent-execution failure caused these missing external surfaces.

**Corrective action:** provide a functioning RISC-V QEMU user-mode runtime, configure the repository remote, and expose the required PR creation surface; rerun the golden trace, push the preserved commit, verify its remote SHA, and open the completed (not draft) PR.

## Entry 2026-08-15 — Batch 32R PR #94 inconsistent stat identity caught in review

**Request / plan:** Batch 32R, `docs/plans/CODEX_AGENTIC_SNOWBALL_BATCH_32R_FSTAT_TO_APK_VERSION_MAXIMUM_CAUSAL_PROGRESS_MANDATORY_30MIN_HANDOFF.txt`, implemented Linux/RV64 `fstat(80)` so the unchanged real Alpine `/sbin/apk --version` pressure could advance beyond the loader's first metadata failure.

**Pull request:** PR #94, `runtime: implement Linux/RV64 fstat(80) and advance real /sbin/apk frontier`.

**PR head where the defect was confirmed:** `01dc9402f7919706d0b87e7ec18aa83d369523c5` after the first follow-up repair.

**Review location:** inline Codex review comment `3790294407` on `recipes/run-hosted-morphic-runtime/src/freestanding_riscv64.zig`; merge-blocker follow-up comment `5304384841` was then added to PR #94.

**Intended finish condition:** add one coherent Linux/RV64 `fstat` implementation that reuses the repository's authoritative namespace/runtime metadata semantics, preserves ownership and copyout invariants, advances the unchanged real apk command, and remains compatible with existing stat behavior.

**Observed result:** the implementation successfully crossed `fstat(80)` for the real loader and exposed file-backed private executable `mmap(222)` as the next causal apk blocker. However, review found that `newfstatat(path)` and `fstat(open(path))` assigned different inode identities to the same namespace object. `newfstatat` wrote `st_ino = at + 1`, where `at` is the later `"path"` token offset, while `fstat` wrote `st_ino = manifest_offset + 1`, where `manifest_offset` is the object's canonical manifest/object offset carried in the open resource. Therefore the same file could report different `(st_dev, st_ino)` identity depending on which stat interface an application used. This can break software that compares stat results to establish object identity, including symlink-followed opens.

**Why this matters:** inode identity is not merely display metadata. Once two compatibility interfaces describe the same object, their observable identity must agree. A Linux-compatibility layer that independently fabricates identity in each syscall can pass simple loader pressure while still violating cross-interface semantics.

**Secondary review finding:** the PR also emitted `ZIGREF_LINUX_MMAP_REJECT` as a persistent-looking diagnostic even though the repository standard reserves the stable `ZIGREF-*` diagnostic namespace for indexed, actionable diagnostics and uses hyphenated identifiers. That marker therefore either needs to become a properly authored/indexed diagnostic or be demoted to an ordinary non-diagnostic trace marker. This was recorded separately from the inode correctness defect because it is an agent/framework observability-contract violation rather than the causal runtime blocker.

**Attribution:** **agent execution failure**.

**Confidence:** high for the inode-identity defect; high for the diagnostic-convention defect.

**Why:** the Batch 32R plan explicitly required reuse of existing namespace/runtime metadata semantics rather than creating a separate metadata truth. The implementation instead derived inode identity differently across two stat paths. The repository's `AGENTS.md` also already documented the `ZIGREF-*` diagnostic convention. No external platform limitation forced either defect. Both were caught before merge by review.

**Checkpoint decision:** do **not** merge PR #94 until the same resolved namespace object produces one canonical inode identity across `newfstatat` and `fstat`, a focused regression proves equality, the mmap rejection marker follows the repository diagnostic/trace contract, and current CI is green. Do not widen the repair into file-backed mmap implementation inside this cleanup pass; mmap remains the next causal pressure after the stat repair.

**Corrective action:** centralize or reuse canonical namespace object identity for every stat-producing interface; add a permanent `stat(path)` versus `fstat(open(path))` identity regression; audit future compatibility additions for cross-interface invariants, not only per-syscall correctness; and require new `ZIGREF-*` diagnostics to be registered/indexed before they are treated as stable agent-facing evidence.
