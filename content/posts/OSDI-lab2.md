+++
title = "OSDI-lab2"
date = 2019-03-13

[taxonomies]
categories = ["Learning"]
tags = ["course", "os"]

[extra]
toc = true
+++

# OSDI lab II

## Objective
 - Learn how to build a customized BIOS and show some message on system startup.
 - Understand kernel booting flow and boot a ‘hello world’ program.
 - Learn how to use BIOS interrupt call to do I/O tasks.
 - Learn how to modify linux-0.11 bootsect.s and the build system to create a multiboot kernel image.

<!--more-->

---

## Lab2.1 - Build SEABIOS, add some message before system startup
```bash
git clone https://git.seabios.org/seabios.git seabios
cd seabios/
make menuconfig
make
```
Print message in `enable_vga_console` function in `src/bootsplash.c`.
```c
void
enable_vga_console(void)
{
    dprintf(1, "Turning on vga text mode console\n");
    struct bregs br; 

    /* Enable VGA text mode */
    memset(&br, 0, sizeof(br));
    br.ax = 0x0003;
    call16_int10(&br);
    
    printf("This is OSDI lab2.\n");
    // Write to screen.
    printf("SeaBIOS (version %s)\n", VERSION);
    display_uuid();
}
```
Use the qemu `-bios` option to load customized BIOS.
```bash
qemu-system-i386 -m 16M -boot a -fda Image -hda osdi.img -bios seabios/out/bios.bin
```
Because the customized BIOS is part of our lab, so I push it to new repo and add the **submodule** to `osdi`.
```bash
git submodule add bios-url bios-in-osdi-path
```
After that, I can update the customized BIOS even though we develop the BIOS and OSDI at different repo using the following command.
```bash
git submodule update bios-name
```

---

## Lab2.2 - Add image before system startup
We want to load the image when BIOS is loading.

Firstly, we want to find which function can help us to do that.
There is a function called `enable_bootsplash` @ `src/bootsplash.c`.
```c
void
enable_bootsplash(void)
{
    if (!CONFIG_BOOTSPLASH)
        return;
    /* splash picture can be bmp or jpeg file */
    dprintf(3, "Checking for bootsplash\n");
    u8 type = 0; /* 0 means jpg, 1 means bmp, default is 0=jpg */
    int filesize;
    u8 *filedata = romfile_loadfile("bootsplash.jpg", &filesize);
    if (!filedata) {
        filedata = romfile_loadfile("bootsplash.bmp", &filesize);
        if (!filedata)
            return;
        type = 1;
    }
    
    ...
}
```
This function will check the `CONFIG_BOOTSPLASH` and bootsplash image.

Secondly, we find that the `enable_bootsplash` will be called by `interactive_bootmenu` @ `src/boot.c`.
```c
// Show IPL option menu.
void
interactive_bootmenu(void)
{
    // XXX - show available drives?
    printf("CONFIG_BOOTMENU: %d\n", CONFIG_BOOTMENU);
    printf("show-boot-menu: %d\n", romfile_loadint("etc/show-boot-menu", 1));
    if (! CONFIG_BOOTMENU || !romfile_loadint("etc/show-boot-menu", 1))
        return;

    while (get_keystroke(0) >= 0)
        ;

    char *bootmsg = romfile_loadfile("etc/boot-menu-message", NULL);
    int menukey = romfile_loadint("etc/boot-menu-key", 1);
    printf("%s", bootmsg ?: "\nPress ESC for boot menu.\n\n");
    free(bootmsg);

    u32 menutime = romfile_loadint("etc/boot-menu-wait", DEFAULT_BOOTMENU_WAIT);
    printf("menutime: %d\n", menutime);
    enable_bootsplash();
    ...
```
It seems that it is the function to provide the boot menu (i.e, booting from which boot device).
This function will also check the `CONFIG_BOOTMENU` and the file `etc/show-boot-menu`.
If we print the config before the first if condition, we will find that 

![](/images/posts/OSDI-lab2/J0M7dAD.png)

Therefore, the `CONFIG_BOOTMENU` is 1 but `etc/show-boot-menu` is 0, so the `interactive_bootmenu` will return early without executing the rest of code including the `enable_bootsplash` method.

After did some [researches](https://github.com/qemu/qemu/blob/master/docs/specs/fw_cfg.txt), qemu provide an option `-fw_cfg` to provide some file as

- `-fw_cfg [name=]<item_name>,file=<path>`. or
- `-fw_cfg [name=]<item_name>,string=<string>`

So I revise the qemu command to
```bash
qemu-system-i386 -m 16M -boot a -fda Image -hda ../osdi.img -bios seabios/out/bios.bin -fw_cfg name=etc/show-boot-menu,string=1
```
After that, the result became

![ ](/images/posts/OSDI-lab2/v1dMZr5.png)

It did enter the rest of code and ready to execute boot menu, and because the `enable_bootsplash` will check the image before load it, and we provide the bootsplash image as following.
```bash
qemu-system-i386 -m 16M -boot a -fda Image -hda ../osdi.img -bios seabios/out/bios.bin -fw_cfg name=etc/show-boot-menu,string=1 -fw_cfg name=bootsplash.jpg,file=bootsplash.jpg
```
![ ](/images/posts/OSDI-lab2/hwRLd1Z.png)

It work!

My friends also found that another qemu option [`-boot`](https://manpages.debian.org/jessie/qemu-system-x86/qemu-system-x86_64.1.en.html) provide the same functionality.
```bash
qemu-system-i386 -m 16M -boot order=a,menu=on,splash=bootsplash.jpg  -fda Image -hda ../osdi.img -bios seabios/out/bios.bin
```
Which will be more clever and elegant!

## Lab2.3 - Boot the hello world program
In this time, we will revise the kernel image structure and boot the given `hello`.
We will revise the image from
![ ](/images/posts/OSDI-lab2/DjL3gC2.png)
to
![ ](/images/posts/OSDI-lab2/biwIcIa.png)

### Makefile
Of course we will revise the Makefile and build.sh.

Firstly, put the `hello.s` to `boot`, and revise the `boot/Makefile`
```
...

all: bootsect hello setup
...

hello: hello.s
	@$(AS) -o hello.o hello.s
	@$(LD) $(LDFLAGS) -o hello hello.o
	@objcopy -R .pdr -R .comment -R.note -S -O binary hello
...

clean:
	@rm -f bootsect bootsect.o setup setup.o head.o hello hello.o
```
Just add new rule for hello and remember to clean its object file when executing `make clean`.

Secondly, revise the `Makefile`

```
...
Image: boot/bootsect boot/hello boot/setup tools/system
	@cp -f tools/system system.tmp
	@strip system.tmp
	@objcopy -O binary -R .note -R .comment system.tmp tools/kernel
	@chmod +x tools/build.sh
	@tools/build.sh boot/bootsect boot/hello boot/setup tools/kernel Image $(ROOT_DEV)
	@rm system.tmp
	@rm tools/kernel -f
	@sync
...
```
Update the Image *prerequisites* and add hello to the `tools/build.sh `parameter.

Thirdly, revise the `tools/build.sh`.

```
#!/bin/bash
# build.sh -- a shell version of build.c for the new bootsect.s & setup.s
# author: falcon <wuzhangjin@gmail.com>
# update: 2008-10-10

bootsect=$1
hello=$2
setup=$3
system=$4
IMAGE=$5
root_dev=$6

# Set the biggest sys_size
# Changes from 0x20000 to 0x30000 by tigercn to avoid oversized code.
SYS_SIZE=$((0x3000*16))

# set the default "device" file for root image file
if [ -z "$root_dev" ]; then
	DEFAULT_MAJOR_ROOT=3
	DEFAULT_MINOR_ROOT=1
else
	DEFAULT_MAJOR_ROOT=${root_dev:0:2}
	DEFAULT_MINOR_ROOT=${root_dev:2:3}
fi

# Write bootsect (512 bytes, one sector) to stdout
[ ! -f "$bootsect" ] && echo "there is no bootsect binary file there" && exit -1
dd if=$bootsect bs=512 count=1 of=$IMAGE 2>&1 >/dev/null

# Write hello(512bytes, one sector) to stdout
[ ! -f "$hello" ] && echo "there is no hello binary file there" && exit -1
dd if=$hello seek=1 bs=512 count=1 of=$IMAGE 2>&1 >/dev/null

# Write setup(4 * 512bytes, four sectors) to stdout
[ ! -f "$setup" ] && echo "there is no setup binary file there" && exit -1
dd if=$setup seek=2 bs=512 count=4 of=$IMAGE 2>&1 >/dev/null

# Write system(< SYS_SIZE) to stdout
[ ! -f "$system" ] && echo "there is no system binary file there" && exit -1
system_size=`wc -c $system |cut -d" " -f1`
[ $system_size -gt $SYS_SIZE ] && echo "the system binary is too big" && exit -1
dd if=$system seek=6 bs=512 count=$((2888-1-1-4)) of=$IMAGE 2>&1 >/dev/null

# Set "device" for the root image file
echo -ne "\x$DEFAULT_MINOR_ROOT\x$DEFAULT_MAJOR_ROOT" | dd ibs=1 obs=1 count=2 seek=508 of=$IMAGE conv=notrunc  2>&1 >/dev/null
```
Remember that at the `Makefile`, we put the hello as the second parameter, and we also need to update the parameter index of rest.

Link the `hello` to `Image`, **order matter!**
We want to put the bootsect, hello, setup and system, so we must follow this order.

The hello contain 512 bytes and occupied 1 sector, that is the `bs` and `count` option for.

So far, we insert the hello to new image, and we are ready to boot it.

### How OS boot?
At `boot/bootsect.s`

```
	ljmp    $BOOTSEG, $_start
_start:
	mov	$BOOTSEG, %ax
	mov	%ax, %ds
	mov	$INITSEG, %ax
	mov	%ax, %es
	mov	$256, %cx
	sub	%si, %si
	sub	%di, %di
	rep
	movsw 
	ljmp	$INITSEG, $go
```
1. Long jump to `$BOOTSEG:$_start` when OS is loaded by BIOS.
2. Put `$BOOTSEG` to `%ds`, `$INITSEG` to `%es` and 256 to `%cx`.
3. Zero the `%si` and `%di`.
4. Repeat `movsw` until `%cx` is zero (i.e. copy itself to from `$BOOTSEG` to `$INITSEG`, total size is 512 bytes).

    Because the counter of `rep` will decrease by 1 after executed, so the `movw` will execute 256 times!

    `movw` will move one word (2 bytes in 16-bits CPU) from `%ds:%si` to `%es:%di`.

    First step:
    ```
    %ds = $BOOTSEG
    %si = 0
    %es = $INITSEG
    %di = 0

    # Copy from $BOOTSEG:0 to $INITSEG:0
    movw
    ```

    Second step:
    Because the `%si` and `%di` will increase by 2 (bytes, one word in 16-bits CPU) after done it. So
    ```
    %ds = $BOOTSEG
    %si = 2
    %es = $INITSEG
    %di = 2

    # Copy from $BOOTSEG:2 to $INITSEG:2
    movw
    ```

    After 256 times, the `$BOOTSEG:0` - `$BOOTSEG:256` will copy to  `$INITSEG:0` - `$INITSEG:256`. That's `bootsect` itself!

5. Long jump to `$INITSEG:$go`.

---

```
go:	mov	%cs, %ax 			# after long jump, %cs become $INITSEG
	mov	%ax, %ds
	mov	%ax, %es
# put stack at 0x9ff00.
	mov	%ax, %ss
	mov	$0xFF00, %sp		# arbitrary value >>512
```

1. Move `$INITSEG` to `%ds`, `%es` and `%ss`.
    After long jump, the `%cs` will store the last segment it jump, that is `$INITSEG`.
2. Put the top of stack `%sp` to a huge address.

---

```
# load the setup-sectors directly after the bootblock.
# Note that 'es' is already set up.
load_setup:
	mov	$0x0000, %dx		# drive 0, head 0
	mov	$0x0002, %cx		# sector 2, track 0
	mov	$0x0200, %bx		# address = 512, in INITSEG
	.equ    AX, 0x0200+SETUPLEN
	mov     $AX, %ax		# service 2, nr of sectors
	int	$0x13			# read it
	jnc	ok_load_setup		# ok - continue
	mov	$0x0000, %dx
	mov	$0x0000, %ax		# reset the diskette
	int	$0x13
	jmp	load_setup
```

1. In this time, we want to read drive 0 (floppy), from 0 cylinder, 0 track, from `2`'th sector and read `SETUPLEN` sectors, 0 head to memory based on address `$INITSEG:$0x0200`. (i.e. load the setup in memory)
2. If successfully read it, `%cf` will not be set, so that `jnc	ok_load_setup` will jump to `ok_load_setup`.
3. Otherwise, reset the disk and try again.

---

**Reference:**

#### [Drive table](https://en.wikipedia.org/wiki/INT_13H):
| Register value | Meaning  |
| -------- | -------- |
| DL = 00h     | 1st floppy disk ( "drive A:" )     |
| DL = 01h     | 2nd floppy disk ( "drive B:" )     |
| DL = 80h     | 1st hard disk     |
| DL = 81h	     | 2nd hard disk     |
| DL = e0h     | CD/DVD     |

---

#### INT 13h, AH = 02h: [Read Sectors From Drive](https://en.wikipedia.org/wiki/INT_13H)

**Parameter:**

| Register | Meaning  |
| -------- | -------- |
| AH     | 02h     |
| AL     | Sectors To Read Count     |
| CH     | Cylinder     |
| CL     | Sector     |
| DH     | Head     |
| DL     | Drive     |
| ES:BX     | Buffer Address Pointer     |

**Results:**

| Register | Meaning  |
| -------- | -------- |
| CF     | Set On Error, Clear If No Error     |
| AH     | Return Code     |
| AL     | Actual Sectors Read Count     |

---

#### INT 13h, AH = 00h: [Reset Disk System](https://en.wikipedia.org/wiki/INT_13H)

**Parameter:**

| Register | Meaning  |
| -------- | -------- |
| AH     | 00h     |
| DL     | Drive (bit 7 set means reset both hard and floppy disks)|

**Results:**

| Register | Meaning  |
| -------- | -------- |
| CF     | Set on error     |
| AH     | Return Code     |

---

We can imitate the procedure to...
```
	.equ HELLOLEN, 1		# nr of hello-sectors
	.equ HELLOSEG, 0x0100	# hello starts here
...

go:	mov	%cs, %ax 			# after long jump, %cs become $INITSEG
	mov	%ax, %ds
	mov	%ax, %es
# put stack at 0x9ff00.
	mov	%ax, %ss
	mov	$0xFF00, %sp		# arbitrary value >>512
    
# Lab 2
load_hello:
   mov	$0x0000, %dx		# drive 0, head 0
   mov	$0x0002, %cx		# sector 2, track 0
   mov $HELLOSEG, %ax		# segment
   mov %ax, %es
   mov	$0x0000, %bx		# offset, address = 0x0100
   .equ    AX, 0x0200+HELLOLEN
   mov     $AX, %ax			# service 2, nr of sectors
   int	$0x13				# read it
   jnc	ok_load_hello		# ok - continue
   mov	$0x0000, %dx
   mov	$0x0000, %ax		# reset the diskette
   int	$0x13
   jmp	load_hello

ok_load_hello:
   ljmp $HELLOSEG, $0 # Jump to hello

...
```

![ ](/images/posts/OSDI-lab2/ejJFhn5.png)

It works!

---

## Lab2.4 - Multiboot support
In this experiment, you need to implement a simple keyboard character reader that when user:

- Press ‘1’, it boots the linux-0.11 Image(just like lab1).

- Press ‘2’, it boots the hello world program.

```
go:	mov	%cs, %ax 			# after long jump, %cs become $INITSEG
	mov	%ax, %ds
	mov	%ax, %es
# put stack at 0x9ff00.
	mov	%ax, %ss
	mov	$0xFF00, %sp		# arbitrary value >>512
    
boot_menu:
   # Print some inane message
   mov	$0x03, %ah		# read cursor pos
   xor	%bh, %bh		# page number
   int	$0x10
   
   mov	$21, %cx		# string length
   mov	$0x000D, %bx		# page 0, attribute 7 (normal)
   #lea	option, %bp
   mov     $option, %bp		# point to message
   mov	$0x1301, %ax		# write string, move cursor
   int	$0x10

   mov $0x00, %ah
   int $0x16

   cmp $49, %al				# 1 ascii
   je load_setup
   cmp $50, %al				# 2 ascii
   je load_hello
   jmp boot_menu

   ...
 
msg1:
	.byte 13,10
	.ascii "Loading system ..."
	.byte 13,10,13,10

option:
	.byte 13,10
	.ascii "1) linux, 2) hello"
	.byte 13,10,13,10
```
1. We locate the cursor.
2. Print the string to show the boot option.
3. Read the keyboard
4. Goto `load_setup` if pressing 1, goto `load_hello` if pressing 2.
5. Otherwise, go to `boot_menu` again.

---

**Reference:**

#### INT 10h, AH = 03h: [Get cursor position and shape](https://en.wikipedia.org/wiki/INT_10H)

**Parameter:**

| Register | Meaning  |
| -------- | -------- |
| AH     | 03h     |
| BH     | Page Number|

**Results:**

| Register | Meaning  |
| -------- | -------- |
| AX = 0     |     |
| CH     | Start scan line     |
| CL     | End scan line     |
| DH     | Row     |
| DL     | Column     |

---

#### INT 10h, AH = 13h: [Write string](https://en.wikipedia.org/wiki/INT_10H)

**Parameter:**

| Register | Meaning  |
| -------- | -------- |
| AH     | 13h     |
| AL     | Write mode     |
| BH     | Page Number     |
| BL     | Color     |
| CX     | String length     |
| DH     | Row     |
| DL     | Column     |
| ES:EP     | Offset of string     |

---

#### INT 16h, AH = 00h: [Read keystroke](https://en.wikipedia.org/wiki/INT_16H)

**Parameter:**

| Register | Meaning  |
| -------- | -------- |
| AH     | 00h     |

**Results:**

| Register | Meaning  |
| -------- | -------- |
| AH     | Scan code of the key pressed down     |
| AL     | ASCII character of the button pressed     |

---

#### [BIOS color](https://en.wikipedia.org/wiki/BIOS_color_attributes):
| Hex | Color  |
| -------- | -------- |
|0|Black|
|1|Blue|
|2|Green|
|3|Cyan|
|4|Red|
|5|Magenta|
|6|Brown|
|7|Light Gray|
|8|Dark Gray|
|9|Light Blue|
|A|Light Green|
|B|Light Cyan|
|C|Light Red|
|D|Light Magenta|
|E|Yellow|
|F|White|

---

#### [ASCII](https://en.wikipedia.org/wiki/ASCII):
| Dec | Meaning  |
| -------- | -------- |
|10|Line feed (\n)|
|49|1|
|50|2|

---

```
load_setup:
	mov	$0x0000, %dx		# drive 0, head 0
	mov	$0x0003, %cx		# sector 3, track 0
	mov	$0x0200, %bx		# address = 512, in INITSEG
	.equ    AX, 0x0200+SETUPLEN
	mov     $AX, %ax		# service 2, nr of sectors
	int	$0x13			# read it
	jnc	ok_load_setup		# ok - continue
	mov	$0x0000, %dx
	mov	$0x0000, %ax		# reset the diskette
	int	$0x13
	jmp	load_setup
```
`load_hello` remain the same, but the setup is located at 3rd sector, so we revise the `%cl` to 0x03.

It seems that all work are done. However, after making and run it.

![](/images/posts/OSDI-lab2/KB682J1.png)

Hello runs pretty well.

After press 1, I want to load the setup, but the OS begin to reboot continuously.

It seems that we didn't run the `ljmp	$SETUPSEG, $0`.
Thus, we must continue to trace the rest of code.

```
ok_load_setup:

# Get disk drive parameters, specifically nr of sectors/track

	mov	$0x00, %dl
	mov	$0x0800, %ax		# AH=8 is get drive parameters
	int	$0x13
	mov	$0x00, %ch
	#seg cs
	mov	%cx, %cs:sectors+0	# %cs means sectors is in %cs
    ...
```

1. Get sectors of track.
2. Set `%ch` (`%cx[15:8]`) to `0x00`.
3. Because we boot from floppy (`%dl` = 0), and its maximum sectors per track will not exceed 256 (18 sectors per track normally), so `%cx[7:6]` will be `0`.
4. Move `%cx` to `sectors`.

---

**Reference:**
#### INT 13h, AH = 08h: [Read Drive Parameters](https://en.wikipedia.org/wiki/INT_13H)

**Parameter:**

| Register | Meaning  |
| -------- | -------- |
| AH     | 08h     |
| DL     | drive index     |
| ES:DI     | set to 0000h:0000h to work around some buggy BIOS   |

**Results:**

| Register | Meaning  |
| -------- | -------- |
| CF     | 	Set On Error, Clear If No Error     |
| AH     | Return Code     |
| DL     | number of hard disk drives     |
| DH     | logical last index of heads = number_of - 1 (because index starts with 0)|
| CX     | 	[7:6][15:8] logical last index of cylinders = number_of - 1 (because index starts with 0)<br>[5:0] logical last index of sectors per track = number_of (because index starts with 1)     |
| BL     | drive type (only AT/PS2 floppies)     |
| ES:DI     | pointer to drive parameter table (only for floppies) |

---

```
ok_load_setup:
   ...
	mov	$SYSSEG, %ax
	mov	%ax, %es		# segment of 0x010000
	call	read_it
	call	kill_motor
   ...
```

Put `$SYSSEG` in `%es`, and call read_it.

```
read_it:
	mov	%es, %ax
	test	$0x0fff, %ax
die:	jne 	die			# es must be at 64kB boundary
	xor 	%bx, %bx		# bx is starting address within segment
```

1. `TEST` `0x0fff` and `0x1000`. `TEST` is bitwise `AND` and result of `TEST` is `0`, `ZF` is set to `1`. [ref](https://en.wikipedia.org/wiki/TEST_(x86_instruction))
2. `JNE` will jump when `ZF` is `0`, so it will continue executing the next instruction. [ref](https://en.wikibooks.org/wiki/X86_Assembly/Control_Flow#Jump_Instructions)
3. Zero `%bx`

```
rp_read:
	mov 	%es, %ax
 	cmp 	$ENDSEG, %ax		# have we loaded all yet?
	jb	ok1_read
	ret
```

1. Put `%es` to `%ax` (`$SYSSEG`).
2. Compare `$ENGSEG`(`0x4000`) and `%ax` (`0x1000`).
3. In AT&T syntax, `%ax` will subtract `$ENGSEG`. Result is `0xD000`. `SF` and `CF` will be set. [ref](https://en.wikibooks.org/wiki/X86_Assembly/Control_Flow#Comparison_Instructions)
4. Because `jb` will jump when `CF` is 1, so jump to `ok1_read`. [ref](https://en.wikibooks.org/wiki/X86_Assembly/Control_Flow#Jump_Instructions)
5. Otherwise, return to last callee.

```
sread:	.word 1+ SETUPLEN	# sectors read of current track
...
ok1_read:
	#seg cs
	mov	%cs:sectors+0, %ax
	sub	sread, %ax
	mov	%ax, %cx
	shl	$9, %cx
	add	%bx, %cx
	jnc 	ok2_read
	je 	ok2_read
	xor 	%ax, %ax
	sub 	%bx, %ax
	shr 	$9, %ax
```

1. Move `sectors` to `%ax` and subtract `sread`. That is un-read sectors.
2. Calculate the total bytes of un-read sectors (512 bytes per sector)  to `%cx`
3. If not greater or eqaul to $2^{16}$ (maximum register capacity), goto `ok2_read`.
4. Otherwise, count the maximum sectors can read (`%ax`).

```
ok2_read:
	call 	read_track

...

read_track:
	push	%ax
	push	%bx
	push	%cx
	push	%dx
	mov	track, %dx
	mov	sread, %cx
	inc	%cx
	mov	%dl, %ch
	mov	head, %dx
	mov	%dl, %dh
	mov	$0, %dl
	and	$0x0100, %dx
	mov	$2, %ah
	int	$0x13
	jc	bad_rt
	pop	%dx
	pop	%cx
	pop	%bx
	pop	%ax
	ret
```

1. Store all register.
2. In this time, we want to read drive 0 (floppy), from 0 cylinder, 0 track, from `1+SETUPLEN+1`'th sector and read `%al` un-read sectors, 0 head to memory based on address `$SYSSEG:0x0000`. (i.e. load the system in memory)
3. If failed, `%cf` will be set, so that `jc	bad_rt` will jump to `bad_rt`.
4. Load all registers.

At this very moment, we have already known the error may come from here. Because the system is located at `1 + 1 + 1 + SETUPLEN`, so we **must** change `sread` to `1 + 1 + SETUPLEN`.

---

**Reference:**

#### INT 13h, AH = 02h: [Read Sectors From Drive](https://en.wikipedia.org/wiki/INT_13H)

**Parameter:**

| Register | Meaning  |
| -------- | -------- |
| AH     | 02h     |
| AL     | Sectors To Read Count     |
| CH     | Cylinder     |
| CL     | Sector     |
| DH     | Head     |
| DL     | Drive     |
| ES:BX     | Buffer Address Pointer     |

**Results:**

| Register | Meaning  |
| -------- | -------- |
| CF     | Set On Error, Clear If No Error     |
| AH     | Return Code     |
| AL     | Actual Sectors Read Count     |

---

After change `sread` to ` 1 + 1 + SETUP`, it works!

![ ](/images/posts/OSDI-lab2/WGZwVkx.png)

---

## Questions

1. What’s the meaning of ljmp $BOOTSEG, $_start(boot/bootsect.s)? What is the memory address of the beginning of bootsect.s? What is the value of $_start? From above questions, could you please clearly explain how do you jump to the beginning of hello image?
   ```
      objdump -D -mi386 -Maddr16,data16 boot/bootsect.o
   ```
     
    ![ ](/images/posts/OSDI-lab2/lDWVVAr.png)


2. What’s the purpose of es register when the cpu is performing int $0x13 with AH=0x2h?

   - base segment of memory address that put read sectors 

3. Please change the Hello program’s font color to another

   - Change `%bl` register.
   
4. If we would like to swap the position of hello and setup in the Image. Where do we need to modify in tools/build.sh and bootsect.s?

   - The order of Image at `tools/build.sh`
   - The starting sector want to read when perform int 13h with AH=02h.

5. Please trace the SeaBIOS code. What are the first and the last instruction of the SeaBIOS? Where are they?

   - First instruction: `reset_vector` @ `src/romlayout.S`
   - Last instruction:
      - `call_boot_entry` @ `src/boot.c` in C
      - `__farcall16` @ `src/romlayout.S` in asm
