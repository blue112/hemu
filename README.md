hemu
====

Haxe NES Emulator

**This emulator cannot run any game currently**

Currently mostly an complete 6502 CPU VM, with unofficial NES instruction added

TODO
====

PPU Support
-----------

PPU is currently absolutly not supported.
It will be handled in a future version.

How to compile
==============

To compile Hemu, you'll need the lastest 3.0 [Haxe](http://haxe.org/manual/haxe3) version and the 2.0.0 [Neko](http://haxe.org/manual/haxe3#build-neko) version.<br />
Create the folder bin with `mkdir bin`<br />
Then, just run `haxe make.hxml` will produce the out.n file in the bin/ folder.<br />
You can run test with `nes_test_diff.sh`, or run a random rom with `neko out.n random.rom`

Sample output
=============

![Sample output](http://i.imgur.com/XeW8unx.jpg)

From left to right :

* Current PC (Program Counter)
* Name of the OpCode
* Corresponding opcode byte
* Accumulator Value (AC)
* X Register Value (RX)
* Y Register Value (RY)
* Stack Pointer (SP)
* CPU Flags
** Carry Flag
** Zero Flag
** Interrupt Disable
** Decimal Mode
** Break Command
** Overflow Flag
** Negative Flag

Resources
=========

Here are some resources I used to better understand the CPU :
* http://wiki.nesdev.com
* http://www.llx.com/~nparker/a2/opcodes.html
* http://www.obelisk.demon.co.uk/6502/
* http://www.ffd2.com/fridge/docs/6502-NMOS.extra.opcodes
