# Agentic Snowball Batch 32U handoff

## Boundary and inherited defect

The useful slice ran from 2026-08-16 02:17 UTC through approximately 02:43
UTC, followed only by final persistence and handoff work. It started from
current main history containing historical checkpoint
`cf87c3b8b5b8b32609cea2d30636aad69a9aacfb`. PR #97 review comment
`3790537879` was the inherited P1 evidence: fork-shaped parent restoration did
not preserve the newly separate private-file mapping backing class, bytes, or
cursor across child exec/reset/reuse.

The implementation commit is
`6059c4afc8a21dd820dcb7128ac8d62668fb9a37`; the final report commit is the
commit containing this file.

## Fork/private-mapping repair and permanent proof

Runtime mapping records now carry neutral backing identity (`none`,
`prepared`, or `private_file`) and the first backing-page index. Range release,
fixed replacement, protection splitting, and snapshots preserve that identity
and adjust the right-hand backing cursor rather than reconstructing every
mapping from prepared/image backing. File MAP_PRIVATE and anonymous mappings
record their actual class at commit.

Fork now copies the allocated prefix of the parent's private-file pool into a
separate bounded snapshot and records its cursor. Child exec remains free to
reset and reuse the live pool. Parent termination restoration copies back the
saved bytes/cursor, restores the stack backing, and maps each runtime range
from its recorded backing class. Resource, binding, cwd, image, stack, break,
and mapping snapshots remain in the existing lifecycle.

Focused permanent tests prove that child reset/reuse cannot change saved
private bytes or the parent cursor, that a copied mapping table retains private
backing identity, that release splitting advances the right-hand backing
offset, that fixed replacement records private backing, and that protection
splitting retains offsets. The recipe gate passed with these tests and the
existing PREPARE -> COMMIT, rollback, ownership, SUM-clear, and W+X=0 proofs.

## Causal APK loop

The exact Alpine v3.22.0 namespace was regenerated (517 objects and 7,069,903
regular bytes), and the same namespace-backed live-console machine was rebuilt
before each meaningful pressure retry. One initial console attempt lost the
leading slash during early SBI input and ran `sbin/apk`; it is not counted as
an unchanged command retry.

The unchanged `/sbin/apk --version` retries after the opening repair were:

1. Retry 1 exposed the required stage identity:
   `ZIGREF_MMAP_ENOMEM stage=private-backing-capacity mappings=8
   private_cursor=0x526 prepared_cursor=0x14`. This identifies the first
   libcrypto ENOMEM as the private-file backing pool, not the mapping table,
   virtual search, or an assumed page-table failure.
2. Retry 2, after raising that class-specific bound from 2,048 to 3,072 pages
   and moving caller transport to `0x83000000`, crossed the capacity check and
   exposed the loader's fixed anonymous RW replacement (`MAP_FIXED |
   MAP_ANONYMOUS | MAP_PRIVATE`) plus relative `libz.so.1` resolution.
3. Retry 3 admitted bounded fixed anonymous replacement only inside an owned
   reservation. It crossed that request and retained a relocation failure
   because the relative library symlink was still unresolved.
4. Retry 4 added bounded parent-relative final-symlink resolution, including
   dot and dot-dot normalization and the existing 16-traversal limit. It loaded
   `/usr/lib/libz.so.1 -> libz.so.1.3.1` and exposed Linux/RV64 mprotect(226).
5. Retry 5 initially proved mprotect was required for interpreter RELRO at
   `0x40094000` and failed closed while only runtime mappings were owned.
6. Retry 6 admitted mprotect only across pages owned by the current image,
   interpreter, break, or runtime mapping, preserves physical backing, rejects
   W+X, and performs SFENCE.VMA/FENCE.I. It then identified the next ENOMEM as
   `stage=page-table-map`, rather than private backing capacity.
7. Retry 7 raised the already dedicated PREPARE table-frame bound to 32 and
   succeeded: real `/sbin/apk --version` printed
   `apk-tools 2.14.9, compiled for riscv64.` No apk, library, path, address, or
   descriptor special case was added.

After version success, `/sbin/apk --help` was invoked immediately and reached
real apk execution/output (it printed the apk-tools identification line). A
following restored-parent command printed `PARENT_ALIVE`. A second child in
that same shell later exposed a parent write page fault at `0x80400168`, so a
complete help listing is not claimed. A fresh `apk info` invocation crossed
all four real dependency loads and RELRO but then faulted in musl `memset`
(PC `0x4004df9a`, store address `0x8`); package listing success is not claimed.
A bounded TIOCGWINSZ experiment did not move that fault and was reverted.

Thus `/sbin/apk --version` succeeded. `--help` and `apk info` were both reached
and pressured, but neither is claimed as a fully successful ladder step.

## Playable Alpine safety gate

The final real-QEMU persistent-shell gate preserved both `morphic` and
`second`, `/`, the real root listing, Alpine `3.22.0`, `/tmp`, redirection
read-back `hello`, pipeline `hello`, and `still-alive`. The host timeout ended
the deliberately persistent machine after those outputs.

## Validation and changed files

Executed commands/checks:

- `python3 tools/query-reference.py agent bootstrap`
- `python3 tools/query-reference.py agent doctor` (initial missing `.venv`,
  then PASS after bounded environment repair)
- `zig version`
- `qemu-system-riscv64 --version` (QEMU 8.2.2)
- `PYTHONDONTWRITEBYTECODE=1 python3 tools/pressure-real-rv64-alpine-minirootfs.py --artifact-only --namespace-output-dir /tmp/batch32u-namespace`
- `zig build test-recipe-run-hosted-morphic-runtime`
- the documented `zig build install-freestanding-riscv64-morphic-runtime ...`
  command with the real namespace, `/bin/sh`, and live console, before each
  runtime pressure round
- repeated real system-QEMU `/sbin/apk --version`, then `--help`, `apk info`,
  and the Playable Alpine gate described above
- `zig build check --summary all`
- `python3 tools/developer-command.py validate-repository`
- `PYTHONDONTWRITEBYTECODE=1 python3 tools/check-command-reference.py --check`
- `git diff --check`

Changed files are `COMMANDS.md`, this report,
`recipes/run-hosted-morphic-runtime/freestanding-riscv64.ld`, and
`recipes/run-hosted-morphic-runtime/src/{bounded_fork_private_backing.zig,bounded_namespace_lookup.zig,bounded_runtime_mappings.zig,freestanding_riscv64.zig,linux_rv64_file_mmap.zig}`.

**Exactly one next causal blocker:** determine why fresh real `apk info`, after
successful dependency loading and RELRO, calls musl `memset` with destination
`0x8` (store page fault at PC `0x4004df9a`); repair only the first causal
producer of that null-derived destination, then rerun unchanged `apk info` and
the multi-child parent-restoration ladder immediately.

## PR #98 P1 review follow-up

This continuation started at 2026-08-16 03:26 UTC from the supplied PR worktree
(the requested remote head `21c722521308ad836a300921a80ebf61259afa34` was not
present in this checkout and no remote was configured). It repaired both P1s
before resuming QEMU pressure.

Runtime mapping backing identity is now independent of current accessibility.
A PROT_NONE reservation without backing receives zeroed bounded prepared
backing before an RW/R/RX transition; a backed mapping changed to PROT_NONE
keeps its class and offset, installs no leaf, and can be re-enabled from the
same bytes. Runtime mprotect snapshots topology/cursor and prior leaves, rolls
back on unmap/map failure, rejects W+X, and fences only after success. Focused
tests cover unbacked PROT_NONE -> RW and backed RW -> PROT_NONE -> R while
retaining the original backing offset.

Fixed anonymous replacement now captures prior leaf physical addresses and
permissions, prepares zeroed backing, and uses a neutral failure-atomic
replacement transaction. A mid-map failure removes attempted leaves, restores
prior leaves and mapping metadata, and leaves the caller-owned cursor
unchanged. Its deterministic forced-failure test proves topology, bytes,
leaves, and cursor conservation. The focused recipe step now executes these
tests and the previously added fork-private snapshot test directly.

Real QEMU then re-proved `/sbin/apk --version` with exact output
`apk-tools 2.14.9, compiled for riscv64.` and a following parent-shell marker.
`/sbin/apk --help` again reached real apk and printed the identification line,
then the inherited post-child parent store fault at `0x80400168`; a full help
listing is not claimed. Fresh `apk info` was retried once unchanged: all four
dependencies and RELRO completed, then the same musl `memset` PC
`0x4004df9a` stored to `0x8`. No speculative syscall repair was admitted.

The canonical Playable Alpine gate passed again with `morphic`, `second`, `/`,
the real root listing, `3.22.0`, `/tmp`, both `hello` results, and
`still-alive` before the bounded host timeout.

Follow-up validation executed `zig build test-recipe-run-hosted-morphic-runtime`,
the canonical namespace acquisition and namespace-backed install, the real
version/help/info/Playable QEMU commands, `zig build check --summary all`,
`python3 tools/developer-command.py validate-repository`, the command-reference
check, and `git diff --check`. Changed files are `build.zig`, `COMMANDS.md`,
this report, `bounded_runtime_mappings.zig`, `freestanding_riscv64.zig`, and
new `bounded_mapping_replacement.zig`. The final implementation commit is
`d1f0918d01616c50233df11775596a70efd4f3fe`; the report persistence commit is
the commit containing this follow-up.

**Exactly one next causal blocker:** trace the real fresh-`apk info` call chain
backward from musl `memset` at `0x4004df9a` to identify the first producer of
its null-derived destination `0x8`, repair only that general semantic defect,
and immediately rerun unchanged `apk info`.
