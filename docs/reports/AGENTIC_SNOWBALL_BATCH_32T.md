# Agentic Snowball Batch 32T handoff

## Boundary

This slice started from current `main` history containing checkpoint
`80fd25c84eeb464c7813491e5a95bbe370bfcc31` (with the Batch 32T plan commit on
top). The repository bootstrap succeeded; doctor found Zig 0.14.0 and the
inherited missing `.venv`. Implementation commit is
`2c67990a87b885f77a603d1f8f294dd6b3654ecf`; the final persistence commit is the
commit containing this report.

## Inherited mmap defects and focused proof

The file-backed MAP_PRIVATE planner now rejects, before reservation or mapping,
a request whose rounded mapping crosses from the permitted final partial file
page into a complete page beyond EOF. Its regression copies the two available
bytes of a six-byte file into the final four-byte page, proves the two-byte tail
is zero, and proves that requesting one byte into the following page returns
`FileRange`. Thus the bounded implementation does not turn a wholly-beyond-EOF
page into ordinary readable zero storage.

The same compatibility edge now deliberately returns `InvalidArgument` for
PROT_NONE and write-only mappings. The current Sv39 path cannot encode a
write-only leaf and does not model an inaccessible PROT_NONE reservation; both
shapes therefore fail deterministically at planning instead of becoming a
misleading mapper/ENOMEM failure. Focused tests permanently cover both cases.
Existing W+X rejection, checked arithmetic, immutable source copying,
descriptor state/ownership, PREPARE -> COMMIT, and rollback tests remain in the
Morphic recipe gate.

## Capacity mechanism

The prior trace established that libcrypto's `0x3b6000` mapping needs about 950
pages while the shared image/brk/mmap backing had only 320 pages. The runtime
now provisions a distinct monotonic 1,024-page private-file pool. Capacity is
checked before reserve/prepare/map, committed only after successful mapping,
and reset when exec removes the old runtime mappings. This is a general bounded
mapping-class resource rather than a path or library special case, and it
prevents a large shared object from consuming exec/brk backing. Caller-artifact
transport moved from `0x81000000` to `0x82000000`; the linker assertion and the
successful canonical namespace-backed build prove that transport and prepared
reservation do not overlap.

## Exact pressure and results

The canonical Alpine acquisition command completed and re-established 517
objects, 7,069,903 regular bytes, namespace SHA-256
`7672a8c49fbd75071a6390a55e227927254afe1eabdad969315414332e5b989b`, BusyBox
SHA-256 `4567ce8a67afd045a9be46745236cf6fca0347f70871a2492c94c166eada856e`,
and musl SHA-256
`f65dfa1e845af4d8c57f5274a8abac7a8c150372b014fb413e44f4cc70050de1`.
The exact namespace-backed install command then succeeded with the new layout.

The unchanged retry was attempted as:

```text
{ sleep 8; printf '/sbin/apk --version\n'; sleep 10; } | timeout 25s qemu-system-riscv64 -machine virt -nographic -bios default -kernel /tmp/alpine-machine/bin/morphic-freestanding-riscv64
```

It could not start: this environment has no `qemu-system-riscv64` executable
(exit 127). Consequently there was no guest trace and no evidence-backed next
runtime repair to admit. `/sbin/apk --version` did **not** succeed; `--help` and
`apk info` were not reached. The Playable Alpine sequence also could not be
re-proved for the same environment limitation. No result is silently promoted
to a pass.

## Validation

Passed:

- `zig build test-recipe-run-hosted-morphic-runtime`
- the canonical namespace artifact acquisition
- `zig build install-freestanding-riscv64-morphic-runtime` with the real
  namespace, `/bin/sh`, and live console options
- `PYTHONDONTWRITEBYTECODE=1 python3 tools/check-command-reference.py --check`
- `git diff --check`

The first combined recipe/install attempt usefully failed after the recipe
regression exposed a stale test expectation and the linker proved the initial
larger reservation overlapped caller transport. The test was corrected to the
actual final-partial-page boundary, capacity was separated by mapping class,
and transport was moved; both commands then passed.

Changed files are `COMMANDS.md`, this report, the freestanding linker script,
and `recipes/run-hosted-morphic-runtime/src/{freestanding_riscv64.zig,linux_rv64_file_mmap.zig}`.

**Exactly one next causal blocker:** restore an environment with
`qemu-system-riscv64` and rerun the unchanged `/sbin/apk --version` command to
observe and classify the first guest failure after the now-build-proven
1,024-page private-file capacity repair; do not guess at the downstream fixed
mapping or relative-symlink candidates before that trace.
