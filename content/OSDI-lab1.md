+++
title = "OSDI-lab1"
date = 2019-03-25

[taxonomies]
categories = ["Learning"]
tags = ["course", "os"]

[extra]
toc = true
+++

# OSDI lab I

## Objective

- Understand version control system and makefile project
- Learn how to use QEMU and GDB to debug Linux 0.11 kernel
- Learn how to commit to GIT system

<!--more-->

---

## Lab1.1 Linux 0.11 Development Environment Setup

### Fix syntax error of `Makefile`

From [Rule Syntax](https://www.gnu.org/software/make/manual/html_node/Rule-Syntax.html#Rule-Syntax):
> the *recipe* must start with a tab character


```cmake
...

.c.s:
	@$(CC) $(CFLAGS) -S -o $*.s $<
.s.o:
	@$(AS)  -o $*.o $<
.c.o:
	@$(CC) $(CFLAGS) -c -o $*.o $<

...
```

### Give execute permission to `tools/build.sh`

```bash
chmod +x tools/build.sh
```

### Change GCC version to 4.8

```cmake
# This file is the Makefile Header for every sub Makefile, which designed to
# simplfy the porting and maintaining operation
# author: falcon <wuzhangjin@gmail.com>
# update: 2008-10-29

AS	= as --32
LD	= ld
#LDFLAGS = -m elf_i386 -x 
LDFLAGS = -m elf_i386
CC	= gcc-4.8
CFLAGS  = -g -m32 -fno-builtin -fno-stack-protector -fomit-frame-pointer -fstrength-reduce #-Wall

CPP	= cpp-4.8 -nostdinc
AR	= ar

# we should use -fno-stack-protector with gcc 4.3
gcc_version=$(shell ls -l `which $(CC)` | tr '-' '\n' | tail -1)
```

### Compile and install newest QEMU

On Ubuntu 18.04
#### Setup the dependencies
```bash
sudo apt-get install checkinstall
sudo apt-get install python
sudo apt-get install build-essential zlib1g-dev pkg-config libglib2.0-dev binutils-dev libboost-all-dev autoconf libtool libssl-dev libpixman-1-dev libpython-dev python-pip python-capstone virtualenv
sudo apt-get install flex bison g++-4.8
```
[ref](https://github.com/Cisco-Talos/pyrebox/issues/41)

#### Start to install qemu
```bash
git clone https://git.qemu.org/git/qemu.git
cd qemu
git submodule init
git submodule update --recursive
./configure
make
sudo checkinstall make install
```
[ref](https://www.qemu.org/download/#source)

Validate the version must be larger than 2.5.x

### Run the Linux 0.11

```bash
qemu-system-i386 -m 16M -boot a -fda Image -hda ../osdi.img
```

![](https://i.imgur.com/xD0vffk.png)

## Lab 1-2 Debug kernel

### Look the problem of `panic`
The kernel stuck on the `panic("")` at `init/maic.c`.

Look at `kernel/panic.c`.

```c
/*
 *  linux/kernel/panic.c
 *
 *  (C) 1991  Linus Torvalds
 */

/*
 * This function is used through-out the kernel (includeinh mm and fs)
 * to indicate a major problem.
 */
#define PANIC

#include <linux/kernel.h>
#include <linux/sched.h>

void sys_sync(void);	/* it's really int */

void panic(const char * s)
{
	printk("Kernel panic: %s\n\r",s);
	if (current == task[0])
		printk("In swapper task - not syncing\n\r");
	else
		sys_sync();
	for(;;);
}

```

Due to the description of `panic`, it may not suitable to put `panic` at `init/main.c`.

```c
void main(void){
...
	mem_init(main_memory_start,memory_end);
	trap_init();
	blk_dev_init();
	chr_dev_init();
	tty_init();
	time_init();
	sched_init();
	buffer_init(buffer_memory_end);
	hd_init();
	floppy_init();
	sti();
	// panic(""); 
	move_to_user_mode();
	if (!fork()) {		/* we count on this going ok */
		init();
	}
...
}
```

Uncomment it and try it.

![](https://i.imgur.com/T1mKZna.png)

Here it is, fix next bug.

### Look the problem of `out of memory`

![](https://i.imgur.com/JIRQ5YR.png)

Actually, there are several warnings relating to `task` at `sched.c`.

```c
struct task_struct * task[NR_TASKS] = {&(init_task.task), };
```

`task` has at leat one `task_struct`, checkout the `NR_TASKS`.

```c
#define NR_TASKS 0
```

The value of `NR_TASKS` is zero, which is unreasonable.

Check out [document](https://download.oldlinux.org/ECLK-5.0-WithCover.pdf) at P994.

![](https://i.imgur.com/4mAhfLo.png)

Therefore, change 0 to 64, and try it.

![](https://i.imgur.com/fbap7SK.png)

Fortunately, no error happened!

![](https://i.imgur.com/cmQyHsq.png)

Work perfectly!

### Print your student id

We need to print out the student ID before shell startup, so look at `main.c`.

```c
...
	printf("%d buffers = %d bytes buffer space\n\r",NR_BUFFERS,
		NR_BUFFERS*BLOCK_SIZE);
	printf("Free mem: %d bytes\n\r",memory_end-main_memory_start);
	if (!(pid=fork())) {
		close(0);
		if (open("/etc/rc",O_RDONLY,0))
			_exit(1);
		execve("/bin/sh",argv_rc,envp_rc);
		_exit(2);
	}
	if (pid>0)
		while (pid != wait(&i))
			/* nothing */;
	while (1) {
		if ((pid=fork())<0) {
			printf("Fork failed in init\r\n");
			continue;
		}
		if (!pid) {
			close(0);close(1);close(2);
			setsid();
			(void) open("/dev/tty0",O_RDWR,0);
			(void) dup(0);
			(void) dup(0);
			_exit(execve("/bin/sh",argv,envp));
		}
        ...
...
```

There are two shell startup, if we print out the student ID before first shell.

![](https://i.imgur.com/HK9suMP.png)

The OK message will print before student ID.

So print student ID before second shell.

![](https://i.imgur.com/OM2s8Ca.png)

Work great! All done!!!

## Questions

Q1: QEMU

```
qemu-system-i386 -m 16M -boot a -fda Image -hda ../osdi.img -s -S -serial stdio
```
According to the above command:
Q1.1: What’s the difference between -S and -s in the command?

   > According to [man](https://manned.org/qemu-system-i386/eeff8ce3) page of `qemu-system-i386`:
   > `-s`: Wait gdb connection to port 1234.
   > `-S`: Do not start CPU at startup (you must type 'c' in the monitor).
 
Q1.2: What are -boot, -fda and -hda used for? If I want to boot with ../osdi.img(supposed it’s a bootable image) what should I do?

   > `-boot a`: Boot from floppy.
   > `-fda Image`: Use `Image` as floppy.
   > `-hda ../osdi.img`: Use `../osdi.img` as hard disk.
   > `-boot c -hda ../osdi.img`.
 
 Q2: Git
 
 Q2.1: Please explain all the flags and options used in below command:

```
git checkout -b lab1 origin/lab1
```

   > There is a remote repo called `origin` and has a branch named `lab1`, we want to create a local branch called `lab1` attach on it and move the `HEAD` on it.

Q2.2 What are the differences among git add, git commit, and git push? What’s the timing you will use them?

   > There are three `working directory`, `stagin area` and `repository`. When you `add` something, you move these into from `working direcotory` to `staging area`, and when you `commit` it, you move to `repository`. At last, when you `push` it, you push your code from `local repo` to `remote repo`.

Q3: Makefile

Q3.1: What happened when you run the below command? Please explain it according to the Makefile.

```
make clean && make
```

   > According to `Makefile`, `make clean` will remove all object file, image etc. `make` will follow the instruction on `Makefile` and build it.


Q3.2: I did edit the include/linux/sched.h file and run make command successfully but the Image file remains the same. However, if I edit the init/main.c file and run make command. My Image will be recompile. What’s the difference between these two operations?

   > The `Makefile` didn't write carefully, you should execute `make clean && make` to rebuild.

Q4: After making, what does the kernel Image ‘Image’ look like?

   > According to `build.sh`, `bootsect` will put first and `setup` will be the second. Finally, the `system` will be at last.
```bash
# Write bootsect (512 bytes, one sector) to stdout
[ ! -f "$bootsect" ] && echo "there is no bootsect binary file there" && exit -1
dd if=$bootsect bs=512 count=1 of=$IMAGE 2>&1 >/dev/null

# Write setup(4 * 512bytes, four sectors) to stdout
[ ! -f "$setup" ] && echo "there is no setup binary file there" && exit -1
dd if=$setup seek=1 bs=512 count=4 of=$IMAGE 2>&1 >/dev/null

# Write system(< SYS_SIZE) to stdout
[ ! -f "$system" ] && echo "there is no system binary file there" && exit -1
system_size=`wc -c $system |cut -d" " -f1`
[ $system_size -gt $SYS_SIZE ] && echo "the system binary is too big" && exit -1
dd if=$system seek=5 bs=512 count=$((2888-1-4)) of=$IMAGE 2>&1 >/dev/null
```