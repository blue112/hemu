hemu
====

Haxe NES Emulator

**This emulator cannot run any game currently**

Currently mostly an incomplete 6502 CPU VM

TODO
====

Not supported special instructions
--------------------------

* SLO (03, 07, 0F, 13, 17, 1B, 1F)
* RLA (23, 27, 2F, 33, 37, 3B, 3F)
* SRE (43, 47, 4F, 53, 57, 5B, 5F)
* RRA (63, 67, 6F, 73, 77, 7B, 7F)
* SAX (83, 87, 8F, 97)
* LAX (A3, A7, AF, B3, B7, BF)
* DCP (C3, C7, CF, D3, D7, DB, DF)
* ISB (E3, E7, EF, F3, F7, FB, FF)
* SBC (EB)

PPU Support
-----------

PPU is currently absolutly not supported.
It will be handled in a future version.

How to compile
==============

To compile Hemu, you'll need the lastest 3.0 [Haxe](http://haxe.org/manual/haxe3) version and the 1.8.2 [Neko](http://nekovm.org/) version.<br />
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
