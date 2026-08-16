# Agentic Snowball Batch 32V handoff

## Starting state and validation recovery

This run started from `060adde52e8bf8dd1d88cf3a25ae9f5b73803ce0`, after PR #98 head `08ed237f00923bb915babe0d48ff310e3a16ac5c` and merge `2bbe272e4b3b3ded824bd3d3a64b60be0f267b1f`. The inherited failure was the stale `fixed-capacity-vector` source digest. The canonical all-level generator refreshed `generated/validation/modules.json` for all 60 modules under Zig 0.14.0. Agent doctor initially reported the missing repository virtual environment; it was created from `tools/requirements.txt`.

## Exact Alpine pressure and causal retries

Canonical Alpine v3.22.0 RV64 acquisition produced 517 objects, 7,069,903 regular-file bytes, archive SHA-256 `ae050812fadcde048e9553004d0d037b2b9c0ec6be09f303db95768a2e35551b`, and namespace-data SHA-256 `7672a8c49fbd75071a6390a55e227927254afe1eabdad969315414332e5b989b`. Pressure used QEMU 8.2.2.

Real `/sbin/apk --version` again printed `apk-tools 2.14.9, compiled for riscv64.` Real `/sbin/apk --help` reached the identification output, then the inherited restored-parent store fault; a complete help listing is not claimed. Fresh unchanged `apk info` retries proceeded causally:

1. The musl `memset` fault reproduced at PC `0x4004df9a`, destination `0x8`; narrow trap evidence identified `a2=0x27100` and return address `0x3e9d72`.
2. Result tracing found the first bad producer: anonymous mmap exhausted the 16-entry mapping table. Raising that bounded class exposed incorrect rejection of Linux byte length `0x2711c` for not being page aligned.
3. Checked byte-length rounding made that allocation return `0x500000`. The next producer was an unsupported address-zero anonymous `PROT_NONE` reservation; bounded unbacked reservation crossed it.
4. The next retry measured the mapping-table boundary at exactly 32 entries. The bound is now 64, with focused proof for entry 33.
5. The original `0x2711c` and two later allocations succeeded. The workload advanced to a `memset` length `0x186a00`; its anonymous request failed at cursor 191 because it needs 391 pages beyond the old 320-page backing class. The bound is now 584 (582 measured pages plus two), and exec/fork copies now copy allocated prefixes only.

The final enlarged machine compiled, but did not reach external execution in the bounded final QEMU retry. Therefore `apk info` completion, package-database listing, local `.apk` behavior, and a final Playable Alpine re-proof are **not claimed**.

## General mechanisms, proof, and validation

The repair adds checked Linux mmap length rounding (including zero/overflow rejection), address-zero anonymous PROT_NONE ownership without backing/leaves, a measured 64-entry bounded topology, a measured 584-page prepared/brk/anonymous class, allocated-prefix exec/fork copies, and narrow edge-trap register evidence. Focused tests cover rounding and the thirty-third disjoint mapping; the recipe suite covers unbacked reservation, rollback, identity, W+X rejection, snapshots, and replacement atomicity.

Successful run commands included Zig/QEMU version checks, canonical namespace generation, repeated namespace-backed installs, `zig build test-recipe-run-hosted-morphic-runtime`, and canonical all-level evidence regeneration. Final `zig build check` passed, and canonical repository validation passed 350/350 steps and 249/249 tests. The command-reference and formatting checks also passed; these local results do not claim GitHub CI state.

Changed files are `COMMANDS.md`, `generated/validation/modules.json`, this report, and `recipes/run-hosted-morphic-runtime/src/{bounded_runtime_mappings.zig,freestanding_riscv64.zig}`. The implementation commit is the commit containing this report.

**Exactly one next causal blocker:** determine why the 584-page machine does not reach external PREPARE/COMMIT within the prior bounded QEMU window (remove remaining capacity-proportional initialization if causal), then rerun unchanged `apk info` to verify the admitted 391-page allocation.
