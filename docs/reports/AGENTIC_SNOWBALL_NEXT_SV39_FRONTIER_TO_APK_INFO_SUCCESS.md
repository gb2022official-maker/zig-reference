# Agentic Snowball: Sv39 frontier toward apk info

## Starting point and environment

This run started from `5193298` on branch `work`; the requested local `main` ref was not present in the worktree. `zig version` reported `0.14.0`; `qemu-system-riscv64` was `/usr/bin/qemu-system-riscv64`, QEMU `8.2.2`.

The Alpine v3.22.0 RV64 namespace was regenerated from the canonical minirootfs command. It proved archive SHA-256 `ae050812fadcde048e9553004d0d037b2b9c0ec6be09f303db95768a2e35551b`, 517 objects, 7,069,903 regular-file bytes, and namespace-data SHA-256 `7672a8c49fbd75071a6390a55e227927254afe1eabdad969315414332e5b989b`.

## Reproduced Sv39 failure

The real unchanged Alpine command was built with live console input and run as:

```text
(sleep 5; printf '/sbin/apk --version\n') | timeout 45 qemu-system-riscv64 -machine virt -nographic -bios default -kernel /tmp/snow/machine/bin/morphic-freestanding-riscv64
```

It reproduced the current frontier after external PREPARE, COMMIT, execute, fork-shaped `clone`, and unsupported errno-returned syscall numbers 96, 135, 135, and 134. The exact edge trap was:

```text
ZIGREF_LINUX_EDGE_TRAP cause=000000000000000d sepc=0000000080208e92 stval=000000004001b148 ra=0000000080208e6a sp=00000000802bd920 gp=00000000000ca800 tp=0000000040097d98 a0=000000004001b000 a1=000000000000001b a2=000000000000001b
```

Host symbolization mapped `sepc=0x80208e92` to `RealPageOwner.owns` and `ra=0x80208e6a` to `RealPageOwner.read`. The first observable invariant violation is that the machine page-table owner accepted user-range address `0x4001b000` as an owned page-table frame, after which the provider attempted to read a PTE at `0x4001b148` and took a supervisor load page fault. The failing walk was at Sv39 4 KiB-table granularity; the root at the preceding proof stage was `0x802da000`, and the live page-table count was `0x1b`.

## Mechanism changed

This slice did not identify the original producer that inserted `0x4001b000` into the runtime owner set. It did add the smallest reusable guard reached by the evidence: page-table traversal now rejects decoded branch PTEs whose target frame is not owned by the page-table owner before descending, and both hosted semantic owners and the real machine owner expose `owns()` for that invariant. The real machine owner additionally refuses low user-range addresses as page-table backing even if corrupted metadata contains them, preventing the supervisor fault from becoming an unchecked physical read.

A focused regression writes a branch PTE to `0x4001b000` directly into a test root and proves `mapPage`, `unmapPage`, and `protect` reject it as `MalformedMapping` rather than descending into a foreign frame.

## Retry result

After rebuilding with the guard, the same `/sbin/apk --version` command no longer printed the supervisor `ZIGREF_LINUX_EDGE_TRAP` line in the captured tail, but it also did not produce the apk version string. The command exited quickly after the same unsupported syscall sequence, implying the remaining parent/child restore path still reaches an unrecovered malformed mapping/shutdown edge rather than completing the shell command. `/sbin/apk --help`, unchanged `apk info`, stronger local apk behavior, and the Playable Alpine regression were not reached in this shortened run.

## Validation

Passed focused validation:

```text
zig build test-riscv-sv39-page-table-builder test-recipe-run-hosted-morphic-runtime
zig build test-recipe-run-hosted-morphic-runtime
```

Final `zig build check --summary all` passed after regenerating unit validation evidence and deterministic indexes. The exact next causal blocker remains: trace the first producer that writes or retains user-range `0x4001b000` in `runtime_page_owner.pages` during the fork/exec/restore sequence, then repair that ownership transition rather than merely rejecting the corrupted state.
