# Agentic Snowball Batch 32W handoff

## Starting frontier and environment

This run started from `d6722a2` (PR #99 merge `efd18a039ce784d837bba03770d8e22e13e74a6b` plus the checked-in Batch 32W plan). Zig was exactly 0.14.0 and system QEMU was 8.2.2. Canonical Alpine v3.22.0 RV64 acquisition again proved 517 objects, 7,069,903 regular-file bytes, archive SHA-256 `ae050812fadcde048e9553004d0d037b2b9c0ec6be09f303db95768a2e35551b`, and namespace-data SHA-256 `7672a8c49fbd75071a6390a55e227927254afe1eabdad969315414332e5b989b`.

## Exact startup diagnosis and bounded repair

The enlarged machine did not merely run slowly. Real QEMU reproducibly completed the cumulative Sv39-permission proof and then shut down before the ordinary U-mode proof. Narrow trap instrumentation showed that the supposedly inactive earlier userspace-ELF branch was selected with all of its expected values zero. ELF symbols placed that corrupted BSS immediately below the explicit supervisor stack. The 584-entry `PreparedImage` metadata values in `executeExternalArtifact` had been inlined into the already large cumulative startup frame, crossing the linker-owned 60 KiB supervisor stack bound and overwriting adjacent state.

The smallest general repair makes external execution an explicit non-inlined phase and builds its two capacity-sized PREPARE metadata values in the already-existing bounded global candidate slots. Capacity remains 584 pages, PREPARE remains failure-atomic, and stack cost no longer scales with that capacity. No allocation or apk-specific branch was added. The focused Morphic recipe test passed, and the rebuilt real machine reached external namespace lookup, PREPARE (`elf`, `image`, `stack`, and `tables`), COMMIT, and execute; the interpreter preflight retained 152 pages and W+X remained forbidden.

## Immediate unchanged apk retry

The immediate real `/sbin/apk --version` retry did not reproduce the inherited successful output. The shell performed its ordinary fork-shaped clone and child execution, then the kernel reported unsupported-but-errno-returned syscall numbers 96, 135, 135, and 134. The next exact failure was a supervisor load page fault: cause 13, PC `0x80208e92`, `stval=0x4001b148`, return address `0x80208e6a`. Host symbolization identifies the PC as `RealPageOwner.owns` through `RealPageOwner.read`; the Sv39 walker was attempting to read a page-table page derived from user virtual page `0x4001b000` rather than an owned physical table page.

Because the first ladder command failed before printing the apk version, `/sbin/apk --version`, `/sbin/apk --help`, and unchanged `apk info` are all **not proved** in this run. The 391-page anonymous allocation was therefore not reached or re-proved. No stronger local apk behavior is claimed. The Playable Alpine gate was not rerun after this new kernel-side fault.

## Validation and exact next blocker

`zig build test-recipe-run-hosted-morphic-runtime` passed after the repair. The exact namespace-backed freestanding build also passed and supplied the QEMU evidence above. All 60 unit/smoke evidence records were regenerated after the source change. Final `zig build check --summary all` passed, and canonical repository validation passed 350/350 steps and 249/249 tests. The command-reference check passed. The repository Python virtual environment was absent at bootstrap, was restored from `tools/requirements.txt`, and the final doctor check passed. The final implementation/report commit is the commit containing this report.

**Exactly one next causal blocker:** determine which page-table state transition installs or corrupts the branch PTE that makes the Sv39 walker treat user virtual page `0x4001b000` as an owned table address during the immediate real `/sbin/apk --version` retry, repair that ownership invariant generally, and rerun unchanged `apk info` immediately after restoring the ladder.
