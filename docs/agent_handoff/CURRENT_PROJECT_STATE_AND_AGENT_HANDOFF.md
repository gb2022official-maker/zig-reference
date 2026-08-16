# Morphic / zig-reference — Current Project State and Agent Handoff

> **Purpose:** This document is the single broad-context handoff for a new engineering agent entering the repository cold. It explains what the project is, why it exists, what has actually been proved, what must never be casually broken, the current runtime frontier, the agent workflow, the short- and long-range goals, and the exact style of progress expected from future runs.
>
> **Current checkpoint:** main after PR #100, merge commit `e0e315219c60075ce81549e3eda657b04a6723f6`.
>
> **Immediate engineering objective:** repair the current Sv39 page-table ownership/state-transition fault exposed by the unchanged real Alpine `/sbin/apk --version` ladder, restore the previously earned apk-version path, and then continue directly toward successful `apk info` and stronger package-manager behavior. Do not stop after one local fix if useful engineering time remains.

---

# 1. What this repository is

`zig-reference` began as a reference-oriented Zig systems repository, but its most ambitious active line is now **Morphic**: a very small freestanding RISC-V runtime/substrate that can host an increasingly Linux-compatible userspace personality without simply embedding the Linux kernel.

The core experiment is:

> How much real Linux userspace can a deliberately small, bounded, inspectable substrate run by implementing the Linux/RV64 userspace contract directly and only admitting mechanisms when real software proves they are needed?

This is not intended to be a fake shell, a scripted compatibility demo, or a bespoke apk emulator. The standard is **unchanged real binaries and real causal pressure**.

The current system has already crossed the threshold from synthetic examples into real Alpine userspace:

- canonical Alpine v3.22.0 RV64 namespace data is used;
- real dynamic musl/BusyBox userspace executes;
- a persistent shell works;
- cwd, files, redirection, pipes, child exec/fork-shaped behavior, dynamic ELF loading, mmap/mprotect/munmap behavior, and shared libraries have all been exercised under real QEMU pressure;
- the real Alpine package manager has previously executed `/sbin/apk --version` successfully and printed `apk-tools 2.14.9, compiled for riscv64`;
- `/sbin/apk --help` reached apk output;
- `apk info` has entered real package-manager execution and has repeatedly driven the admission of more general mmap/topology semantics.

The repository deliberately prefers **small general mechanisms** over broad speculative implementation.

---

# 2. The architectural idea in one picture

```text
                unchanged Linux/RV64 userspace
                           │
                 Alpine / musl / BusyBox
                           │
                         apk
                           │
                  Linux UAPI personality
                           │
                  syscall / ELF / VM edge
                           │
                    ┌─────────────┐
                    │   MORPHIC   │
                    └─────────────┘
                           │
               bounded neutral mechanisms
                           │
              Sv39 / frames / traps / I/O
                           │
                       RISC-V 64
```

Morphic should remain understandable enough that an agent can reason about the entire causal path rather than treating the runtime as an opaque pile of subsystems.

The long-term attraction is not merely "another tiny OS." The project is exploring a compact machine/runtime architecture where:

1. a Linux personality can run ordinary Linux software without requiring the Linux kernel itself for that interface;
2. the same small substrate can later host other personalities or execution models;
3. the system is bounded and explicit enough for AI-assisted whole-system reasoning;
4. compatibility grows from observed real workloads rather than from blindly copying all of Linux.

---

# 3. What Morphic is NOT

A new agent should internalize these boundaries immediately.

Morphic is not:

- a Linux kernel fork;
- a goal to reimplement every Linux internal subsystem;
- a collection of apk/BusyBox special cases;
- a syscall-count vanity project;
- a fake browser desktop assembled from screenshots or scripted output;
- a "vibe OS" cardboard city where a demo looks broad but the mechanisms cannot support ordinary software;
- a reason to weaken correctness invariants merely to push one command one line farther.

The project values **real software unlocked per admitted primitive**.

If a general mechanism is required by real pressure, implement it. If a feature is merely imaginable but not causally required, it usually waits.

---

# 4. Current main checkpoint

The current main-line checkpoint after PR #100 is:

```text
PR #100
runtime: bound external PREPARE stack usage

merge commit:
e0e315219c60075ce81549e3eda657b04a6723f6
```

PR #100 repaired a real regression introduced when the prepared execution capacity grew to 584 pages.

The failure was not "QEMU is slow." The 584-entry `PreparedImage` metadata was being inlined into an already large supervisor startup frame. That crossed the runtime's explicit 60 KiB supervisor stack reservation and corrupted adjacent BSS state before ordinary external execution.

The repair:

- makes external execution an explicit non-inlined phase;
- moves capacity-sized PREPARE metadata into bounded global candidate slots already owned by the runtime;
- keeps the 584-page capacity;
- keeps PREPARE/COMMIT failure atomicity;
- removes capacity-proportional supervisor stack growth;
- returns the real machine to external namespace lookup, PREPARE, COMMIT, and execution.

This is an important distinction: **the 584-page growth was not itself conceptually wrong; where its metadata lived was wrong.**

---

# 5. Exact current causal frontier

After the PR #100 stack repair, real QEMU again reaches external execution.

The immediate unchanged `/sbin/apk --version` retry then exposed the next exact kernel-side failure:

```text
supervisor load page fault
cause: 13
PC: approximately 0x80208e92
stval: 0x4001b148
return address: approximately 0x80208e6a
```

Host symbolization places the failing PC in the `RealPageOwner.owns` / `RealPageOwner.read` path used by the Sv39 walker.

The key symptom is:

> the Sv39 walker attempts to read a page-table page derived from the **user virtual page around `0x4001b000`** as though that value were an owned physical page-table address.

Therefore the immediate problem is **not** "implement more apk." The immediate blocker is to determine which page-table state transition creates/corrupts the branch PTE or ownership state that lets a user-derived address become interpreted as a physical table page.

Current frontier:

```text
584-page PREPARE startup stack corruption       FIXED
external namespace lookup                       REACHED
external PREPARE                                REACHED
external COMMIT                                 REACHED
external execute                                REACHED
               │
               ▼
unchanged /sbin/apk --version retry
               │
               ▼
Sv39 walker follows corrupted/wrong branch state
               │
               ▼
user-derived 0x4001b000 treated as table address
               │
               ▼
        ★ YOU ARE HERE ★
```

The next agent must first restore the page-table ownership invariant, then **immediately** rerun the real apk ladder.

---

# 6. Previously earned apk milestone — do not forget it

Before the current regression/frontier, Morphic had already earned:

```text
/sbin/apk --version
→ apk-tools 2.14.9, compiled for riscv64
```

That matters enormously.

The project is not still asking "can apk start?"

It has already demonstrated that real Alpine apk can:

- be found in the unchanged namespace;
- execute through the Morphic Linux/RV64 personality;
- load its dynamic interpreter;
- load substantial shared-library dependencies;
- survive many mmap, mprotect, fixed-mapping, symlink, file-stat, pipe/process, and allocator semantics;
- reach apk's own version output.

Later work reached `/sbin/apk --help` output and entered `apk info`.

The current job is to **restore and extend** that earned path, not to redesign it from zero.

Never casually downgrade an earned milestone in documentation. If a new regression prevents a previously successful command from running, state both truths:

1. the milestone was historically earned;
2. the current head has a regression/new blocker preventing re-proof.

---

# 7. apk-info causal history

The recent `apk info` pressure is useful because it shows the intended development style.

A prior fresh `apk info` run faulted in musl `memset` with a destination near `0x8`.

Instead of patching `memset`, the agent traced backward through the result producers.

The causal ladder exposed, in order:

1. the runtime mapping table had only 16 entries and was exhausted;
2. after growing that measured topology, Linux mmap byte length `0x2711c` was incorrectly rejected because the implementation required page alignment rather than rounding every touched page;
3. after fixing checked mmap byte-length rounding, an address-zero anonymous `PROT_NONE` reservation became causal;
4. after admitting bounded unbacked address-zero `PROT_NONE`, the mapping-table pressure reached exactly 32 entries, so the measured bounded table was raised to 64 with focused proof for entry 33;
5. the original `0x2711c` allocation and later allocations succeeded;
6. the workload then requested a much larger anonymous allocation requiring 391 pages at a point where the cursor was already around 191 pages;
7. the measured prepared/anonymous capacity was therefore raised to 584 pages (582 measured plus two explicit headroom pages);
8. exec/fork state transfer was changed to copy only the live prefix rather than capacity-sized arrays;
9. the capacity growth then exposed the supervisor-stack placement bug fixed by PR #100.

This is exactly how future agents should work:

```text
real failure
   ↓
identify first bad producer
   ↓
smallest general semantic repair
   ↓
focused permanent proof
   ↓
rereun unchanged real workload immediately
   ↓
observe next causal blocker
```

Do not patch the symptom when the producer is knowable.

---

# 8. The 30-minute snowball rule

This repository uses a deliberate **agentic snowball** workflow.

The normal Codex engineering slice is approximately 30 useful minutes.

The agent is expected to use that time for **continuous causal progress**, not to stop after the first successful local repair.

Canonical behavior:

```text
start from exact inherited frontier
        ↓
reproduce
        ↓
repair smallest general mechanism
        ↓
focused test
        ↓
real QEMU retry immediately
        ↓
next blocker
        ↓
repair
        ↓
retry
        ↓
continue while useful time remains
        ↓
~30-minute boundary
        ↓
persist report / docs / handoff LAST
```

The following are **not** valid automatic batch boundaries:

- one unit test turning green;
- one syscall implemented;
- one mmap failure repaired;
- apk version succeeding;
- `apk info` succeeding early in the slice;
- validation becoming green;
- discovery of a second blocker.

If a slice problem is solved at minute 8, the agent should spend the remaining useful window attacking the next real blocker.

If `apk info` succeeds at minute 18, continue into stronger package-manager behavior rather than spending 12 minutes admiring the milestone.

The report/handoff is the **final action**, not the main activity.

---

# 9. What "full apk" means in stages

Do not treat apk as a single binary yes/no milestone.

The package-manager ladder is approximately:

```text
/sbin/apk --version
        ↓
/sbin/apk --help
        ↓
apk info
        ↓
read local apk database reliably
        ↓
query installed package metadata
        ↓
local package/archive operations
        ↓
package extraction into real filesystem tree
        ↓
links / directories / ownership / permissions
        ↓
package scripts/hooks where required
        ↓
transactional/durable filesystem mutation
        ↓
★ LOCAL APK INSTALL ★
        ↓
network sockets / DNS / HTTP(S)
        ↓
apk update
        ↓
apk add from Alpine repositories
        ↓
★ NETWORKED APK ★
```

The current major target is **`apk info` success and useful local package-database behavior**.

After that, local `.apk` installation is the next major ecosystem unlock.

Networked repository installation comes after enough networking/syscall support exists.

---

# 10. Why apk is strategically important

apk is not merely a trophy application.

Once local/networked apk works, Alpine itself becomes a compatibility-pressure generator.

Instead of manually choosing every next feature, the project can ask real ecosystem questions:

```text
apk add python3
apk add git
apk add sqlite
apk add curl
apk add nano
apk add openssh
```

Each request exposes whatever general semantics remain missing.

The desired convergence signal is:

> as Morphic matures, the number of new substrate mechanisms required per newly working Alpine package should decline.

That is far more interesting than raw syscall count.

---

# 11. Current Linux/RV64 syscall surface and Minimus

See:

`docs/roadmaps/MINIMUS_GLOBAL_UNLOCK_ORDER.md`

The Minimus principle is:

> If only seven missing Linux syscalls can be added next, choose the seven that unlock the most real software.

There are no sacred filesystem/network/threading batches. Every missing syscall competes globally on downstream leverage.

Current dispatcher-admitted calls include at least:

```text
read
write
writev
mmap
munmap
mprotect
brk
openat
close
newfstatat
fstat
getdents64
clone
execve
pipe2
fcntl
dup / dup3
getcwd
chdir
exit / exit_group
```

In the first twelve seven-call Minimus forecast batches, the roadmap currently records 20 of 84 ranked slots as admitted.

This number should not be mistaken for percent-Linux-complete. Morphic has intentionally selected disproportionately high-leverage primitives, which is why real dynamic Alpine and apk have become possible at a low absolute syscall count.

After real workload pressure becomes richer, measured evidence outranks the theoretical batch forecast.

Missing syscalls should be scored roughly by:

```text
unlock score =
    independently blocked target paths
  × target importance
  × downstream software fanout
  × cross-workload reuse
```

Implementation cost can break ties, but agents should not choose easy low-value calls merely to make a checklist move.

---

# 12. Current high-leverage future syscall areas

These are planning priors, not instructions to implement them speculatively.

Likely high-leverage untouched areas include:

- `futex`
- `clock_gettime`
- `rt_sigaction`
- `rt_sigprocmask`
- `set_tid_address`
- `ioctl`
- `lseek`
- `getpid`
- `getrandom`
- `readlinkat`
- `wait4`
- networking: `socket`, `connect`, `poll`, `sendto`, `recvfrom`, sockopts
- async/server primitives: epoll family, bind/listen/accept4
- package-filesystem mutation: `renameat2`, `unlinkat`, `mkdirat`, `fsync`, truncate/chmod/chown variants

But again:

> real workload evidence wins.

If the next unchanged apk retry says a different primitive is causal, follow the trace.

---

# 13. Correctness invariants that matter

Agents must not casually weaken these to make a command print more output.

## PREPARE → COMMIT

Potentially fallible work should happen before externally visible state replacement when possible.

A failed exec/mapping transaction should not leave half-installed state.

## Failure atomicity / rollback

If page-table allocation, mapping, backing preparation, or topology admission fails mid-operation:

- remove leaves installed by the failed attempt;
- restore prior mapping topology;
- restore backing/cursors where required;
- return a deterministic Linux errno;
- do not shut down the entire VM merely because a guest request exceeds a bounded resource.

## W+X = 0

Do not silently admit writable+executable mappings merely to satisfy a loader.

## SUM clear

Supervisor/user access discipline must remain intentional.

## Bounded resources

The project prefers explicit bounded classes whose growth is justified by measured real pressure.

When a bound is raised, record:

- old bound;
- observed requirement;
- new bound;
- why the headroom is reasonable;
- focused proof when practical.

## Immutable canonical source

The canonical Alpine namespace is evidence/input, not something to mutate in order to fake compatibility.

## Ownership identity

Descriptors, physical frames, page-table pages, runtime mappings, backing classes, file offsets, private mappings, parent/child process state, and namespace objects all need stable ownership semantics.

## Parent shell liveness

Child exec/fork-shaped behavior must not silently corrupt the parent shell.

## Deterministic errno

Unsupported or bounded failures should generally return the appropriate deterministic guest error rather than trap or power off the system.

## No workload special cases

Do not add:

```text
if apk ...
if libcrypto ...
if path == /foo ...
if fd == 7 ...
```

unless the behavior is genuinely part of a general ABI rule and the condition is merely the correct generic dispatch predicate.

---

# 14. Important memory/mmap machinery already earned

The runtime has accumulated significant real loader/mapping semantics. Do not rewrite these casually.

Recent mechanisms include:

- Linux mmap byte lengths are rounded to all pages touched rather than requiring already aligned length;
- zero-length/overflow ranges are rejected safely;
- address-zero anonymous `PROT_NONE` reservations can own virtual address space without immediately consuming/installing data backing;
- runtime mappings record explicit backing classes and offsets;
- file-backed `MAP_PRIVATE` has its own bounded private-file backing pool;
- fixed private mappings and fixed anonymous replacement have been advanced;
- `munmap(215)` exists for supported runtime-owned mappings;
- `mprotect(226)` exists and has been repaired around `PROT_NONE` transitions and backing identity;
- mapping-table splits preserve backing offsets;
- fork-shaped parent snapshot/restore preserves private-file backing state and cursor;
- exec/fork large backing copies use live-prefix copies rather than capacity-sized copies;
- the measured runtime mapping table is currently 64 entries;
- the measured prepared/anonymous backing class is currently 584 pages;
- the private file mapping class has been grown independently based on loader pressure;
- page-table PREPARE has explicit bounded table backing.

The current page-table ownership fault should be repaired **within these invariants**, not by bypassing the page owner or teaching the walker to accept arbitrary addresses.

---

# 15. Current page-table bug — working hypothesis discipline

The evidence says the Sv39 walker is reading a page-table address derived from user VA `0x4001b000`.

Do not prematurely conclude the exact cause.

Reasonable candidate classes include:

- a branch PTE encoded from the wrong address domain;
- physical-vs-virtual address confusion during a mapping transition;
- stale branch table state surviving unmap/replacement;
- page-table frame ownership metadata being overwritten or restored incorrectly;
- a branch page created/returned through the wrong allocator/owner path;
- corrupted PTE bits from a mapping/preflight/restore operation;
- an address-shift/mask bug that only becomes visible after the new topology/capacity path.

The correct procedure is:

1. reproduce unchanged `/sbin/apk --version` under the canonical QEMU command;
2. instrument narrowly around the first bad page-table transition;
3. identify the earliest moment where a branch PTE or owner returns a user-derived/non-owned table address;
4. repair the general invariant;
5. add a focused regression if practical;
6. rerun apk immediately.

Do not "fix" this by letting `RealPageOwner` claim user pages as page-table pages.

---

# 16. Playable Alpine milestone

The project has a canonical persistent-shell acceptance sequence that has previously passed under real QEMU:

```sh
echo morphic
echo second
pwd
ls /
cat /etc/alpine-release
cd /tmp
pwd
echo hello > /tmp/hello
cat /tmp/hello
echo hello | cat
echo still-alive
```

This proves substantially more than shell startup:

- persistent process liveness;
- cwd state;
- directory traversal;
- file lookup/open/read;
- writable runtime state;
- redirection;
- pipe byte flow;
- descriptor lifecycle;
- parent shell survival across child activity.

After invasive runtime changes, re-prove this gate near the end of the engineering slice if time permits and especially before claiming a stable milestone.

The current PR #100 report explicitly says the gate was **not rerun after the newly exposed Sv39 fault**, so current head should not be described as freshly re-proved Playable Alpine until the new fault is repaired and the gate is rerun.

Historically, however, Playable Alpine is an earned milestone.

---

# 17. Canonical environment expectations

Codex/cloud development should have at least:

- Zig `0.14.0`;
- `qemu-system-riscv64` available;
- internet access where required for canonical Alpine acquisition;
- repository Python environment/requirements when validation tooling needs it.

QEMU is not optional infrastructure for real runtime-pressure tasks.

A minimal beginning-of-run check is:

```sh
zig version
command -v qemu-system-riscv64
qemu-system-riscv64 --version
```

If QEMU itself is missing, do not immediately hand off after six minutes. Treat missing pressure infrastructure as a bounded environment problem: diagnose PATH/install/bootstrap/cache possibilities and use the useful engineering window to restore the real oracle when possible.

The repository has historically used QEMU 8.2.2 in these pressure reports.

---

# 18. Validation expectations

Important validation surfaces commonly include:

```sh
zig build test-recipe-run-hosted-morphic-runtime
zig build install-freestanding-riscv64-morphic-runtime
zig build check --summary all
python3 tools/developer-command.py validate-repository
PYTHONDONTWRITEBYTECODE=1 python3 tools/check-command-reference.py --check
```

Validation evidence under `generated/validation/modules.json` may need regeneration after source changes.

A prior PR was intentionally merged with stale validation evidence and the next run repaired it. The lesson is not "CI does not matter." The lesson is to distinguish:

- runtime evidence;
- repository validation evidence;
- GitHub CI state;
- known debt intentionally handed off.

Agents should state each accurately.

Do not claim GitHub CI green merely because local validation is green.

---

# 19. Repository documentation map

A new agent should inspect these regions before broad changes:

```text
README.md
COMMANDS.md

docs/README.md
docs/milestones.md

docs/roadmaps/
    PLAYABLE_ALPINE_TO_APK.md        (if present/current)
    MINIMUS_GLOBAL_UNLOCK_ORDER.md
    other Morphic roadmaps

docs/plans/
    canonical batch execution plans

docs/reports/
    AGENTIC_SNOWBALL_BATCH_*.md

docs/research/
    comparisons, failure ledgers, strategic research

docs/codex/
docs/codex-requests/
    agent/Codex guidance and requests

docs/agent_handoff/
    this handoff region
```

`COMMANDS.md` is not decorative. It captures runnable surfaces and important batch-specific execution facts.

The `docs/reports/AGENTIC_SNOWBALL_BATCH_*` sequence is the historical causal record of recent Morphic progress.

---

# 20. Failure ledger philosophy

The repository maintains research/failure ledger material for important agent/runtime failures.

When a significant problem is knowingly merged or handed forward, associate it with:

- PR number;
- PR head SHA;
- merge commit SHA where relevant;
- review comment/thread when relevant;
- exact workflow/job when CI is the failure;
- the causal classification;
- whether the failure is architecture, implementation, agent execution/completeness, tooling, or external environment.

Do not let a future agent discover an old known problem with no historical identity.

Tags are also used as explicit historical checkpoints, especially for important milestones carrying known debt.

---

# 21. How to write the next Codex request

A strong request should contain:

1. exact inherited commit/frontier;
2. exact first command to reproduce;
3. current evidence, not just a guessed subsystem;
4. invariants that cannot be weakened;
5. instructions to add focused permanent proof;
6. immediate retry of unchanged real workload after every causal repair;
7. explicit instruction to continue after success while useful time remains;
8. ~30-minute handoff-last rule;
9. exact report path expected at the end.

For the next run, conceptually:

```text
FIRST:
repair the Sv39 table ownership/state transition that causes
0x4001b000-ish user-derived state to be treated as a page table.

THEN IMMEDIATELY:
/sbin/apk --version

IF SUCCESS:
/sbin/apk --help

THEN:
apk info

AFTER EVERY FIX:
retry the unchanged command immediately.

IF apk info SUCCEEDS EARLY:
continue into stronger real local package/database behavior.

ONLY NEAR ~30 MIN:
write the final handoff report.
```

---

# 22. Immediate roadmap — "YOU ARE HERE"

```text
MORPHIC / ALPINE ROADMAP

freestanding RV64 substrate
        ✓
Linux/RV64 compatibility personality
        ✓
unchanged Alpine userspace boots/runs
        ✓
dynamic musl / BusyBox
        ✓
persistent Playable Alpine shell
        ✓
files / cwd / redirection
        ✓
real pipes
        ✓
clone/exec-shaped process path
        ✓
file-backed MAP_PRIVATE
        ✓
fixed mappings
        ✓
munmap
        ✓
relative shared-library resolution
        ✓
mprotect / RELRO progression
        ✓
real /sbin/apk --version historically
        ✓
real apk --help reaches apk output historically
        ✓
real apk info enters package-manager execution
        ✓

584-page PREPARE metadata stack issue
        ✓ FIXED BY PR #100
        │
        ▼
Sv39 page-table ownership/state fault
        ★ YOU ARE HERE ★
        │
        ▼
restore apk --version
        │
        ▼
restore/advance --help
        │
        ▼
APK INFO SUCCESS
        │
        ▼
local package DB read/query
        │
        ▼
local .apk extraction/install
        │
        ▼
filesystem mutation semantics
        │
        ▼
★ LOCAL APK ★
        │
        ▼
networking + DNS + HTTP(S)
        │
        ▼
apk update / repository access
        │
        ▼
★ NETWORKED APK ★
        │
        ▼
install real ecosystem workloads
        │
        ▼
Python / Git / SQLite / curl / Zig / etc.
        │
        ▼
graphics prerequisites
        │
        ▼
graphical Alpine
        │
        ▼
browser-visible desktop
```

---

# 23. Medium-range goals after local apk

Once local package installation works, pressure should expand deliberately across diverse software.

Good targets include:

```text
BusyBox breadth
apk
SQLite
curl
Git
Python
Zig
Bun or another modern runtime
terminal/PTY workloads
browser-adjacent dependencies
```

The point is not to make each application perfect in isolation. The point is to use them as **orthogonal pressure generators**.

Track which new primitives unlock multiple targets simultaneously.

This is where Minimus becomes empirical rather than theoretical.

---

# 24. Networking roadmap

Networking is a major later unlock, not something to fake around apk.

Expected general progression:

```text
socket
connect
poll/ppoll
send/recv family
setsockopt/getsockopt
DNS path
HTTP(S) client behavior
        ↓
apk repository access
        ↓
curl
        ↓
Git remote operations
        ↓
servers / async runtimes
        ↓
epoll family
bind/listen/accept4
```

When network pressure arrives, continue the same rule: choose general primitives from real traces, not a special apk networking tunnel.

---

# 25. Graphical / browser-desktop long-range goal

A major long-range product/showcase goal is a **real graphical Alpine environment visible through a browser**, with a distinctive visual identity rather than generic modern desktop styling.

The intended design direction discussed for the eventual desktop is roughly:

- 1960s/1990s technology nostalgia;
- ASCII/terminal graphic energy;
- Macintosh-like warmth and friendliness;
- intentionally small, legible, charming graphical surface;
- avoid looking like a disposable AI-generated "vibe OS" demo.

Engineering sequence should remain reality-based:

```text
useful apk
   ↓
install needed userspace packages
   ↓
PTY / ioctl / poll / signals mature
   ↓
simple display primitive/framebuffer
   ↓
Xorg or another sufficiently small graphical route
   ↓
terminal emulator
   ↓
window manager
   ↓
input
   ↓
graphical applications
   ↓
display transport to browser
   ↓
keyboard/mouse bridge
   ↓
★ MORPHIC WEB DESKTOP ★
```

Do not claim "first Alpine in browser" or "first desktop in browser." Prior art exists. The differentiation should come from the architecture, inspectability, Linux-compatibility route, small substrate, reproducibility, and research value.

---

# 26. Long-range research identity

The project should become a **standard study subject**, not merely a novelty demo.

Potential differentiators:

- tiny bounded substrate with a real Linux/RV64 personality;
- real unchanged Alpine pressure;
- reproducible causal frontier reports;
- explicit failure ledgers rather than hidden broken history;
- direct measurement of "software unlocked per primitive";
- whole-system inspectability for humans and agents;
- side-by-side comparison against mature Linux-compatibility approaches;
- ability to run both a compatibility personality and, eventually, true virtualized guests;
- browser-visible graphical system as a compelling demonstration rather than the entire substance.

Research comparisons already discussed include ideas analogous to:

- Fuchsia Starnix: Linux UAPI compatibility without using Linux as the syscall implementation kernel;
- WebVM/CheerpX-style browser-side Linux execution concepts;
- Kerla and other alternative systems projects;
- traditional kernels and emulation layers.

Comparisons must remain accurate. Similarity of one architectural idea does not imply equivalent completeness.

---

# 27. Hyper-Zig / RISC-V H-extension future

There is a related project, **Hyper-Zig**, containing substantial groundwork for the RISC-V H extension and hypervisor architecture.

The likely plan is **not** to interrupt the current apk snowball.

After useful apk/local ecosystem capability is secured and tagged, perform a deliberate Hyper-Zig harvest/integration audit.

Hyper-Zig already contains or has explored machinery such as:

- H-extension discovery;
- VM/vCPU structures;
- guest memory ownership;
- guest address-space concepts;
- guest loading;
- SBI foundations;
- DTB/FDT preparation;
- trap planning;
- hypervisor CSR safety;
- `hgatp` candidate/planning/gating work.

The important boundary is that this groundwork is not the same thing as completed live H-extension guest execution.

Future sequence may look like:

```text
★ USEFUL APK ★
      ↓
freeze/stabilize milestone
      ↓
Hyper-Zig import audit
      ↓
port reusable mechanisms, not wholesale monolith
      ↓
real hgatp activation
      ↓
stage-2 translation
      ↓
VS/guest entry
      ↓
first guest instruction
      ↓
first guest trap
      ↓
Linux guest
```

This creates a fascinating dual architecture:

```text
Linux software WITHOUT Linux kernel
        via Morphic Linux personality

                 AND

Linux kernel AS A GUEST
        via RISC-V H extension
```

That is long-range work. Do not derail apk for it now.

---

# 28. AI/agent development philosophy

The project is intentionally using AI agents aggressively, but the goal is not to produce "AI slop."

The expected antidote is evidence discipline.

An agent should be able to say:

- exact command run;
- exact output/fault;
- exact first bad producer;
- exact mechanism admitted;
- exact test proving it;
- exact real command retried;
- exact new frontier;
- exact commit carrying the change.

A weak agent says:

> I implemented some mmap improvements and updated docs.

A strong agent says:

> The unchanged `apk info` request failed because anonymous mmap exhausted the 16-entry table; after measured growth it exposed byte-length rejection of 0x2711c; checked rounding crossed that, which exposed an address-zero PROT_NONE reservation; after that the real workload reached 32 mappings and then a 391-page allocation. Each transition was rerun under QEMU.

Prefer the latter level of causal accounting.

---

# 29. Agent anti-patterns

Do not:

- spend the whole slice polishing the report before real pressure;
- stop after 6–12 minutes because the first requested fix succeeded;
- guess downstream blockers and implement them all speculatively;
- add dozens of syscalls because they "sound useful" while an exact current blocker is known;
- special-case apk/musl/BusyBox paths;
- convert guest ENOMEM/EINVAL cases into VM shutdowns unnecessarily;
- weaken W+X or ownership boundaries;
- conflate virtual, guest-physical, host-physical, and backing addresses;
- silently overwrite live parent state during child exec;
- claim a milestone from synthetic/unit tests when the standard is real QEMU;
- claim fresh Playable Alpine proof if it was not rerun after the latest invasive change;
- claim CI green from local validation only;
- treat larger static bounds as "solutions" without proving the measured need and ensuring their metadata/layout costs remain bounded.

PR #100 is a perfect reminder of the last point: increasing a measured data capacity can reveal a totally different cost center such as supervisor stack metadata.

---

# 30. How to think about bounds

This project is intentionally bounded, but bounds are not dogma.

Bad reasoning:

> The bound is 320 because small is good.

Also bad:

> Make it 100000 so apk stops complaining.

Good reasoning:

> Real apk reached cursor 191 and requested another 391 pages. The measured requirement is 582 pages. Admit 584 with explicit two-page headroom, then make sure the associated metadata does not scale onto a tiny supervisor stack.

Every bounded class should have a reason.

As the system matures, consider whether repeated bound growth indicates a need for a better bounded allocator or reclaim strategy rather than endless static expansion. But only make that architectural jump when evidence supports it.

---

# 31. Current known unsupported syscalls seen around the latest retry

The PR #100 report notes unsupported-but-errno-returned syscall numbers around the immediate apk-version retry, including numbers `96`, `135`, `135`, and `134` before the Sv39 fault.

Do not automatically implement these merely because they appeared.

The page-table fault is the first fatal causal blocker in that run.

After repairing it, rerun unchanged. If one of those syscalls becomes the next fatal/behavioral blocker, identify it by Linux/RV64 number and implement the smallest correct semantic surface required by the trace.

This is an example of the difference between **observed** and **causal**.

---

# 32. Historical batch sequence relevant to the current state

Recent important batches/PRs:

```text
Batch 32Q / PR #93
bounded pipe2 and Playable Alpine milestone work

Batch 32R / PR #94
fstat(80), real /sbin/apk frontier

Batch 32S / PR #95 and follow-up PR #96
stat identity + bounded file-backed MAP_PRIVATE work

Batch 32T / PR #97
file-backed MAP_PRIVATE EOF/protection semantics,
private-file backing capacity, fixed mapping / munmap progress,
then libcrypto ENOMEM frontier

Batch 32U / PR #98
fork-shaped private-file mmap restore,
backing identity, mprotect/fixed replacement cleanup,
real apk --version success, --help progress, apk info frontier

Batch 32V / PR #99
validation recovery + mmap rounding + PROT_NONE reservation
+ 64-entry topology + 584-page measured anonymous capacity,
traced apk-info null-derived memset back through actual mmap producers

Batch 32W / PR #100
repaired 584-capacity metadata blowing the 60 KiB supervisor stack;
external PREPARE/COMMIT/execute restored;
new Sv39 page-table ownership fault exposed
```

The letter sequence should continue naturally for new snowball plans/reports.

---

# 33. Next batch recommendation

The next canonical execution plan should likely be **Batch 32X**.

Suggested conceptual title:

```text
Batch 32X — repair Sv39 branch/table ownership corruption,
restore apk ladder, then maximize causal progress toward apk info
for the full useful 30-minute window before handoff
```

The run should begin from current main and explicitly reference PR #100 merge:

```text
e0e315219c60075ce81549e3eda657b04a6723f6
```

Opening task:

> Determine the first page-table state transition that causes the walker to treat a user-derived page near `0x4001b000` as an owned table address. Repair the ownership/address-domain invariant generally. Add focused proof. Then immediately rerun unchanged real Alpine apk pressure.

Do not let the page-table repair consume the whole run if it is solved quickly.

---

# 34. Exact desired next-run ladder

```text
1. verify Zig/QEMU environment
2. build canonical current machine
3. reproduce unchanged /sbin/apk --version failure
4. trace first bad Sv39 ownership/PTE transition
5. make smallest general fix
6. focused test/proof
7. rebuild
8. /sbin/apk --version immediately
9. if success → /sbin/apk --help
10. then → apk info
11. if apk info fails → first causal producer → repair → retry
12. if apk info succeeds → continue into local package DB/query behavior
13. continue real progress until ~30-minute boundary
14. re-prove Playable Alpine if useful/possible
15. run validation
16. write Batch 32X report LAST
```

---

# 35. What success in the next few runs looks like

Near-term success:

```text
Sv39 ownership fault repaired
        ✓
apk --version restored
        ✓
apk --help restored/advanced
        ✓
apk info completes
        ✓
```

Next major milestone:

```text
real local apk database behavior
        ↓
local package extraction/install
        ↓
★ LOCAL APK ★
```

A single completed `apk info` is meaningful, but it should not be treated as the end of the project or even necessarily the end of the 30-minute slice.

---

# 36. Long-range milestone ladder

```text
[ACHIEVED HISTORICALLY]
unchanged dynamic Alpine under Morphic
Playable Alpine shell
real pipes/process/file behavior
real apk --version

[CURRENT]
restore page-table correctness on enlarged machine
apk info completion

[NEXT]
local package database
local apk install

[THEN]
networking
DNS
HTTP(S)
networked apk repositories

[ECOSYSTEM]
Python
Git
SQLite
curl
Zig
modern runtimes

[GRAPHICS]
PTY/ioctl/poll/signals completeness
framebuffer/display abstraction
X/Wayland-like route
terminal/window manager
browser display/input bridge

[SHOWCASE]
Morphic graphical Alpine web desktop

[RESEARCH EXPANSION]
measured global syscall unlock batches
cross-workload convergence data
Hyper-Zig H-extension harvest
Linux guest virtualization
multiple personalities
```

---

# 37. What the project should eventually be able to say

The strongest eventual claim is not:

> We implemented N Linux syscalls.

It is closer to:

> A small bounded Zig/RISC-V substrate can run a growing unchanged Alpine ecosystem through a directly implemented Linux userspace personality, with every admitted mechanism justified by reproducible real-workload pressure and with the entire compatibility frontier documented causally.

And later:

> The same substrate can also host virtualized Linux through RISC-V H-extension machinery, allowing direct Linux-ABI compatibility and true Linux guests to coexist as separate execution strategies.

That is a genuinely interesting systems research story.

---

# 38. Final instructions to the incoming agent

If you remember only ten things, remember these:

1. **Real QEMU is the oracle.** Unit tests support claims; they do not replace real Alpine evidence.
2. **Follow the first causal blocker.** Do not guess five blockers ahead.
3. **Repair general semantics, never apk-specific symptoms.**
4. **Preserve PREPARE/COMMIT, rollback, ownership, W+X=0, SUM discipline, bounded resources, and parent-shell liveness.**
5. **After every repair, rerun the unchanged real command immediately.**
6. **Use the full useful ~30-minute window.** One solved slice is not a handoff trigger.
7. **If `apk info` succeeds early, keep going into stronger real package behavior.**
8. **Report and handoff last.**
9. **Record exact evidence and exact commits.** Do not blur historical earned milestones with current regressions.
10. **The immediate frontier is the Sv39 ownership/state transition around the `0x4001b000` user-derived table address. Fix that first, then get back to apk.**

---

# 39. One-screen handoff summary

```text
PROJECT:
Morphic inside thanks-cohn/zig-reference
small bounded freestanding RV64 substrate + Linux/RV64 personality

CURRENT MAIN:
e0e315219c60075ce81549e3eda657b04a6723f6
(PR #100 merged)

HISTORICALLY PROVED:
✓ unchanged Alpine v3.22 RV64 userspace
✓ dynamic musl/BusyBox
✓ persistent Playable Alpine shell
✓ cwd/files/redirection/pipes
✓ clone/exec-shaped child path
✓ file-backed MAP_PRIVATE
✓ mmap/munmap/mprotect/fixed mapping progress
✓ real /sbin/apk --version → apk-tools 2.14.9
✓ apk --help reaches apk
✓ apk info enters real execution

PR #100 FIXED:
✓ 584-page PREPARE metadata overflowed 60 KiB supervisor stack
✓ non-inlined phase + global bounded candidates
✓ external PREPARE/COMMIT/execute restored

CURRENT EXACT BLOCKER:
Sv39 walker load fault
user-derived ~0x4001b000 is treated as page-table address
find first corrupt/wrong PTE/ownership state transition

NEXT:
fix general page-table ownership invariant
→ retry /sbin/apk --version
→ --help
→ apk info
→ keep repairing/retrying until ~30 min
→ handoff last

NEAR-TERM GOAL:
★ APK INFO SUCCESS ★
then local package DB and local .apk install

MEDIUM GOAL:
★ LOCAL APK ★
then networking and networked repositories

LONG GOAL:
real Alpine ecosystem + graphical browser-visible desktop

LATER RESEARCH:
Hyper-Zig H-extension harvest → true Linux guest support
alongside the direct Linux userspace personality

AGENT RULE:
real evidence, smallest general mechanism, retry immediately,
full useful 30-minute snowball, report last.
```

---

**End of current-state handoff.**

Update this document when a major milestone materially changes the project frontier. Do not rewrite historical earned facts merely because a later regression temporarily prevents re-proof.