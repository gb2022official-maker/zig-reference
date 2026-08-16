# Minimus Global Unlock Order

Each batch adds exactly **7 Linux syscalls**.

The batches are ranked by expected **global software-unlock leverage**, not by subsystem. Filesystem, process, networking, memory, signals, clocks, IPC, and threading calls are deliberately allowed to compete against one another.

The goal is simple:

> If Minimus can add only seven missing Linux syscalls next, choose the seven that unlock the most real software.

This is a planning prior, not scripture. Once real workload pressure produces better evidence, measured evidence wins.

## Current-state legend

- ✅ implemented/admitted by the current Morphic Linux/RV64 syscall dispatcher
- ⬜ not currently admitted by that dispatcher

A checkmark means the syscall has a real implementation path in the current bounded Linux personality. It does **not** claim complete Linux semantic coverage for every flag, object type, race, or edge case.

The current dispatcher already contains `getcwd`, `chdir`, `dup`, `dup3`, `fcntl`, `close`, `pipe2`, `openat`, `getdents64`, `read`, `write`, `writev`, `newfstatat`, `fstat`, `brk`, `munmap`, `clone`, `execve`, `mmap`, `mprotect`, and termination through `exit`/`exit_group`.

---

## Batch 1 — first survival surface

- ✅ `read`
- ✅ `write`
- ✅ `mmap`
- ✅ `munmap`
- ✅ `exit_group`
- ✅ `openat`
- ✅ `close`

**Current: 7 / 7**

These are the first seven because without basic I/O, mapped memory, file access, cleanup, and process termination, almost nothing useful survives long enough to expose more interesting requirements.

This entire first unlock batch is already present.

---

## Batch 2 — dynamic-program credibility

- ✅ `mprotect`
- ✅ `newfstatat`
- ✅ `fstat`
- ✅ `brk`
- ⬜ `futex`
- ⬜ `clock_gettime`
- ⬜ `rt_sigaction`

**Current: 4 / 7**

This batch attacks several common hidden dependencies at once:

- loader RELRO and memory-protection transitions
- pathname and descriptor metadata
- heap growth
- synchronization
- clocks
- signal initialization

The current project has already crossed the memory, metadata, and heap portion. The major remaining leverage here is threading/synchronization, time, and signals.

---

## Batch 3 — libc/runtime friction removal

- ⬜ `rt_sigprocmask`
- ⬜ `set_tid_address`
- ⬜ `ioctl`
- ⬜ `lseek`
- ⬜ `getpid`
- ⬜ `getrandom`
- ⬜ `readlinkat`

**Current: 0 / 7**

These are extremely common compatibility calls hiding inside otherwise ordinary programs.

This batch removes startup/runtime friction involving signal masks, libc thread bookkeeping, terminals/devices, seekable files, process identity, entropy initialization, and path discovery.

This is currently one of the largest untouched high-leverage clusters.

---

## Batch 4 — major process and network unlock

- ⬜ `socket`
- ⬜ `connect`
- ⬜ `poll`
- ✅ `getdents64`
- ✅ `execve`
- ✅ `clone`
- ⬜ `wait4`

**Current: 3 / 7**

This is a major unlock batch because it simultaneously opens networking, directory traversal, subprocess creation, shells, workers, and process-oriented programs.

Morphic has already earned the directory and child-execution side of this batch. The untouched half is especially valuable because `socket` + `connect` + `poll` would begin turning the system outward toward networked software, while `wait4` would deepen general child lifecycle semantics.

---

## Batch 5 — network reality plus Unix process plumbing

- ⬜ `sendto`
- ⬜ `recvfrom`
- ⬜ `setsockopt`
- ⬜ `getsockopt`
- ✅ `pipe2`
- ✅ `fcntl`
- ✅ `dup3`

**Current: 3 / 7**

At this point network clients become substantially real while Unix process plumbing becomes useful.

The process-plumbing half is already unusually strong: real descriptor manipulation and a real bounded pipe are part of the current Playable Alpine proof. The remaining four calls are all network leverage.

---

## Batch 6 — broad library and shell compatibility

- ⬜ `readv`
- ✅ `writev`
- ⬜ `ppoll`
- ⬜ `socketpair`
- ✅ `getcwd`
- ✅ `chdir`
- ⬜ `faccessat2`

**Current: 3 / 7**

This adds a surprising amount of compatibility for runtimes, shells, libraries, and IPC.

Morphic already has cwd navigation and vectored writes. The remaining calls would broaden generic library I/O, readiness waiting, local IPC, and modern access checking.

---

## Batch 7 — async runtimes and practical servers

- ⬜ `epoll_create1`
- ⬜ `epoll_ctl`
- ⬜ `epoll_pwait`
- ⬜ `bind`
- ⬜ `listen`
- ⬜ `accept4`
- ⬜ `shutdown`

**Current: 0 / 7**

This is another huge leap: asynchronous runtimes and real servers become practical.

Once basic socket creation/connectivity exists, these calls become disproportionately valuable because they open server-side and modern event-loop software rather than one narrow application.

---

## Batch 8 — deeper event-loop and socket semantics

- ⬜ `recvmsg`
- ⬜ `sendmsg`
- ⬜ `getsockname`
- ⬜ `getpeername`
- ⬜ `eventfd2`
- ⬜ `timerfd_create`
- ⬜ `timerfd_settime`

**Current: 0 / 7**

This deepens event-loop and networking compatibility enough for substantially heavier modern software.

`sendmsg`/`recvmsg` are particularly valuable because they also underpin ancillary data and many Unix-domain IPC patterns.

---

## Batch 9 — package, database, and source-tree mutation

- ⬜ `pread64`
- ⬜ `pwrite64`
- ⬜ `statx`
- ⬜ `renameat2`
- ⬜ `unlinkat`
- ⬜ `mkdirat`
- ⬜ `fsync`

**Current: 0 / 7**

This batch starts paying heavily toward package managers, databases, source-management tools, installers, caches, and applications that modify real filesystem trees.

This becomes especially important once `apk` advances from reading metadata into package extraction and transactional filesystem mutation.

---

## Batch 10 — durable installation and conventional Unix identity

- ⬜ `fdatasync`
- ⬜ `ftruncate`
- ⬜ `fchmod`
- ⬜ `fchownat`
- ⬜ `getuid`
- ⬜ `geteuid`
- ⬜ `getgid`

**Current: 0 / 7**

This pushes package installation, SQLite-like workloads, permissions, ownership, and conventional Unix software considerably farther.

---

## Batch 11 — modern multithreaded runtime expectations

- ⬜ `rseq`
- ⬜ `set_robust_list`
- ⬜ `tgkill`
- ⬜ `sigaltstack`
- ⬜ `prlimit64`
- ⬜ `sched_yield`
- ⬜ `madvise`

**Current: 0 / 7**

These are less visually exciting but can become enormously important once modern multithreaded runtimes are the pressure targets.

This is exactly the kind of batch a feature-oriented roadmap tends to postpone too long.

---

## Batch 12 — heavier runtimes and developer ecosystem

- ⬜ `mremap`
- ⬜ `memfd_create`
- ⬜ `nanosleep`
- ⬜ `clock_nanosleep`
- ⬜ `getrusage`
- ⬜ `sched_getaffinity`
- ⬜ `fstatfs`

**Current: 0 / 7**

This is where larger developer tools, language runtimes, databases, compilers, and browser-adjacent software get progressively happier.

---

# Current position

Across the first twelve seven-syscall batches:

```text
Batch 1   7 / 7   ███████   complete
Batch 2   4 / 7   ████░░░
Batch 3   0 / 7   ░░░░░░░
Batch 4   3 / 7   ███░░░░
Batch 5   3 / 7   ███░░░░
Batch 6   3 / 7   ███░░░░
Batch 7   0 / 7   ░░░░░░░
Batch 8   0 / 7   ░░░░░░░
Batch 9   0 / 7   ░░░░░░░
Batch 10  0 / 7   ░░░░░░░
Batch 11  0 / 7   ░░░░░░░
Batch 12  0 / 7   ░░░░░░░
```

That is **20 of these 84 ranked syscall slots already admitted** by the current dispatcher.

The distribution is intentionally non-linear. Morphic did not implement them in this theoretical order; real Alpine pressure pulled high-value calls from later batches forward. That is exactly the philosophy of Minimus.

A useful visual summary is:

```text
SURVIVAL CORE            [██████████]  done
LOADER/METADATA/HEAP     [██████░░░░]  substantial
LIBC RUNTIME EXTRAS      [░░░░░░░░░░]  largely untouched
PROCESS EXECUTION        [██████░░░░]  strong bounded slice
UNIX PROCESS PLUMBING    [██████░░░░]  strong bounded slice
NETWORKING               [░░░░░░░░░░]  major future unlock
ASYNC / SERVER SURFACE   [░░░░░░░░░░]  future
PACKAGE FS MUTATION      [░░░░░░░░░░]  future
MODERN THREAD RUNTIME    [░░░░░░░░░░]  future
```

The important interpretation is not "only 20 syscalls." The project has deliberately chosen high-leverage semantics, which is why the current system can already run an unchanged dynamic Alpine shell and execute the real Alpine package manager far earlier than a raw syscall count would suggest.

---

# Batch 13+ — measurement takes over

At this point the list stops being theoretical.

Run a deliberately diverse pressure suite:

```text
BusyBox
curl
apk
SQLite
Git
Python
Zig
Bun
browser-adjacent workload
```

Record every unsupported syscall they encounter.

For each missing syscall, track at least:

- number of independently blocked target paths needing it;
- whether it is fatal or merely degrades behavior;
- importance of the blocked targets;
- downstream software fanout;
- cross-workload reuse;
- what new blockers become visible when it is implemented.

Then calculate a score such as:

```text
unlock score =
    blocked target paths needing syscall
  × target importance
  × downstream software unlocked
  × cross-workload reuse
```

Implementation cost and semantic risk may be used as tie-breakers, but **not** as an excuse to implement the easiest seven instead of the most valuable seven.

Take the seven highest-scoring missing syscalls.

That becomes the next batch.

Then rerun the pressure suite and calculate again.

---

# The key idea

The ordering deliberately looks messy.

That is good.

A real maximum-leverage order can look like:

```text
mmap
openat
futex
socket
execve
epoll_ctl
renameat2
```

because real software does not care whether those operations belong in the same textbook chapter.

Minimus cares about **software unlocked per implemented primitive**.

---

# Desired progression

```text
7 syscalls
some real binaries survive

14
libc and ordinary programs become credible

21
many CLI programs initialize normally

28
network + processes arrive

35
internet + shell plumbing

42
richer Unix applications

49
async runtimes + servers

56
modern networking/event systems

63
package-manager filesystem behavior

70
real package installation approaches viability

77
modern threaded runtimes

84
developer/runtime ecosystem deepens
```

The exact unlock percentages must ultimately come from testing, not prediction.

---

# Official rule

There are no filesystem batches.

There are no networking batches.

There are no threading batches.

There are only:

> **the next seven most valuable missing syscalls.**

Every missing syscall competes against every other missing syscall for its place in the next seven.

And after each batch, **the ranking is recalculated from real software pressure rather than blindly continuing the original forecast.**
