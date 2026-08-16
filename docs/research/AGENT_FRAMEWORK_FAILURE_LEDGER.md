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

**Attribution:** **platform/tooling failure** (high confidence). The plan was actionable, and the agent performed the available persistence and focused implementation work; externally required Git, Node.js, and emulator surfaces were absent.

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

## Entry 2026-08-15 — Batch 32S PR #95/#96 file-backed mmap semantic defects caught in review

**Request / plan:** Batch 32S, `docs/plans/CODEX_AGENTIC_SNOWBALL_BATCH_32S_STAT_IDENTITY_AND_FILE_BACKED_MMAP_TO_APK_VERSION_MAXIMUM_CAUSAL_PROGRESS_MANDATORY_30MIN_HANDOFF.txt`, was intended to repair the inherited stat-identity/diagnostic debt and then implement the smallest general file-backed `MAP_PRIVATE mmap(222)` semantics required by the real Alpine loader while preserving Linux-compatible bounds, permissions, rollback, ownership, and W+X=0.

**Pull requests:** PR #95 (`runtime: unify stat identity and add bounded file-backed MAP_PRIVATE mmap (Batch 32S)`) first introduced the implementation. The merge-clean re-run appeared as PR #96 (`Add file-backed MAP_PRIVATE planning and runtime mapping; refine namespace stat identity and mmap diagnostics`) at head `aaf8f63eaae7ce45e85f5e0060d2217655f74f7d`.

**Review locations:** the first Codex review on PR #95 recorded inline findings `3790408750` (whole pages past EOF becoming readable zero pages) and `3790408757` (unsupported protection modes accepted by the planner). The same implementation defects were re-confirmed on PR #96 and summarized in review `4944941980` before merge.

**Intended finish condition:** file-backed private mappings must be bounded and Linux-coherent for the admitted slice: validate the requested file range, copy only authoritative file bytes, zero only the legitimate tail of the final file-backed page, preserve immutable source bytes and descriptor state, reject or deliberately model protection modes the Sv39 layer cannot represent, preflight capacity/collisions, and roll back without leaks on mapping failure.

**Observed result — defect 1, pages wholly beyond EOF:** `plan()` computes `byte_length = min(length, file_size - offset)` but retains `mapped_length = roundUp(length, page_size)`. `mapPrivate()` then installs every page in `mapped_length`, while `prepare()` zero-fills the entire destination before copying only `byte_length` file bytes. A request extending by one or more complete pages beyond EOF can therefore expose those wholly-past-EOF pages as readable zero-filled memory. Linux file mappings only provide zero-fill for the remainder of the final partial file-backed page; pages wholly beyond the underlying file must not silently become fabricated readable file contents. Because this runtime does not yet provide the corresponding SIGBUS/page-fault semantics, the bounded implementation should reject such a range or leave those pages unmapped rather than inventing contents.

**Observed result — defect 2, unrepresentable protection modes:** the planner accepts any R/W/X combination except W+X. That includes `PROT_NONE` and write-only `PROT_WRITE`. The current Sv39 leaf encoder cannot directly install a user leaf with neither R nor X, and RISC-V leaf semantics do not permit W without R. As a result, syntactically accepted mmap requests can perform preparation/reservation work and later fail in the page-table layer, surfacing as a generic mapping/ENOMEM-style failure rather than a deliberate compatibility decision. The compatibility edge must either reject these unsupported modes deterministically before mutation, reserve `PROT_NONE` without installing a leaf, or normalize Linux write permission into an explicitly documented representable Sv39 policy.

**Why this matters:** both defects are cross-layer semantic failures that ordinary happy-path tests and even green repository CI can miss. The implementation can advance the real loader and prove rollback while still exposing file bytes or protection behavior that Linux would not. This is exactly the class of compatibility bug the failure ledger is meant to preserve: successful causal progress does not erase semantic debt found by review.

**Observed validation state:** PR #96's GitHub `validate` workflow was green and its report recorded focused ownership/collision/capacity/rollback tests plus a complete Playable Alpine re-proof. Those successes are real, but they did not cover the two semantic gaps above.

**Attribution:** **agent execution failure**.

**Confidence:** high.

**Why:** the Batch 32S plan explicitly required validation of file ranges, requested permissions, deterministic errno, bounded failure atomicity, and Linux-compatible private mappings. No external platform limitation forced the planner to map whole pages beyond EOF or admit protection shapes that the downstream Sv39 implementation cannot encode. Review found both directly in the persisted implementation.

**Checkpoint decision:** do **not** merge the Batch 32S file-mmap PR until both semantic defects are repaired with focused permanent regressions and the full validation workflow remains green. Keep the measured 950-page libcrypto private-backing capacity requirement as the next causal apk frontier; do not mix that capacity expansion into this correctness cleanup.

**Corrective action:** add explicit planner invariants for EOF/page-boundary behavior and representable protection modes; add regressions proving no wholly-past-EOF readable pages are admitted and that `PROT_NONE`/write-only requests receive the chosen deterministic policy before mapping mutation; preserve the current rollback/ownership tests and Playable Alpine gate; then rerun the unchanged real `/sbin/apk --version` only after the merge-clean correctness repair.

## Entry 2026-08-15 — Batch 32T PR #97 private mmap fork/restore ownership defect

**Request / plan:** Batch 32T, `docs/plans/CODEX_AGENTIC_SNOWBALL_BATCH_32T_MMAP_SEMANTICS_TO_APK_VERSION_MAXIMUM_CAUSAL_PROGRESS_FULL_30MIN_BEFORE_HANDOFF.txt`, repaired the inherited mmap semantics and then repeatedly pressured the unchanged real Alpine `/sbin/apk --version` under QEMU.

**Pull request:** PR #97, `fix: bound file-backed MAP_PRIVATE EOF/protection semantics and add private-file backing pool`.

**Merged checkpoint:** PR #97 was intentionally merged to advance the project at merge commit `cf87c3b8b5b8b32609cea2d30636aad69a9aacfb`, from PR head `5bcf7ce2a536bfdde5b4d5798351dea6ceb49703`. The merge message explicitly records the known defect and hands it to the next Codex run; this merge is not a claim that fork/clone restoration is correct.

**Review location:** Codex inline review comment `3790537879` on `recipes/run-hosted-morphic-runtime/src/freestanding_riscv64.zig` (review `4944974587`).

**Useful progress preserved by the checkpoint:** QEMU-capable continuation crossed the corrected file-backed EOF reservation semantics, exact `MAP_PRIVATE|MAP_FIXED` replacement for loader segments, and Linux/RV64 `munmap(215)`. The runtime mapping-table bound rose from 8 to 16, private-file backing from 1,024 to 2,048 pages, Playable Alpine was re-proved, and the unchanged apk frontier advanced to a deterministic first `libcrypto` `ENOMEM` while the separate relative `libz.so.1` `ENOENT` remained downstream.

**Observed defect:** file-backed private pages now live in `external_private_file_backing`, with a separate allocation cursor, but the supported fork-shaped `clone` parent snapshot/restore path still snapshots the old prepared backing state and cursor. When a dynamically linked parent forks, the child may `execve`, which resets/reuses the private-file pool. On child termination, the parent runtime mappings can then be restored from the wrong backing class or overwritten bytes. The mapping topology may look valid while the parent's shared-library contents are silently wrong.

**Why this matters:** this is a process-lifetime ownership defect, not merely a capacity issue. A compatibility layer must preserve the bytes and backing identity of the parent's mappings across the supported fork/child-exec/parent-restore cycle. Passing loader startup and Playable Alpine does not prove that invariant because the acceptance sequence does not exercise a dynamically linked parent carrying private file mappings through that lifecycle.

**Attribution:** **agent execution failure**.

**Confidence:** high.

**Why:** the Batch 32T implementation introduced a second backing class without extending the already-supported process snapshot/restore contract to carry that backing class and cursor. No platform limitation forced the omission. Automated review identified the mismatch directly in persisted runtime state management.

**Checkpoint decision:** intentionally merge PR #97 as an annotated causal-progress checkpoint at `cf87c3b8b5b8b32609cea2d30636aad69a9aacfb`, then hand the known ownership defect to the next fresh Codex run. The next run must repair and prove backing-class-aware snapshot/restore first, then immediately resume real `/sbin/apk --version` pressure instead of treating the cleanup as the endpoint.

**Corrective action:** represent enough backing identity in runtime mappings or process snapshots to distinguish prepared-image backing from private-file backing; snapshot and restore the private pool plus cursor across fork-shaped clone; add a focused regression where a parent with file-backed private mappings forks, the child execs/exits, and the parent resumes with byte-identical mappings; re-prove Playable Alpine; then rerun unchanged `/sbin/apk --version` and continue causal repairs through the full useful ~30-minute slice before final handoff.

## Entry 2026-08-15 — Batch 32U PR #98 merged with stale validation-evidence digest

**Request / plan:** Batch 32U, `docs/plans/CODEX_AGENTIC_SNOWBALL_BATCH_32U_FORK_PRIVATE_MMAP_RESTORE_TO_APK_MAXIMUM_CAUSAL_PROGRESS_FULL_30MIN_BEFORE_HANDOFF.txt`, repaired the inherited fork/private-file mapping restore defect and then continued real QEMU apk pressure. A follow-up repaired two P1 review findings around PROT_NONE `mprotect` transitions and fixed-anonymous replacement failure atomicity.

**Pull request:** PR #98, `Fix fork-shaped private-file mmap restore; record backing classes and advance apk runtime progress`.

**PR head carrying the validation debt:** `08ed237f00923bb915babe0d48ff310e3a16ac5c`.

**Intentional merge checkpoint:** PR #98 was merged at `2bbe272e4b3b3ded824bd3d3a64b60be0f267b1f`. The merge commit message explicitly states that this is a progress checkpoint and that the remaining validation-evidence regeneration is handed to the next Codex run. This merge is not a claim that CI was green.

**GitHub Actions evidence:** workflow run `31926416535`, job `95114607166` (`contracts-and-zig`), completed with failure. The failing step was `zig build check`. The concrete error was `validation evidence error: fixed-capacity-vector: stale source digest; regenerate validation evidence`, emitted by `python3 tools/python-environment.py tools/record-validation.py --check`. The same job reported `71/74 steps succeeded`, `30/30 tests passed`, canonical formatting passed, 60 contracts validated, dependency graphs/indexes passed, and repository policy passed.

**Useful progress preserved by the checkpoint:** the Batch 32U report records that real `/sbin/apk --version` succeeded with `apk-tools 2.14.9, compiled for riscv64`, `/sbin/apk --help` reached real apk output, `apk info` progressed through dependency loading and RELRO to a deterministic musl `memset` store fault at destination `0x8`, the inherited fork/private-mmap restore defect was repaired, both P1 review findings were repaired with focused tests, and the canonical Playable Alpine persistent-shell gate was re-proved.

**Observed failure:** repository-owned generated validation evidence was not regenerated/persisted after source/build wiring changed, so the PR head failed the canonical `zig build check` evidence-digest gate even though runtime tests and the real-QEMU pressure evidence were useful.

**Attribution:** **agent execution failure**.

**Confidence:** high.

**Why:** stale validation evidence is a deterministic repository-owned derived-artifact obligation. The run had a viable local path to regenerate it and no external platform/tool failure prevented that operation. The follow-up also reported local validation success, but the externally authoritative PR workflow disproved completeness. This is therefore a persistence/completeness failure, not a framework or platform failure.

**Checkpoint decision:** intentionally merge PR #98 at `2bbe272e4b3b3ded824bd3d3a64b60be0f267b1f` to preserve the major apk-version milestone and the substantial runtime repairs. The next run must first regenerate and verify canonical validation evidence from current main, get `zig build check` green, and then immediately resume the unchanged real `apk info` frontier rather than spending an entire batch on validation cleanup.

**Corrective action:** regenerate canonical validation evidence using the repository's established tooling; run `zig build check`, repository validation, command-reference checks, and formatting from current main; persist all required generated/evidence changes; then immediately rebuild the real Alpine machine and continue causal `apk info` repair/retry pressure through the full useful ~30-minute window before final handoff.