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

The original environment-blocked pressure account is superseded by the QEMU-capable continuation below.

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


## QEMU-capable continuation

The follow-up environment initially exposed a partially installed QEMU package;
a bounded `dpkg --configure -a` completion restored
`/usr/bin/qemu-system-riscv64`, QEMU 8.2.2. The canonical namespace-backed
machine was rebuilt before every runtime retry.

The first unchanged retry crossed the old 1,024-page check but showed
`Value too large for data type`: the new EOF planner was still rejecting the
loader's legal whole-range reservation. The repair now records separate
`mapped_length` and `accessible_length`: the full Linux range is reserved, the
final partial file page is copied and zero-tailed, and complete pages beyond EOF
receive no readable leaf. Focused tests prove the distinction.

The second retry reached the exact fixed file mappings for libcrypto and libapk
(`MAP_PRIVATE|MAP_FIXED`, including libcrypto address `0x353000`, length
`0x77000`, offset `0x33f000`). A bounded fixed replacement path now accepts only
a range already owned by the preceding mapping, prepares private bytes before
replacement, removes existing leaves, installs only file-accessible leaves, and
commits backing after mapping. The neutral mapping table gained tested
non-mutating containment.

The third retry crossed both fixed mappings and exposed Linux/RV64 `munmap(215)`
as `ENOSYS`. A bounded implementation now validates alignment/range, removes
leaves only from runtime-owned mappings, and updates ownership with an atomic,
tested range-release operation that handles entry splitting. The mapping table
bound rose from 8 to 16 and private-file backing from 1,024 to 2,048 pages under
the existing linker separation. The fourth and fifth unchanged retries crossed
`munmap`; they reached libssl and repeated dependency loads. The first
libcrypto load now returns deterministic `ENOMEM`, while relative `libz.so.1`
still returns `ENOENT`. Because the trace does not yet identify which bounded
subresource produces that first ENOMEM, no symlink or later-syscall repair was
guessed.

`/sbin/apk --version` did not succeed. Consequently `--help` and `apk info` were
not reached. The canonical persistent shell was re-proved after the runtime
changes: both echoes, `/`, root listing, Alpine `3.22.0`, `/tmp`, redirection
read-back `hello`, pipeline `hello`, and `still-alive` all appeared before the
host timeout terminated the live guest.

**Exactly one next causal blocker:** add bounded stage-specific failure identity
to the first libcrypto file-mapping transaction, determine which checked
resource returns `ENOMEM` after fixed-map/munmap progress, repair that smallest
general resource, and immediately rerun unchanged `/sbin/apk --version`.
