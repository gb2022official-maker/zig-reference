# zig-reference

> **Solved once. Documented completely. Reused forever.**

`zig-reference` is an experimental systems-research repository targeting Zig 0.14.0. It combines reusable low-level modules, machine-readable engineering knowledge, Morphic, the Alpz RV64 kernel path, Linux-compatibility research, QuirkM native-interface research, and future Wasm and virtualization directions.

## Research project

**Everything in this repository is research.** The kernel work, Morphic substrate, Alpz machine work, QuirkM, Linux personality, agent tooling, compatibility experiments, and future virtualization work are research artifacts unless a narrower proof establishes more.

This repository is not presented as production-ready infrastructure. Its larger purpose is to make operating-system construction itself observable enough that the project can answer questions about kernels, compatibility, software inheritance, AI-assisted engineering, and the cost of building new systems.

## Current milestone

# ★ PLAYABLE ALPINE UNDER MORPHIC ★

**Batch 32Q / PR #93 earned the complete Playable Alpine gate under real QEMU 8.2.2 using the canonical Alpine v3.22.0 RV64 namespace.** The proof now includes a persistent real BusyBox/musl shell, real external child execution, writable runtime state, external file read-back, a bounded real pipe carrying bytes between unchanged Alpine processes, ownership-correct EOF/lifetime behavior across the active child and suspended parent snapshot, and parent-shell survival after the pipeline.

The complete one-shell acceptance proof is:

```text
echo morphic                 -> morphic
echo second                  -> second
pwd                          -> /
ls /                         -> genuine serialized Alpine root entries
cat /etc/alpine-release      -> 3.22.0
cd /tmp                      -> success
pwd                          -> /tmp
echo hello > /tmp/hello      -> success
cat /tmp/hello               -> hello
echo hello | cat             -> hello
echo still-alive             -> still-alive
```

**Playable Alpine is complete. The active causal frontier has moved to the real Alpine package manager: `/sbin/apk --version`, then `apk --help`, followed by local package-database pressure, package filesystem transactions, local `.apk` installation, and only later networking/DNS/TLS for real repositories.**

See [`docs/reports/AGENTIC_SNOWBALL_BATCH_32Q.md`](docs/reports/AGENTIC_SNOWBALL_BATCH_32Q.md) and [`docs/roadmaps/PLAYABLE_ALPINE_TO_APK.md`](docs/roadmaps/PLAYABLE_ALPINE_TO_APK.md).

### Where Morphic sits in the AI-assisted OS landscape

AI-assisted operating-system projects are now interesting enough that the question **“can AI help build a substantial operating system?”** no longer has to remain hypothetical.

[SlopOS](https://github.com/SlopLabs/slopos) and [VibeOS](https://github.com/kaansenol5/VibeOS) are neighboring experiments that we respect. They demonstrate different, valuable parts of the emerging landscape. Morphic, Alpz, and QuirkM do not need those projects to be lesser in order for this project to ask a different class of questions.

**While SlopOS establishes that an AI-heavy development process can contribute to a remarkably substantial from-scratch Rust operating system that boots on real hardware, runs its own desktop and drivers, carries a large QEMU test suite, and applies machine-checked verification to important invariants, we aim to ask what such success can teach us about the structure underneath an operating system.** How much mechanism is actually fundamental? How much is historical representation? How much can remain replaceable? How much of a modern software world can be inherited without importing the architecture of the system that world originally grew up on?

**While VibeOS demonstrates that a Claude-assisted, from-scratch ARM64 operating system can advance through a graphical desktop, networking, a browser, development tools, MicroPython, TCC, and real Raspberry Pi hardware across documented development sessions, we choose to treat comparable increases in capability as experimental pressure as well as engineering milestones.** When a new workload starts working, Morphic wants to know exactly which new semantic requirement made that possible, which layer owns it, whether unrelated workloads reuse it, and whether the permanent substrate had to grow at all.

Those projects help establish that AI-assisted kernel and OS development can produce consequential artifacts. **Our intended contribution is to use the same historical moment to investigate deeper systems questions that are not answered merely by reaching a shell, a working desktop, an attractive display, a browser, or a long feature list.** Those achievements matter. We simply want the project to remain useful after they are achieved, because the system itself can then become experimental apparatus.

This is not a claim that Morphic is superior to SlopOS, VibeOS, Linux, or any other system. It is a statement of research direction. Different projects can be excellent answers to different questions.

### Kerla: a useful Linux-ABI comparison

[Kerla](https://github.com/nuta/kerla) is one of the most useful comparison points for Morphic because it pursued a closely related practical idea from a very different design and historical direction: a monolithic Rust kernel, written from scratch for x86_64, whose explicit goal is to run unmodified Linux binaries through Linux ABI compatibility.

Kerla is broader than Morphic today in several traditional kernel areas. Its documented surface includes `fork`, `execve`, `wait4`, signals, `mmap`, pipes, `poll`, tmpfs/devfs, TCP/IP through smoltcp, tty/pty support, QEMU and Firecracker, and an SSH demonstration. Morphic does **not** currently claim equivalent breadth: it still lacks general networking, broad signal semantics, poll/epoll-class readiness, a native completed TTY/pty stack, a general filesystem, and many other Linux interfaces.

There is also an interesting difference in what each project proved. Kerla's README explicitly notes that its experimental Docker-image path could not be expected to run most images and gives unimplemented position-independent executables used by Alpine Linux as an example. Morphic is already running an unchanged dynamic Alpine v3.22.0 RV64 musl/BusyBox environment through the real userspace interpreter, with a persistent shell, external processes, writable runtime state, external read-back, and a real pipeline. At the opening Batch 32R `apk` frontier, the real `/sbin/apk` binary already reaches `execve` commit and its dynamic loader opens `/usr/lib/libcrypto.so.3` and `/usr/lib/libapk.so.2.14.9` before encountering the next missing Linux/RV64 metadata semantic. See [`docs/plans/CODEX_AGENTIC_SNOWBALL_BATCH_32R_FSTAT_TO_APK_VERSION_MAXIMUM_CAUSAL_PROGRESS_MANDATORY_30MIN_HANDOFF.txt`](docs/plans/CODEX_AGENTIC_SNOWBALL_BATCH_32R_FSTAT_TO_APK_VERSION_MAXIMUM_CAUSAL_PROGRESS_MANDATORY_30MIN_HANDOFF.txt).

**That does not make Morphic “more complete” than Kerla.** The projects have accumulated capability in different directions. Kerla currently demonstrates a much wider conventional Unix/kernel surface; Morphic has reached unusually deep modern Alpine/dynamic-userspace compatibility on a narrower RV64 substrate.

A compact comparison:

| Dimension | Kerla | Morphic / Alpz today |
|---|---|---|
| Implementation direction | Monolithic Rust kernel | Zig-centered Morphic substrate + Alpz RV64 machine path + Linux personality |
| Primary architecture | x86_64 | RV64 |
| Linux-process breadth | Broad `fork`/`execve`/`wait4`, signals, mmap, poll, etc. | Bounded clone/exec model sufficient for the current Alpine acceptance path; much narrower overall |
| IPC / readiness | Pipe and poll documented | Bounded pipe2 byte streams; no general poll/epoll claim |
| Terminal support | tty + pty documented | Guest console works; human-friendly PTY+picocom host path; native complete TTY/termios semantics not yet claimed |
| Networking | TCP/IP, UDP/TCP sockets, SSH demo | Not yet implemented |
| Filesystem direction | initramfs root plus tmpfs/devfs | Exact immutable Alpine namespace plus deliberately tiny bounded writable runtime overlay |
| Alpine-specific proof | README identifies Alpine PIE as an obstacle in its experimental image path | Exact Alpine v3.22.0 RV64 dynamic musl/BusyBox shell is Playable; real `apk` loader pressure is underway |
| Current maturity claim | Historical project with a much broader demonstrated system surface; no longer maintained | Fast-moving research prototype; explicitly not production-ready |

#### The rate of progress is extraordinary, but the stopwatch needs context

The Morphic chronology is unusually fast in a narrow, measurable sense. The preserved repository baseline is **2026-08-04 04:32 CST** and the Playable Alpine merge is **2026-08-15 15:39:43 CST**: **275.13 hours, or 11 days 11 hours 7 minutes 43 seconds** of calendar time. From the first static BusyBox shell milestone to Playable Alpine was only **45.64 hours**, or just under two days.

That is an extraordinary research-prototyping velocity result. In less than two calendar weeks the project moved from its preserved baseline to real dynamic musl, real BusyBox, an exact 517-object Alpine namespace, a persistent interactive shell, clone/exec external commands, directory enumeration, immutable file reads, cwd, bounded writable state, descriptor replacement, external read-back, and a real pipe carrying bytes between unchanged Alpine processes. On the same day Playable Alpine was earned, the next real pressure had already moved inside `/sbin/apk`'s dynamic-loader path.

But **11.5 calendar days is not the same thing as 275 engineer-hours**, and it should not be presented that way. This repository uses intensive AI-assisted/agentic iteration, automated validation, preserved causal handoffs, and rapid retry loops. There is no honest one-to-one conversion from wall-clock time here to the labor time of a conventional single developer or team. The useful metric is **time-to-reproducible capability frontier**, not a claim about equivalent human-hours.

Kerla provides a good historical control for that distinction. Its public GitHub repository was created on May 18, 2021, but author Seiya Nuta wrote the next day in [“Writing a Linux-compatible kernel in Rust”](https://seiya.me/blog/writing-linux-clone-in-rust) that he had already been working on Kerla for **recent months** and had implemented fork/exec, file operations, TCP/UDP sockets, signals, tty/pty, pipes, poll, and more. In other words, Kerla's public repository creation date is not its true project stopwatch; the substantial early feature set represented months of prior work.

There is also a striking modern reference from the same author. In 2026 Nuta documented [“New microkernel OS in 10 days: From zero to Google Compute Engine”](https://seiya.me/blog/new-microkernel-os-in-10-days), showing that a highly experienced systems engineer with accumulated knowledge and modern tooling can compress a serious OS prototype into roughly a ten-day experiment. In that project he says GPT-5.2-Codex was used for review and debugging rather than agentic coding. The goals and architecture are different, so this is not a race result; it is a useful real-world calibration that **ten-day-scale operating-system leaps are possible when expertise, tooling, scope, and feedback loops line up**.

Kerla also demonstrates how much farther “real deployment” is from an early compatibility milestone. By December 2021, Nuta documented [running his personal website on Kerla](https://seiya.me/blog/this-website-is-now-powered-by-kerla): two Kerla VMs behind a load balancer, each on a 1-core / 1-GB server, with crash recovery, metrics, and alerting. He also documented remaining instability and periodic reboots from memory exhaustion. That is a concrete level of operational maturity Morphic has **not** reached; Morphic's current proof remains a QEMU-centered research environment.

So the remarkable claim should stay precise:

> **In about 11.5 calendar days, Morphic reached a reproducible Playable Alpine RV64 frontier that includes unchanged dynamic musl/BusyBox userspace and immediately began pressuring the real Alpine package manager. That rate is genuinely exceptional for systems research prototyping. It is not evidence that Morphic already matches the breadth, deployment maturity, or production experience of longer-running kernels such as Kerla.**

The comparison becomes more interesting, not less, if both facts remain visible at once: **Kerla is broader; Morphic's measured early compatibility velocity is unusually high.**

### A possible first-of-its-kind Zig milestone

There are already operating-system kernels written in Zig, and there are already non-Linux systems capable of running Linux software. The narrower combination pursued here appears much rarer. **To the best of our current public-source search, we have not found another publicly documented Zig-written, non-Linux RISC-V kernel/substrate that runs an unchanged real Alpine Linux musl/BusyBox userspace through a Linux ABI compatibility edge.**

That is deliberately a qualified research-positioning claim, not a declaration that every private, unpublished, or obscure project has been exhaustively ruled out. It also does not claim that Morphic would be the first non-Linux system to run Linux binaries; mature projects in other languages already occupy that broader space.

Morphic has now earned the reproducible **★ PLAYABLE ALPINE ★** gate defined below. The project therefore appears to have reached a **likely first-of-its-kind milestone in the public Zig operating-system ecosystem**: a Zig-centered, RV64, non-Linux substrate running unchanged real Alpine userspace through compatibility rather than through a Zig-native replacement userland. If real `apk` later crosses the local-install and networked-package gates, that distinction becomes substantially stronger because the inherited Alpine ecosystem itself, rather than only individual binaries, becomes the pressure source.

This claim should remain evidence-bound. If a prior or contemporary public project demonstrating the same combination is found, this section should be corrected and the comparison documented rather than defended rhetorically.

### The central Morphic question

The project is organized around a question that can be tested rather than merely advertised:

> **What is the smallest durable operating-system substrate capable of inheriting a modern software civilization without permanently inheriting the architecture of the operating system that civilization grew up on?**

A closely related hypothesis is the **Morphic Convergence Hypothesis**:

> **As a neutral operating-system substrate acquires the genuinely general semantics demanded by diverse real workloads, the rate at which additional inherited software requires new permanent substrate mechanisms approaches zero.**

In short: **does the kernel converge?**

If the answer is yes, increasingly large software ecosystems should eventually run while the neutral permanent substrate changes less and less. If the answer is no, that negative result is equally valuable: Morphic can show where semantic growth refuses to compress and why.

See [`docs/research/MORPHIC_CONVERGENCE_HYPOTHESIS.md`](docs/research/MORPHIC_CONVERGENCE_HYPOTHESIS.md).

### Questions this project is unusually positioned to investigate

Morphic is being built so that each compatibility frontier leaves behind machine evidence, causal failures, explicit semantic repairs, and a record of where each mechanism lives. That makes the repository suitable for questions that are difficult to isolate in a mature monolithic system.

#### What does a modern operating system actually need to provide?

Not everything Linux has accumulated. Not everything POSIX names. What does diverse real software *causally require* beneath those interfaces?

#### Does the permanent kernel semantic surface converge?

As we move from static programs to BusyBox, musl, real Alpine, `apk`, language runtimes, databases, browsers, graphical environments, scientific software, servers, and other workload families, does the rate of new permanent Morphic semantics fall?

#### How much historical API surface is representation rather than fundamental mechanism?

Can many Linux syscalls, ioctls, errno conventions, descriptor behaviors, and ABI structures be translated onto a smaller number of neutral operations? If so, how much semantic compression is possible without lying about behavior?

#### Can compatibility be migration scaffolding rather than permanent architecture?

Can Linux compatibility become broad and useful while Linux-specific meaning remains at a replaceable edge? Can another personality later reuse the same substrate without forcing a redesign?

#### Can one substrate support mutually incompatible systems ideas?

Can alternative schedulers, allocators, IPC models, filesystems, security models, task models, networking designs, deterministic execution models, VM mechanisms, or native APIs be evaluated against a shared substrate and shared workload corpus rather than each experiment reconstructing an entire operating system?

#### Can kernel experiments inherit a software civilization without first rebuilding one?

A new kernel idea often pays a huge bootstrap cost before the actual research begins. Morphic asks whether a researcher can reuse proven executable loading, compatibility translation, resource semantics, machine evidence, test workloads, and other neutral mechanisms, then replace the component they actually want to study.

#### Can a common proving ground reduce the marginal cost of kernel development?

This is a major long-term question for the repository.

Suppose a researcher wants to test a scheduler, memory manager, capability system, IPC design, filesystem, VM mechanism, or security policy. Today that idea may require months of unrelated bootstrapping before it encounters serious software.

Morphic aims to investigate whether the path can become closer to:

```text
new kernel/system hypothesis
        |
        v
reuse proven neutral mechanisms
        |
        v
insert or replace the mechanism under study
        |
        v
run the same workload-pressure corpus
        |
        v
compare behavior, evidence, failures, and semantic cost
```

The ambitious future is a **kernel and systems testing ground** where researchers can reach consequential workloads sooner because solved boundaries remain reusable.

“If it runs through Morphic, it will run everywhere” would be an unjustified claim, and this project will not make it. The research question is narrower and more useful: **can a shared substrate, compatibility corpus, and proof record substantially reduce the amount of unrelated work a new kernel experiment must repeat before its central hypothesis can be tested?**

#### Can cross-architecture work distinguish semantics from machinery?

RISC-V is the current proving architecture. A future second architecture can test which mechanisms are truly semantic, which belong to the platform backend, and how much of the system survives a hardware transition unchanged.

#### Can a second ABI personality expose hidden Linux assumptions?

Linux is currently the strongest compatibility pressure source. A future second personality would be a powerful falsification test. If apparently neutral Morphic mechanisms must be redesigned around assumptions inherited from Linux, we learn that the neutrality claim was weaker than believed.

#### Which workloads exert the highest semantic pressure?

Does a package manager change the substrate more than a language runtime? Does a database introduce more fundamental mechanism than a graphical desktop? Does a browser? A JIT? A scientific workload? A hypervisor? Morphic can measure the answer rather than guess.

#### Which mechanisms provide the highest software-unlock value?

For each admitted mechanism, how much unrelated software becomes possible afterward? Which mechanisms are repeatedly reused, and which were accidental one-workload residue?

#### How small can the trusted and permanent surface remain while capability explodes above it?

Total userspace may become enormous. The research target is not a tiny repository. It is understanding how much code and state must remain privileged, trusted, semantically permanent, or architecture-defining as the inherited world expands.

#### Can AI-assisted development produce better experimental history, not merely more code?

This repository records agent contracts, causal failures, machine evidence, validation artifacts, handoffs, and exact workload frontiers. We want to investigate whether AI-assisted development can produce a systems history that is unusually inspectable and reproducible, rather than merely increasing coding speed.

#### Can failure itself become reusable engineering knowledge?

A failed ELF load, missing syscall semantic, incorrect page permission, ABI mismatch, or process-lifetime bug should not disappear into chat history. Can those failures become indexed artifacts that prevent future kernels, ports, and agents from paying the same discovery cost again?

### The Morphic Semantic Atlas

A central future research artifact is the **Morphic Semantic Atlas**: a versioned, preferably machine-readable mapping from real workload frontiers to the neutral semantics they actually required.

Conceptually:

```text
WORKLOAD                       NEW NEUTRAL SEMANTICS       CUMULATIVE FRONTIER
----------------------------   -------------------------   -------------------
static userspace               measured                    measured
static BusyBox                 measured                    measured
static shell                   measured                    measured
dynamic musl                   measured                    measured
dynamic BusyBox                measured                    measured
real Alpine                    measured                    measured
interactive Alpine             measured                    measured
read-only Alpine               measured                    measured
playable Alpine                measured                    earned
apk                            future                      current pressure
Python                         future                      future
Git                            future                      future
SQLite                         future                      future
SSH                            future                      future
scientific stack               future                      future
browser engine                 future                      future
desktop                        future                      future
second ABI personality         future                      future
second hardware architecture   future                      future
```

The numbers must come from evidence, not from promotional estimates.

A mature atlas could support comparative work on semantic compression, trusted-surface growth, compatibility cost, mechanism reuse, workload pressure, cross-architecture stability, and convergence.

### Morphic as a future research launching dock

The long-term aim is broader than making one kernel implementation impressive.

We would like Morphic to become a **launching dock for systems inquiry**: a place where researchers, students, engineers, and agents can introduce a hypothesis without first recreating every unrelated solved boundary.

Possible future experiments include:

- replace the scheduler and run identical workload pressure;
- substitute a capability or object-security model;
- compare IPC designs under the same userspace;
- test alternative address-space and page-management policies;
- compare filesystem semantics without replacing the entire execution environment;
- study deterministic execution or record/replay;
- insert a new networking model;
- compare native QuirkM APIs with Linux compatibility over the same Morphic capabilities;
- introduce a second compatibility personality;
- move the substrate to another architecture;
- study VM/vCPU and hypervisor mechanisms;
- compare agent-generated kernel components using identical validation and workload evidence;
- measure which changes actually increase the admissible hypothesis space.

The ideal result is that future researchers spend more time testing the mechanism they care about and less time rebuilding boot code, loaders, test harnesses, compatibility plumbing, or userspace merely to reach the experiment.

See [`docs/research/MORPHIC_GENERAL_SYSTEMS_RESEARCH_SUBSTRATE_PROPOSAL.md`](docs/research/MORPHIC_GENERAL_SYSTEMS_RESEARCH_SUBSTRATE_PROPOSAL.md).

### We invite examination, including hostile examination

We want this repository studied, compared, reproduced, criticized, extended, and contradicted.

Useful future work includes questions such as:

```text
Does the Morphic convergence curve actually flatten?

Which Linux interfaces refuse semantic compression?

Does a database workload falsify mechanisms that looked general under Alpine?

Does a browser force permanent complexity back into the core?

Can a second personality reuse Morphic without Linux contamination?

Can another architecture preserve the same semantic decomposition?

Does a replacement scheduler inherit the same software frontier?

Can Morphic shorten time-to-experiment for a new kernel design?

Which Morphic abstractions are wrong?

Which can be deleted?

Which are missing?
```

A result that disproves a favored Morphic idea is not an attack on the project. It is research progress.

### Research launching points

If you want to study the project rather than merely boot it, begin here:

- [`docs/research/MORPHIC_CONVERGENCE_HYPOTHESIS.md`](docs/research/MORPHIC_CONVERGENCE_HYPOTHESIS.md) — the convergence thesis, Semantic Atlas, measurements, and falsifiability requirements.
- [`docs/research/MORPHIC_GENERAL_SYSTEMS_RESEARCH_SUBSTRATE_PROPOSAL.md`](docs/research/MORPHIC_GENERAL_SYSTEMS_RESEARCH_SUBSTRATE_PROPOSAL.md) — Morphic as a shared substrate for many classes of systems experiments.
- [`docs/papers/COMPATIBILITY_AS_MIGRATION_SCAFFOLD.md`](docs/papers/COMPATIBILITY_AS_MIGRATION_SCAFFOLD.md) — compatibility as an edge and migration instrument rather than permanent ontology.
- [`docs/research/FRESH_AGENT_ADVANCEMENT_AND_INHERITABLE_TECHNICAL_KNOWLEDGE.md`](docs/research/FRESH_AGENT_ADVANCEMENT_AND_INHERITABLE_TECHNICAL_KNOWLEDGE.md) — whether fresh agents can inherit enough explicit knowledge to advance systems work.
- [`docs/research/AGENT_FRAMEWORK_FAILURE_LEDGER.md`](docs/research/AGENT_FRAMEWORK_FAILURE_LEDGER.md) — preserved failures as research evidence.
- [`docs/reports/`](docs/reports/) — concrete implementation frontiers and machine evidence.
- [`COMMANDS.md`](COMMANDS.md) — durable reproduction commands.

The aspiration is not merely to join the genre of AI-assisted operating systems. **It is to help turn that genre into something researchers can measure.** SlopOS, VibeOS, Morphic, and future projects can then be more than impressive demonstrations in isolation: together they can become evidence about how AI changes systems construction, which architectures survive real workloads, what complexity is actually necessary, and how much development effort future kernels might inherit instead of repeat.

## What the names mean

| Name | Role |
|---|---|
| **Z-Ref** | Reusable knowledge and evidence: modules, contracts, tests, proof records, indexes, diagnostics, and agent-facing discovery. |
| **Morphic** | Shared architectural and semantic substrate. |
| **Alpz** | Current RV64 kernel/machine embodiment and Linux-compatibility proving ground. |
| **QuirkM** | Proposed clean native Morphic personality/API. |
| **Linux personality** | Compatibility edge for Linux-specific behavior that should not define Morphic internally. |

```text
software / agents
      |
      +--> QuirkM native
      +--> Linux personality
      +--> future Wasm
                |
                v
             MORPHIC
                |
                v
              ALPZ
                |
              RV64
```

## QuirkM research goal

QuirkM asks how much historical compatibility tax a new native system can avoid once compatibility is separated from permanent architecture.

Linux has extraordinary practical strengths, especially compatibility and ecosystem depth. Those same strengths make some old interfaces and accumulated semantic constraints difficult to remove without breaking existing software.

QuirkM therefore treats Linux compatibility history as **design evidence**, not a mandatory native blueprint.

> **Keep the capabilities. Preserve compatibility where it is valuable. Remove avoidable historical taxes from the native path.**

This is a research hypothesis, not a claim that QuirkM has already solved every problem inherited by mature operating systems.

## Build beyond us

This project is not intended to be a ceiling.

If another researcher, engineer, student, team, company, or agent-assisted project wants to use Morphic ideas to build a **larger, more capable, more specialized, or better system than QuirkM itself**, that is welcome.

Building **on top of** QuirkM, Morphic, or Alpz is welcome too.

The desired legacy is a foundation, body of evidence, and collection of solved mechanisms that make future systems cheaper to understand and build.

```text
zig-reference / Z-Ref
        |
      Morphic
      /    \
   Alpz   QuirkM
      \    /
       \  /
   YOUR SYSTEM MAY BEGIN
```

**This repository is MIT-licensed. Anyone may use, copy, modify, merge, publish, distribute, sublicense, sell, fork, extend, or build on this work under the terms of the MIT License.** No additional permission from this project is required beyond compliance with that license.

If you want to build a bigger system than QuirkM, replace parts of Morphic, turn Alpz into something we never planned, build a commercial product, or use this work as the foundation of a completely different operating system, you are welcome to do so.

See [`LICENSE`](LICENSE).

## Core architectural rule

Compatibility pressure should reveal general mechanisms without forcing historical compatibility details into the permanent core.

```text
real software pressure
        |
        v
what capability is missing?
        |
        +--> general mechanism --> Morphic
        |
        +--> compatibility-only behavior --> personality edge
```

See [`docs/papers/COMPATIBILITY_AS_MIGRATION_SCAFFOLD.md`](docs/papers/COMPATIBILITY_AS_MIGRATION_SCAFFOLD.md) and [`docs/concepts/QuirkM/`](docs/concepts/QuirkM/).

## MinMax Memo™

> **Minimum implementation surface. Maximum capability surface. Maximum whole-system mental model.**

The goal is not the smallest kernel at any cost. It is the smallest coherent foundation that unlocks the largest useful computing world while remaining understandable.

## Current machine milestone

# ★ PLAYABLE ALPINE UNDER MORPHIC ★

**Morphic now runs the exact Alpine v3.22.0 RV64 namespace through the real musl interpreter and BusyBox `/bin/sh`, preserves a persistent interactive shell, executes real external BusyBox applets through bounded clone/exec, enumerates and reads the genuine serialized namespace, maintains bounded per-process current-working-directory state, supports a bounded writable runtime namespace, and now carries real bytes through a bounded pipe between unchanged Alpine processes while preserving descriptor/resource ownership and parent-shell liveness.**

Batch 32Q closed the pipeline gate and the PR #93 ownership follow-up repaired the two subtle lifetime holes exposed during review: writer/endpoint discovery now spans both active child state and the suspended parent snapshot, and dup3 displacement runs the same ownership-aware final-pipe retirement check. The generic dup3 helper remains pipe-independent.

```text
exact Alpine v3.22.0 RV64 minirootfs       PASS
complete namespace: 517 objects            PASS
regular-file backing: 7,069,903 bytes      PASS
runtime /bin/sh -> /bin/busybox lookup     PASS
same-namespace real musl PT_INTERP lookup  PASS
real ld-musl interpreter-first             PASS
PREPARE -> COMMIT -> execute               PASS
exec mapping/table-capacity preflight      PASS
W+X=0                                      PASS
SUM clear                                  PASS

live keyboard input                        PASS
real interactive BusyBox /bin/sh           PASS
echo morphic                               PASS
persistent second command                  PASS
pwd -> /                                   PASS
ls /                                       PASS
cat /etc/alpine-release -> 3.22.0          PASS

clone(220) + real child                    PASS
execve(221) + real BusyBox applets         PASS
parent restoration                         PASS
bounded cwd / chdir / getcwd               PASS
cd /tmp ; pwd -> /tmp                      PASS

bounded writable runtime namespace         PASS
transactional create/truncate              PASS
F_DUPFD compatibility + ownership          PASS
dup3(24) target replacement                PASS
echo hello > /tmp/hello                    PASS
cat /tmp/hello -> hello                    PASS

pipe2(59)                                  PASS
bounded FIFO pipe bytes                    PASS
read/write endpoint capabilities           PASS
clone/exec descriptor inheritance          PASS
dup/close endpoint lifetime                PASS
EOF waits for all meaningful writers       PASS
suspended-parent ownership                 PASS
dup3 displaced-endpoint retirement         PASS
echo hello | cat -> hello                  PASS
echo still-alive                           PASS

★ PLAYABLE ALPINE UNDER MORPHIC ★          EARNED

/sbin/apk --version                        CURRENT PRESSURE
apk local database / metadata              NEXT
filesystem package transactions            NEXT
local .apk extraction + install            FUTURE
★ LOCAL APK UNDER MORPHIC ★                 FUTURE
networking / DNS / clocks / entropy        FUTURE
userspace TLS + CA trust                    FUTURE
apk update / apk add                        FUTURE
★ NETWORKED APK UNDER MORPHIC ★             FUTURE
```

The proof is runtime evidence, not compile-only inference. Known limitations remain explicit: incomplete component-wise symlink semantics, a tiny four-object/256-byte runtime overlay, a serialized single-child execution model, two bounded 4096-byte pipe streams, and deliberately narrow Linux ABI coverage. None invalidates the exact Playable Alpine acceptance proof.

See [`docs/reports/AGENTIC_SNOWBALL_BATCH_32Q.md`](docs/reports/AGENTIC_SNOWBALL_BATCH_32Q.md).

## Roadmap: Playable Alpine -> local apk -> networked apk

The full pressure-driven roadmap is maintained in [`docs/roadmaps/PLAYABLE_ALPINE_TO_APK.md`](docs/roadmaps/PLAYABLE_ALPINE_TO_APK.md).

At a glance:

```text
★ PLAYABLE ALPINE UNDER MORPHIC ★          EARNED
        |
        v
CURRENT: real /sbin/apk --version pressure
        |
        v
apk --help / startup semantics
        |
        v
apk local database / metadata reads
        |
        v
filesystem package transactions
mkdir / unlink / rename / metadata / larger bounded storage
        |
        v
local .apk extraction + install
        |
        v
run an unchanged installed program
        |
        v
★ LOCAL APK UNDER MORPHIC ★
        |
        v
sockets + DNS + clocks + entropy
        |
        v
userspace TLS + CA trust + repository transport
        |
        v
apk update
        |
        v
apk add <small-package>
        |
        v
run the newly installed program
        |
        v
★ NETWORKED APK UNDER MORPHIC ★
```

The Playable Alpine gate is deliberately narrow and reproducible. One persistent real shell has completed:

```text
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

`apk` is now the pressure source rather than a single syscall milestone. Local package work comes before networking so filesystem/database/package-transaction semantics can be isolated from DNS/TCP/TLS. Only after a real local `.apk` can be installed should the campaign add the network substrate required for `apk update` and `apk add` against real Alpine repositories.

## Experience Playable Alpine in your own console

You can reproduce the current live Morphic/Alpine state from a fresh clone. This is the same exact Alpine namespace and system-QEMU pressure used by the Snowball reports; it gives you a real interactive BusyBox/musl shell rather than a synthetic transcript.

> **Current console-input limitation:** Playable Alpine proves real guest command execution, persistence, external processes, files, and pipelines. It does **not** yet claim a completed guest TTY/termios stack. With the simplest QEMU `-nographic` path, typed characters may not be visibly echoed and some terminal setups may require `Ctrl-J` (LF) rather than Return to submit a line. The acceptance proof is based on observed guest command output, not on visible local keystroke echo.

For the clearest human-facing experience today, use the **QEMU PTY + picocom path** below. It provides visible local typing and maps Return to LF while leaving the guest/runtime semantics unchanged. The local echo is host-side presentation assistance; it is not being claimed as native Morphic TTY echo.

Prerequisites:

- Git
- Python 3
- Zig **0.14.0**
- `qemu-system-riscv64`
- Internet access for the hash-pinned Alpine v3.22.0 RV64 minirootfs download
- `picocom` for the recommended visible-input console path

On Arch Linux / Garuda Linux, install picocom with:

```sh
sudo pacman -S picocom
```

On Debian / Ubuntu:

```sh
sudo apt install picocom
```

On Fedora:

```sh
sudo dnf install picocom
```

Clone and enter the repository:

```sh
git clone https://github.com/thanks-cohn/zig-reference.git
cd zig-reference
git switch main
git pull --ff-only
```

Confirm the important host tools:

```sh
zig version
qemu-system-riscv64 --version
python3 --version
```

`zig version` must report `0.14.0`.

Generate the complete verified Alpine namespace:

```sh
rm -rf /tmp/zigref-namespace /tmp/alpine-machine

PYTHONDONTWRITEBYTECODE=1 python3 \
  tools/pressure-real-rv64-alpine-minirootfs.py \
  --artifact-only \
  --namespace-output-dir /tmp/zigref-namespace
```

The acquisition tool verifies the pinned Alpine archive, `/bin/sh -> /bin/busybox`, the real musl interpreter, the complete 517-object namespace, and the immutable serialized regular-file backing before the machine is built.

Build Morphic with that exact namespace and live console input:

```sh
zig build install-freestanding-riscv64-morphic-runtime \
  -Dexternal-rv64-namespace-manifest=/tmp/zigref-namespace/namespace.json \
  -Dexternal-rv64-namespace-data=/tmp/zigref-namespace/namespace.data \
  -Dexternal-rv64-argv0=/bin/sh \
  -Dexternal-rv64-live-console-input=true \
  --prefix /tmp/alpine-machine
```

### Recommended: visible-input console with QEMU PTY + picocom

Use two terminal windows.

**Terminal 1 — start Morphic and expose its serial console as a host PTY:**

```sh
qemu-system-riscv64 \
  -machine virt \
  -display none \
  -monitor none \
  -bios default \
  -chardev pty,id=morphic \
  -serial chardev:morphic \
  -kernel /tmp/alpine-machine/bin/morphic-freestanding-riscv64
```

QEMU prints the PTY it allocated, for example:

```text
char device redirected to /dev/pts/1 (label morphic)
```

Keep Terminal 1 running.

**Terminal 2 — attach picocom to the PTY QEMU printed:**

```sh
picocom --echo --omap crlf /dev/pts/1
```

Replace `/dev/pts/1` with the actual `/dev/pts/N` shown by QEMU.

The two important options are:

- `--echo`: display locally what you type, so the shell is not a blind-input experience.
- `--omap crlf`: map carriage return to line feed so ordinary Return/Enter can submit commands to the current console path.

A successful attachment ends with:

```text
Terminal ready
```

At that point, type commands normally. In the tested Konsole + picocom path, typed commands are visible and ordinary Return/Enter submits them. If a different terminal still does not submit a line, `Ctrl-J` remains the fallback.

Conceptually:

```text
Morphic guest serial console
          |
          v
QEMU PTY (/dev/pts/N)
          |
          v
picocom --echo --omap crlf
          |
          v
visible, human-friendly host terminal
```

Again, this presentation path does not upgrade the milestone claim: visible input is currently provided by picocom's local echo, while complete native TTY/termios behavior remains future compatibility work.

### Simpler direct QEMU console

If visible local typing is not important, the original one-terminal path remains available:

```sh
qemu-system-riscv64 \
  -machine virt \
  -nographic \
  -bios default \
  -kernel /tmp/alpine-machine/bin/morphic-freestanding-riscv64
```

With this path, typed characters may not appear on screen. Type the command and use Return if it works in your terminal; otherwise use `Ctrl-J` to submit the line.

After Morphic's proof/trace output, use the live Alpine shell. The complete earned sequence is:

```text
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

The important user-visible results include:

```text
morphic
second
/
...
3.22.0
/tmp
hello
hello
still-alive
```

`ls /` prints genuine entries from the exact serialized Alpine root namespace, including directories such as `bin`, `dev`, `etc`, `home`, `lib`, `proc`, `tmp`, `usr`, and `var`.

The next causal pressure is deliberately not claimed as working yet:

```text
/sbin/apk --version
```

That real unchanged binary is the opening gate of the package-manager phase.

To leave QEMU's `-nographic` console, use QEMU's terminal escape sequence (`Ctrl-A`, then `X`).

The canonical command record lives in [`COMMANDS.md`](COMMANDS.md).

## Come attack the next boundary

This is a good time to join the project.

The shell milestone is now complete. The next questions concern how much additional neutral mechanism a real package manager and then a package ecosystem actually force into the substrate.

If you work on kernels, Zig, RISC-V, ELF, linkers/loaders, filesystems, process models, verification, virtualization, capability systems, compatibility layers, reproducible systems research, or agent-assisted engineering, there is useful work here now.

You do **not** have to accept the current architecture as sacred. A strong result that proves a Morphic or QuirkM idea wrong is valuable. A smaller mechanism, a cleaner proof, a better abstraction, a stronger negative result, or an entirely better system built from these pieces is welcome.

Some of the next concrete questions are:

- What is the first unchanged runtime boundary exposed by real Alpine `/sbin/apk --version`?
- Which startup/version/help requirements are genuinely causal, and which Linux calls can remain compatibility-edge failures?
- How much of Alpine's local package database can be traversed through mechanisms Morphic already has?
- Which directory, pathname, metadata, rename, unlink, permission, timestamp, or locking semantics become causal for package transactions?
- How large and general must the bounded writable runtime become before a real local `.apk` can install?
- Can local installation be earned before networking, cleanly separating package/filesystem semantics from sockets/DNS/TLS?
- Can an unchanged program installed by real `apk` execute without a Morphic-specific port?
- Which Linux behaviors belong at the compatibility edge, and which reveal reusable Morphic mechanisms?
- Does the permanent semantic growth rate begin flattening as `apk` unlocks more unrelated Alpine software?
- How far can the privileged core remain small and understandable while the capability surface grows?

Bring a counterexample. Bring a trace. Bring a weird package. Bring a cleaner abstraction. Bring a PR that deletes more complexity than it adds.

**The goal is not to protect the current design. The goal is to discover the best system we can build.**

## Time to milestone

The earliest preserved commit is the reproducible project-time baseline.

```text
Repository baseline / first commit:     2026-08-04 04:32:00 CST
First static BusyBox shell milestone:   2026-08-13 18:01:04 CST
Playable Alpine merge milestone:        2026-08-15 15:39:43 CST

TO PLAYABLE ALPINE FROM REPOSITORY START:       275.13 hours
TO PLAYABLE ALPINE FROM STATIC BUSYBOX SHELL:    45.64 hours

Exact elapsed from repository start:
11 days, 11 hours, 7 minutes, 43 seconds

Exact elapsed from first static BusyBox shell:
1 day, 21 hours, 38 minutes, 39 seconds
```

Milestone tag name:

`morphic-batch32q-playable-alpine-under-morphic`

Future major milestones should accumulate the same chronology line by line. The real dynamic-musl, dynamic-BusyBox-shell, first-real-Alpine, persistent-interactive-Alpine, read-only-Alpine, persistent-cwd, bounded-writable-runtime, shell-redirection, external-read-back, pipe, and Playable-Alpine milestones are now complete.

## Active frontier

**The exact active frontier is now the real Alpine `/sbin/apk --version` startup path. Playable Alpine itself is complete and ownership-correct under the bounded Batch 32Q process/pipe model.**

```text
FIRST STATIC BUSYBOX SHELL                complete
        |
        v
FIRST REAL DYNAMIC MUSL                   complete
        |
        v
DYNAMIC BUSYBOX SHELL                     complete
        |
        v
REAL ALPINE NAMESPACE                     complete
        |
        v
★ FIRST REAL ALPINE ★                     complete
        |
        v
PERSISTENT INTERACTIVE ALPINE SHELL       complete
        |
        v
BOUNDED clone(220) + REAL CHILD           complete
        |
        v
execve(221) + REAL BUSYBOX APPLETS        complete
        |
        v
openat(56) + getdents64(61)               complete
        |
        v
REAL ls / + DIRECTORY ENUMERATION         complete
        |
        v
REGULAR-FILE READ + alpine-release        complete
        |
        v
★ READ-ONLY ALPINE ★                      complete
        |
        v
chdir(49) + NEUTRAL CWD                   complete
        |
        v
WRITABLE /tmp RUNTIME STATE               complete
        |
        v
F_DUPFD + dup3 DESCRIPTOR REPLACEMENT     complete
        |
        v
SHELL REDIRECTION                         complete
        |
        v
EXTERNAL cat /tmp/hello READ-BACK         complete
        |
        v
pipe2 + BYTE FLOW + EOF/LIFETIME           complete
        |
        v
★ PLAYABLE ALPINE ★                       complete
        |
        v
/sbin/apk --version                       <-- exact current pressure
        |
        v
APK LOCAL DATABASE / METADATA             next
        |
        v
FILESYSTEM PACKAGE TRANSACTIONS           next
        |
        v
LOCAL .APK INSTALL TRANSACTION            future
        |
        v
★ LOCAL APK ★
        |
        v
SOCKETS / DNS / CLOCKS / ENTROPY
        |
        v
USERSPACE TLS + CA TRUST
        |
        v
apk update
        |
        v
apk add FROM REAL ALPINE REPOSITORIES
        |
        v
★ NETWORKED APK ★
```

Only real pressure should decide what filesystem, pathname, metadata, process, terminal, networking, or compatibility mechanisms are admitted next. The kernel should not grow a speculative Linux subsystem merely because Linux has one.

Completed reports now include Batch 32Q. See [`docs/reports/`](docs/reports/) for the preserved causal history.

Current roadmap:

- [`docs/roadmaps/PLAYABLE_ALPINE_TO_APK.md`](docs/roadmaps/PLAYABLE_ALPINE_TO_APK.md)

## Engineering model

> **Observed foreign API usage does not automatically justify permanent mechanism. Causal necessity does.**

The working loop is:

```text
observe real failure
      -> classify
      -> minimum general repair
      -> prove causality
      -> retry the same artifact
```

## Documentation

Start with [`docs/README.md`](docs/README.md), [`AGENTS.md`](AGENTS.md), [`COMMANDS.md`](COMMANDS.md), [`docs/porting/PORTING.md`](docs/porting/PORTING.md), [`docs/project_vocab.md`](docs/project_vocab.md), [`docs/research/MORPHIC_CONVERGENCE_HYPOTHESIS.md`](docs/research/MORPHIC_CONVERGENCE_HYPOTHESIS.md), [`docs/research/MORPHIC_GENERAL_SYSTEMS_RESEARCH_SUBSTRATE_PROPOSAL.md`](docs/research/MORPHIC_GENERAL_SYSTEMS_RESEARCH_SUBSTRATE_PROPOSAL.md), [`docs/concepts/QuirkM/`](docs/concepts/QuirkM/), [`docs/reports/AGENTIC_SNOWBALL_BATCH_32Q.md`](docs/reports/AGENTIC_SNOWBALL_BATCH_32Q.md), and [`docs/roadmaps/PLAYABLE_ALPINE_TO_APK.md`](docs/roadmaps/PLAYABLE_ALPINE_TO_APK.md).

## Validation

The broad repository gates are `zig build check` and `python3 tools/developer-command.py validate-repository`. Focused commands are documented in [`COMMANDS.md`](COMMANDS.md).

Do not weaken a gate merely to make new work pass. Fix the work or narrow the claim.

## Contributing

Contribution guidance lives in [`.github/CONTRIBUTING.md`](.github/CONTRIBUTING.md).

Research that proves an existing Morphic or QuirkM idea wrong is useful too. Prefer falsifiable evidence over protecting a favored architecture.

**If this problem space sounds fun, you are invited.** You do not need to wait for the project to become mature, and you do not need permission to explore a different direction. Fork it, test it, break an assumption, improve a mechanism, propose a competing design, or build something larger on top of it.

## Eventually: immediately testable workload challenges

The current focus is compatibility research, semantic compression, and building a reusable systems substrate. A mature Morphic, however, should eventually be able to turn those abstractions into demonstrations that anyone can understand and test immediately.

One long-horizon direction is **workload specialization**. General-purpose operating systems are designed to keep many possible activities available at once: services, desktop components, caches, launchers, background jobs, update machinery, networking, logging, and other work can remain alive while one foreground program is running. That is often the right tradeoff for a general-purpose machine. Because Morphic is being built as a new substrate, however, it gives us room to test a deliberately different policy when the user explicitly asks for it:

> **How much of the machine can safely belong to one chosen workload?**

Many computer users have had the ordinary experience of closing browsers, launchers, background applications, and services before starting a demanding game and wondering how much more of the machine could be devoted to the thing they are actually trying to do. Morphic should eventually turn that intuition into a measurable systems experiment rather than a marketing promise.

In the proposed **Appliance Mode**, after a real application already runs correctly through ordinary compatibility, Morphic could temporarily reorganize the machine around that workload. Optional services could be omitted or shut down, reclaimable caches surrendered under pressure, unnecessary background work reduced, CPU placement and scheduling biased toward the selected process tree, and nearly all RAM and CPU capacity not required for Morphic, the compatibility environment, and necessary devices made available to the workload.

The goal is not literal exclusive ownership. The substrate, page tables, resource metadata, drivers, required libraries, device queues, safety margins, and any compatibility machinery that the application actually needs still consume resources. The research target is simpler and testable: **everything that is not required for correctness should become a candidate to get out of the workload's way.**

A particularly concrete challenge is a fixed **8 or 16 GiB ordinary laptop**, especially a machine with integrated graphics where CPU and GPU share system memory. The eventual experiment would run the same demanding application on the same hardware under a conventional reference system, Morphic Normal Mode, and Morphic Appliance Mode, then compare measurable results such as available workload memory, platform RAM overhead, background CPU activity, context switches, frame-time distribution, 1%/0.1% lows, I/O latency, simulation rate, loading behavior, and application throughput.

Games are an appealing public pressure ladder because they combine graphics, input, audio, files, timers, threads, networking, memory pressure, simulation, and human-visible latency. The early ladder should prove graphical compatibility. The later ladder should deliberately favor **CPU-, memory-, simulation-, JVM/runtime-, and mod-heavy workloads whose graphics can be scaled down**, because those are the cases where resource specialization has the best chance of producing a meaningful result on ordinary hardware.

A candidate progression is:

1. **Freedoom / GZDoom** — first complete game loop and graphics/input proof.
2. **OpenArena / ioquake3** — mature real-time 3D, audio, input, networking, and timing pressure.
3. **SuperTuxKart** — broader packaged graphical/media dependency pressure.
4. **Xonotic** — a substantially richer real-time 3D workload.
5. **Dwarf Fortress** — simulation pressure with modest graphical requirements.
6. **Oxygen Not Included** — sustained simulation and memory/CPU pressure on relatively modest graphics.
7. **RimWorld**, especially large colonies and mod-heavy installs — simulation, allocation, mod/runtime, and long-frame pressure.
8. **Project Zomboid**, especially large or heavily modded worlds — JVM/runtime, world state, simulation, files, networking, and memory pressure.
9. **Kerbal Space Program**, especially complex or mod-heavy saves — physics, simulation, asset, CPU, and memory pressure.
10. **Minecraft: Java Edition**, especially large worlds and heavy modpacks — JVM heap, garbage collection, world streaming, assets, CPU, and memory pressure.
11. **Factorio: Space Age**, especially large factories/megabases — a flagship simulation/UPS benchmark and strong Appliance Mode candidate.
12. **Cities: Skylines**, especially asset- and mod-heavy cities — a direct 8/16 GiB memory-pressure and simulation challenge.
13. **Stellaris**, especially late-game large galaxies — a long-running simulation and scheduling/CPU-pressure challenge.
14. **A mainstream commercial CPU/memory-heavy title** once the required x86-64, graphics, audio, input, launcher/runtime, Vulkan/OpenGL, and possibly Proton/Wine paths genuinely exist.

These names are workload candidates, not support claims or promises. The exact versions, architectures, legal distribution paths, benchmark scenes, and graphics/runtime requirements must be chosen when each rung is reached. Real pressure may change the order.

There is an important nonclaim here: **RAM cannot replace GPU compute capability.** A title that is fundamentally limited by shader throughput, rasterization, ray tracing, VRAM bandwidth, or another hard graphics bottleneck will remain limited by the available graphics hardware. Morphic cannot turn an incapable GPU into a capable one merely by freeing system memory.

What specialization may be able to improve is the surrounding cost of running the workload: how much RAM remains available, how much shared memory an integrated GPU can access without competing with unnecessary processes, how much background CPU and I/O interference exists, whether the machine avoids swapping, whether frame-time spikes are reduced, whether a larger simulation or modpack fits, and how well constrained hardware is utilized. That is why **maximum playable workload on fixed inexpensive hardware** may ultimately be a more interesting metric than average FPS alone.

The standard should therefore be empirical rather than promotional: same machine, same application build, same graphics settings and resolution, same driver/hardware path where possible, reproducible scenes or traces, and publication of both wins and losses.

If Morphic eventually reaches the point where an ordinary 8 or 16 GiB laptop can dedicate nearly all of its usable machine budget to one heavy workload while preserving the workload's expected compatibility contract, that would be a compelling demonstration of how far the substrate has come. It would also generalize beyond games to compilers, databases, AI inference, emulators, renderers, scientific programs, and simulations.

The fuller proposal, including Normal/Focus/Appliance modes, resource-policy ideas, benchmark rules, and the game/workload pressure ladder, lives in [`docs/concepts/APPLIANCE_MODE_AND_WORKLOAD_SPECIALIZATION.md`](docs/concepts/APPLIANCE_MODE_AND_WORKLOAD_SPECIALIZATION.md).

## Scope and nonclaims

Alpz is **not Linux**, QuirkM is **not a completed native operating environment**, and Morphic is **not presented as a production kernel platform**.

The project now has real static-musl execution, a proven static Alpine BusyBox shell, successful real dynamic-musl execution through the real userspace interpreter, a proven dynamic Alpine BusyBox shell, **first real Alpine through a complete serialized Alpine v3.22.0 RV64 namespace**, a persistent interactive shell, bounded clone/exec external-command execution, genuine root-directory enumeration through `getdents64(61)`, real immutable regular-file reads including `/etc/alpine-release -> 3.22.0`, bounded neutral current-working-directory state mapped through Linux/RV64 `chdir(49)`/`getcwd(17)`, a bounded writable session-local runtime namespace, transactional create/truncate behavior, ownership-correct F_DUPFD and dup3-backed descriptor replacement, real shell redirection and external runtime-file read-back, and a real bounded `echo hello | cat` pipeline with parent-shell survival proven under QEMU. The complete one-shell acceptance sequence has earned **★ PLAYABLE ALPINE UNDER MORPHIC ★**. It does **not yet claim** broad relative-path semantics, complete component-wise symlink resolution, general Linux compatibility, local `.apk` installation, working `apk update` or `apk add`, production security, production readiness, or completed virtualization.

Proof records, exact artifacts, machine traces, validation gates, and current code define what has actually been achieved.
