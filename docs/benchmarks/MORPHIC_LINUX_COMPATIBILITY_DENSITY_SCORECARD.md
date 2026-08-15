# Morphic Linux Compatibility Density Scorecard

Status: **provisional comparative framework and current analytical snapshot**.

This document answers a narrow question:

> **How much real, unchanged Linux userspace can a system support, and how much machinery does it need to do it?**

It is not a general operating-system quality ranking, not a production-readiness ranking, and not a claim that Morphic is already more complete than mature Linux-compatible systems.

The purpose is to give Morphic a scoreboard that can become increasingly empirical as the repository accumulates measurable evidence.

## Why two leaderboards are necessary

A single ranking would be misleading.

A mature compatibility system such as gVisor or Asterinas should dominate a ranking of total Linux capability. That does not answer Morphic's central research question, which is deliberately about the **minimum substrate required to inherit real Linux software**.

Accordingly, comparisons should use two separate views.

### Leaderboard A: general Linux-compatible system maturity

This asks:

- How much Linux userspace runs?
- How broad are the syscall and semantic surfaces?
- Are signals, filesystems, networking, concurrency, terminals, process semantics, and deployment mature?
- Is the system useful beyond a narrow demonstration path?

On this axis, Morphic is currently an early research system and should not be presented as competing with the maturity of gVisor or Asterinas.

### Leaderboard B: Morphic mission score

This asks:

- How much **unchanged real Linux software** runs?
- How little permanent machinery was required?
- Are the Linux semantics real rather than syscall-shaped stubs?
- Is the capability demonstrated end-to-end and reproducibly?
- Does each new workload teach us something reusable about the minimum Linux-compatible substrate?

This second leaderboard is where Morphic's design can be tested on its own terms.

---

# Morphic Mission Score

The score is 100 points.

```text
30  Unchanged Linux userspace reach
25  Minimality / mechanism cost
20  Semantic depth
15  Reproducible proof quality
10  Experimental leverage
---
100 total
```

The score must never replace the underlying measurements. Every published score should link to the evidence used to assign it.

## 1. Unchanged Linux userspace reach — 30 points

Award points for increasingly demanding **real, unmodified** Linux workloads.

Suggested ladder:

| Capability | Guidance |
|---|---:|
| One trivial static ELF | 2 |
| Real static BusyBox program | 5 |
| Dynamic ELF through the real userspace loader | 8 |
| Persistent real shell | 12 |
| External process execution | 15 |
| Writable runtime state and file read-back | 18 |
| Real shell pipelines / IPC | 21 |
| Package-manager binary reaches meaningful execution | 23 |
| Local package transaction succeeds | 25 |
| Networked package retrieval succeeds | 27 |
| Broad representative application corpus | 30 |

Points should reflect the highest reproducible frontier, not a sum of every row.

## 2. Minimality / mechanism cost — 25 points

This category is the heart of the Morphic experiment and therefore must eventually be measured rather than asserted.

Required measurements should include, where practical:

- kernel/substrate source LOC;
- Linux-personality LOC;
- executable/kernel image bytes;
- resident memory at the acceptance frontier;
- number of implemented syscall behaviors;
- number of permanent subsystems introduced;
- amount of mutable runtime state;
- amount of guest-specific glue;
- reusable code versus one-workload special casing.

A small system does not receive a high score merely because it is incomplete. Minimality only counts when paired with demonstrated userspace capability.

A future quantitative metric should be published alongside this category:

```text
Compatibility Density = demonstrated capability points / kernel-or-substrate KLOC
```

Additional density measures may use binary size, resident memory, or permanent semantic mechanisms as the denominator.

Until those measurements are automated, minimality scores are explicitly **provisional estimates**.

## 3. Semantic depth — 20 points

This category distinguishes genuine compatibility from a pile of syscall names.

Credit should increase when the implementation survives real interactions among:

- process creation and replacement;
- descriptor ownership and lifetime;
- EOF behavior;
- mmap/protection semantics;
- cwd and path resolution;
- directory enumeration;
- file metadata;
- pipes and readiness;
- signals;
- futex/thread behavior;
- terminal semantics;
- networking;
- Linux-visible error behavior.

A syscall stub that returns a convenient value for one demo should receive little or no credit.

## 4. Reproducible proof quality — 15 points

Credit should depend on evidence quality:

- deterministic build instructions;
- exact guest image/version identified;
- canonical acceptance command sequence;
- automated or machine-checkable validation;
- preserved logs/reports;
- negative tests;
- regression tests;
- independent reproduction where available.

A screenshot is weaker evidence than a deterministic acceptance test. A claimed feature without a reproducible path receives no proof credit.

## 5. Experimental leverage — 10 points

This measures whether the system is useful as research apparatus rather than only as a feature collection.

Questions include:

- Can a new workload reveal one missing semantic dependency clearly?
- Is that dependency recorded before being generalized?
- Does the resulting mechanism unlock unrelated software?
- Can the repository distinguish permanent substrate growth from guest-specific accommodation?
- Are failures preserved as useful evidence?
- Can later agents or engineers inherit the causal result without repeating the archaeology?

This category is intentionally small enough that architectural storytelling cannot overpower demonstrated compatibility.

---

# Current provisional snapshot — 2026-08-15

These numbers are **analytical estimates, not benchmark results**. They exist to show where the current framework places the projects before the measurement pipeline is fully automated.

| Rank | Project | Userspace /30 | Minimality /25 | Semantics /20 | Proof /15 | Experimental /10 | Total |
|---:|---|---:|---:|---:|---:|---:|---:|
| 1 | Asterinas | 30 | 10 | 20 | 15 | 9 | **84** |
| 2 | gVisor | 30 | 7 | 20 | 15 | 8 | **80** |
| 3 | **Morphic / Alpz** | **18** | **24*** | **11** | **10** | **9** | **72*** |
| 4 | Kerla | 22 | 17 | 14 | 9 | 6 | **68** |
| 5 | BamOS | 13 | 13 | 15 | 8 | 8 | **57** |

`*` Morphic's minimality score, and therefore its total, is deliberately marked provisional until LOC, image-size, memory, and semantic-surface measurements are generated mechanically.

The important interpretation is not "Morphic is the third-best operating system." That would be false framing.

The useful interpretation is:

> **Morphic is already interesting on a compatibility-per-mechanism axis, while remaining much less complete than the mature systems above it on ordinary OS breadth.**

## General maturity placement

A separate maturity view should remain visible beside the mission score.

Approximate current tiers:

```text
S  gVisor, Asterinas
B  Kerla
C  BamOS, Morphic / Alpz
```

This tier list is intentionally coarse. Morphic's current strength is not broad system maturity; it is the depth reached by a deliberately narrow RV64 compatibility substrate.

---

# Why BamOS is a comparison point, not a direct score-race rival

BamOS is especially useful because it is another serious Zig operating-system project with Linux ABI ambitions, but it approaches the problem from the opposite direction.

BamOS builds a broad conventional operating system: scheduler, processes, VFS, device infrastructure, storage, filesystems, SMP, hardware support, and then Linux ABI compatibility as one major subsystem.

Morphic asks almost the inverse question:

> **What is the least permanent machinery that must exist underneath unchanged Linux software before increasingly complicated real programs work?**

That means BamOS can beat Morphic decisively in traditional kernel breadth while Morphic can still produce a meaningful result if it obtains comparable userspace capability with substantially less mechanism.

The strongest future comparison is therefore not "which OS has more features?" It is:

```text
Linux workloads demonstrated
------------------------------
per KLOC / binary byte / MiB / permanent mechanism
```

If BamOS ultimately needs more machinery because it is solving a much broader OS problem, that is not a failure by BamOS. It is exactly the kind of architectural contrast that makes the comparison useful.

---

# Current Morphic evidence frontier

The repository currently records the **Playable Alpine** gate under the exact Alpine v3.22.0 RV64 namespace.

The accepted path includes:

```text
echo morphic
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

This establishes, within the current bounded environment:

- real Alpine userspace rather than a bespoke test program;
- dynamic musl/BusyBox execution;
- persistent shell state;
- external process execution;
- directory enumeration;
- cwd behavior;
- writable bounded runtime state;
- external read-back;
- descriptor replacement;
- a real byte-carrying pipeline;
- EOF/lifetime behavior sufficient for the demonstrated shell pipeline;
- parent-shell survival after the pipeline.

The active pressure frontier is the real Alpine package manager, beginning with `/sbin/apk --version` and moving toward local package-database and package-transaction behavior before network retrieval is treated as necessary.

Canonical internal evidence:

- [`../../README.md`](../../README.md)
- [`../reports/AGENTIC_SNOWBALL_BATCH_32Q.md`](../reports/AGENTIC_SNOWBALL_BATCH_32Q.md)
- [`../roadmaps/PLAYABLE_ALPINE_TO_APK.md`](../roadmaps/PLAYABLE_ALPINE_TO_APK.md)

---

# Comparison set

## Primary Linux-compatibility comparisons

### gVisor

A mature application-kernel approach that implements a substantial Linux interface in userspace and supports real container workloads. It is a maturity ceiling for this comparison, not a minimal-kernel analogue.

Source: <https://gvisor.dev/docs/architecture_guide/intro/>

### Asterinas

A modern Rust-based kernel project pursuing strong Linux ABI compatibility with a very broad syscall/application surface and system-level ambitions.

Source: <https://github.com/asterinas/asterinas>

### Kerla

A historical from-scratch Rust Linux-compatible kernel and one of Morphic's closest conceptual comparisons. Kerla demonstrated broad Unix/Linux behavior including process management, pipes/poll, terminal support, networking, and SSH.

Source: <https://github.com/nuta/kerla>

### BamOS

A substantial Zig OS with a broad conventional kernel and an actively implemented GNU/Linux ABI path. Its Linux syscall dispatch includes process, memory, file, IPC, timing, and other behaviors, while its published project status still marks Linux compatibility and several userspace/kernel subsystems as in progress.

Sources:

- <https://github.com/bagggage/bamos>
- <https://github.com/bagggage/bamos/blob/main/src/kernel/sys/call/linux.zig>
- <https://github.com/bagggage/bamos-book/blob/main/src/current-progress.md>

## Secondary AI-assisted OS context

SlopOS and VibeOS should remain in the broader historical/agentic comparison, but they should **not** be forced into the primary Linux-ABI density leaderboard unless the compared workload genuinely tests unchanged Linux ABI compatibility.

Their strongest contributions are different: demonstrating how far AI-heavy operating-system development can progress in conventional OS capability, hardware, desktop, drivers, tools, and documented iteration.

This distinction keeps the benchmark from rewarding or punishing a project for solving a different problem.

---

# Measurements Morphic should automate next

The score becomes valuable when arguments can be replaced by generated numbers.

The repository should eventually emit a machine-readable snapshot containing at least:

```text
commit
UTC timestamp
Zig version
target architecture
guest distribution + exact version
kernel/substrate LOC
Linux-personality LOC
kernel/image bytes
RAM at acceptance shell
implemented syscall behaviors
acceptance workloads
negative/regression tests
current first-failing real workload
```

Recommended derived values:

```text
compatibility_density_loc
compatibility_density_bytes
compatibility_density_ram
semantic_reuse_ratio
new_mechanism_cost_per_frontier
```

The most important graph may eventually be neither syscall count nor LOC by itself. It may be:

```text
real workload capability
        ^
        |
        |                         mature compatibility systems
        |
        |              Morphic frontier
        |          *
        |      *
        |   *
        | *
        +------------------------------------> permanent mechanism / complexity
```

The research question is whether Morphic's curve stays unusually steep as real software pressure increases.

If it does, that is evidence for the architecture.

If it flattens and Morphic grows toward the complexity of broader kernels, that is also valuable evidence: the experiment will have located where the supposedly avoidable Linux machinery stops being avoidable.

---

# Anti-claim

This scorecard must not be used to claim any of the following without additional evidence:

- Morphic is more complete than gVisor, Asterinas, Kerla, or BamOS.
- Morphic is production-ready.
- fewer lines automatically means better engineering;
- syscall count alone measures compatibility;
- one successful workload proves general Linux support;
- AI assistance invalidates or validates the engineering result by itself;
- a high provisional score is a benchmark victory.

The point of the scorecard is precisely the opposite: **turn an argument about taste, architecture, or AI into a sequence of measurements that can survive criticism.**

---

# The result Morphic is trying to earn

The strongest future claim is not:

> "Morphic has more features than Linux-compatible project X."

It is something measurable in this form:

> **At commit X, Morphic supports workload set Y from unchanged Alpine RV64 userspace using Z KLOC, N implemented Linux behaviors, B bytes of kernel/substrate image, and M MiB at the acceptance frontier. Compared with the declared reference systems, this yields a compatibility density of D under the published benchmark definition.**

That is a claim engineers can reproduce, dispute, improve, or falsify.

And whichever direction the result goes, we know more because the experiment was run.
