# Agentic Snowball Batch 32R handoff

## Persistence boundary

Work began on branch `work` at commit `19a38fc` (`docs: add Batch 32R apk
fstat snowball plan`) at `2026-08-15T21:09:51Z`. The opening agent doctor
confirmed Zig 0.14.0 and current generated indexes, but reported the inherited
missing `.venv/bin/python`. This handoff and the coherent implementation are
committed together on the current branch.

## Opening failure and repair

The exact inherited `/sbin/apk --version` trace opened
`/usr/lib/libcrypto.so.3` and `/usr/lib/libapk.so.2.14.9`, then rejected
Linux/RV64 syscall 80 (`fstat`) with `ENOSYS`. The dynamic loader consequently
reported `Function not implemented`; its relocation errors were downstream.

The Linux edge now decodes fstat(80), resolves the descriptor through the
existing binding table and resource table, and accepts the namespace directory
and regular-file backends actually used by the loader. It derives stable inode,
kind, and regular-file length from the already-authoritative bounded namespace
manifest, encodes the 128-byte asm-generic RV64 stat layout, and uses the
existing checked user-memory copyout. Invalid descriptors return `EBADF`,
unsupported resource classes fail closed, malformed metadata returns `EIO`,
and copyout failure returns `EFAULT`. The operation neither changes shared
resource state (including offset) nor creates/releases a descriptor or
resource. There are no apk, library-name, path, fd, or payload special cases.

The new focused tests prove coherent regular-file encoding, including block
count rounding, explicit copyout failure, and deterministic Linux `EBADF` for
an unbound descriptor while resource count, reference count, binding topology,
and resource state remain unchanged. Decoder coverage is retained by the
freestanding compile-time drift assertion. The new test is part of
`zig build test-recipe-run-hosted-morphic-runtime`.

## Exact real-QEMU evidence

The Alpine v3.22.0 RV64 namespace was regenerated with:

```text
rm -rf /tmp/zigref-namespace /tmp/alpine-machine
PYTHONDONTWRITEBYTECODE=1 python3 tools/pressure-real-rv64-alpine-minirootfs.py --artifact-only --namespace-output-dir /tmp/zigref-namespace
zig build install-freestanding-riscv64-morphic-runtime -Dexternal-rv64-namespace-manifest=/tmp/zigref-namespace/namespace.json -Dexternal-rv64-namespace-data=/tmp/zigref-namespace/namespace.data -Dexternal-rv64-argv0=/bin/sh -Dexternal-rv64-live-console-input=true --prefix /tmp/alpine-machine
```

Acquisition verified 517 objects, 7,069,903 regular-file bytes, namespace-data
SHA-256 `7672a8c49fbd75071a6390a55e227927254afe1eabdad969315414332e5b989b`,
BusyBox SHA-256 `4567ce8a67afd045a9be46745236cf6fca0347f70871a2492c94c166eada856e`,
and musl SHA-256
`f65dfa1e845af4d8c57f5274a8abac7a8c150372b014fb413e44f4cc70050de1`.
System QEMU was initially absent; installing Ubuntu's `qemu-system-misc`
provided `qemu-system-riscv64` 8.2.2. The exact pressure was injected into:

```text
qemu-system-riscv64 -machine virt -nographic -bios default -kernel /tmp/alpine-machine/bin/morphic-freestanding-riscv64
/sbin/apk --version
```

The unchanged retry no longer reports unsupported syscall 80 or `Function not
implemented`. It opens both libraries and directly exposes these rejected
requests:

```text
libcrypto: mmap address=0 length=0x3b6000 protection=0x5 flags=0x2 fd=3 offset=0
libapk:    mmap address=0 length=0x02c000 protection=0x5 flags=0x2 fd=3 offset=0
```

Both are file-backed `MAP_PRIVATE` executable mappings. The loader reports
`Invalid argument`, so the later relocation list remains downstream. A compact
`ZIGREF_LINUX_MMAP_REJECT` trace was retained to make all six causal request
arguments deterministic and locally visible.

`/sbin/apk --version` therefore **did not succeed**. `--help` and `info` were
not reached, as required by the pressure ladder. Unsupported calls 96
(`set_tid_address`), 134 (`rt_sigaction`), 135 (`rt_sigprocmask`), and 226
(`mprotect`) were observed. The first three remain proven non-causal through
exec and library opening; mprotect is downstream and not yet classified.
`libz.so.1` also still reports `ENOENT`, but it is not the first causal blocker
while earlier opened dependencies cannot be mapped.

## Validation and changed files

Passed during implementation:

- `zig test recipes/run-hosted-morphic-runtime/src/linux_rv64_fstat.zig`
- `zig build test-recipe-run-hosted-morphic-runtime`
- the canonical namespace artifact verification and namespace-backed
  freestanding build above
- two real system-QEMU retries of the unchanged command

The PR #94 validation repair regenerated all 60 canonical unit/smoke evidence
records after the root build wiring changed, then passed the focused Morphic
recipe tests, `zig fmt --check build.zig projects recipes conformance`,
`zig build check`, and
`python3 tools/developer-command.py validate-repository` under Zig 0.14.0.
This repair does not change the measured QEMU frontier described above.

The final assembly also runs formatting, command-reference, diff, focused, and
available aggregate checks; their exact outcomes are recorded in the final
response. Changed files are `build.zig`, `COMMANDS.md`, this report,
`recipes/run-hosted-morphic-runtime/recipe.json`, and the two runtime source
files `freestanding_riscv64.zig` and `linux_rv64_fstat.zig`.

## One next pressure

Implement the smallest bounded general file-backed `MAP_PRIVATE` mapping for an
already-open namespace regular resource, preserving mapping/table preflight,
checked file-range arithmetic, private bytes, requested R/W/X permissions,
W+X=0, offset semantics, rollback, and resource ownership. Add focused
capacity/range/rollback tests, then immediately rerun the unchanged real
`/sbin/apk --version` command and classify only its next observed blocker.
