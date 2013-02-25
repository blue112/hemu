import haxe.io.Bytes;
import haxe.io.Input;

using TerminalFormatter;

enum OPCode //http://www.obelisk.demon.co.uk/6502/reference.html
{
    ORA; //Logical Inclusive OR
    AND; //Logical and
    EOR; //Exclusive or (^)
    ADC; //Add with Carry (?)
    STA; //Store accumulator (save it)
    LDA; //Load accumulator (load it)
    CMP; //Compare
    SBC; //Subtract with Carry

    ASL; //Arithmetic Shift Left
    ROL; //Rotate left
    LSR; //Logical shift right
    ROR; //Rotate right
    STX; //Store X (save it)
    LDX; //Load X (load it)
    DEC; //Decrement memory
    INC; //Increment memory

    BIT; //Bit test
    JMP; //Jump
    JMA; //Jump absolute
    STY; //Store Y (save it)
    LDY; //Load Y (load it)
    CPY; //Compare Y
    CPX; //Compare X


    BCC; //Branch if Carry Clear
    BCS; //Branch if Carry Set
    BEQ; //Branch if Equal
    BMI; //Branch if Minus
    BNE; //Branch if Not Equal
    BPL; //Branch if Positive
    BVC; //Branch if Overflow Clear
    BVS; //Branch if Overflow Set

    BRK; //Force Interrupt
    CLC; //Clear Carry Flag
    CLD; //Clear Decimal Mode
    CLI; //Clear Interrupt Disable
    CLV; //Clear Overflow Flag
    DEX; //Decrement X Register
    DEY; //Decrement Y Register
    INX; //Increment X Register
    INY; //Increment Y Register
    JSR; //Jump to Subroutine
    NOP(ignore:Int); //No Operation
    PHA; //Push Accumulator
    PHP; //Push Processor Status
    PLA; //Pull Accumulator
    PLP; //Pull Processor Status
    RTI; //Return From Interrupt
    RTS; //Return From Subroutine
    SEC; //Set Carry Flag
    SED; //Set Decimal Flag
    SEI; //Set interrupt disabled
    TAX; //Transfer Accumulator to X
    TAY; //Transfer Accumulator to Y
    TSX; //Transfer Stack Pointer to X
    TSY; //Transfer Stack Pointer to Y
    TYA; //Transfer Y to Accumulator
    TXS; //Transfer X to Stack Pointer
    TXA; //Transfer X to Stack Pointer
}

enum AddressingMode //http://www.obelisk.demon.co.uk/6502/addressing.html
{
    IMMEDIATE; //Direct value (constant)
    ZERO_PAGE; //From 0 to FF addresses (8b)
    ACCUMULATOR;  // ==> The accumulator is where calculation are made
    ABSOLUTE; //Direct address (16b)
    ZERO_PAGE_Y; //Like Zero_page but +Y (8b)
    ZERO_PAGE_Y_2; // (zero_page),Y
    ZERO_PAGE_X;   // zero_page,X //Like Zero_page but +X (8b)
    ZERO_PAGE_X_2; // (zero_page,X)
    ABSOLUTE_X; //Like absolute but +X (16b)
    ABSOLUTE_Y; //Like absolute but +Y (16b)


    RELATIVE; //Move pointer (8b signed)
    INDIRECT; //Only for jmp => Read 16b from address (16b) and jump thered
    INDIRECT_INDEXED; //Wat
    INDEXED_INDIRECT; //Wat
}

typedef Command =
{
    var code:OPCode;
    var addressing:AddressingMode;
}

class Decode6502
{
    var s:Bytes;
    var offset:Int;

    static public function main()
    {

    }

    public function new(file:Bytes, offset:Int)
    {
        this.s = file;
        this.offset = offset;

        parseHeader();
    }

    private function parseHeader():Void
    {
        var f6 = s.get(6);
        var f7 = s.get(7);

        var mapper = (f6 & 0xF0 >> 4) + f7 & 0xF0;
        //trace(mapper);
    }

    public function getByte(address:Int):Int
    {
        return s.get(address + offset);
    }

    public function getOP(address:Int):Command
    {
        return decodeByte(getByte(address));
    }

    public function decodeByte(byte:Int):Command
    {
        var opCode:OPCode = null;
        var addressing:AddressingMode = ABSOLUTE;

        var aaa = (byte & 0xE0) >> 5; //First 3 bits
        var bbb = (byte & 0x1C) >> 2; //Middle 3 bits
        var cc = byte & 0x3; //Last two bits

        if (byte == 0) opCode = BRK;
        else if (byte == 0x20) opCode = JSR;
        else if (byte == 0x40) opCode = RTI;
        else if (byte == 0x60) opCode = RTS;
        else if (byte == 0x8A) opCode = TXA;
        else if (byte == 0x9A) opCode = TXS;
        else if (byte == 0xAA) opCode = TAX;
        else if (byte == 0xBA) opCode = TSX;
        else if (byte == 0xCA) opCode = DEX;
        else if (byte == 0xEA) opCode = NOP(0);
        else if (
            byte == 0x1A ||
            byte == 0x3A ||
            byte == 0x5A ||
            byte == 0x7A ||
            byte == 0xDA ||
            byte == 0xFA)
                opCode = NOP(0);
        else if (
            byte == 0x04 ||
            byte == 0x14 ||
            byte == 0x34 ||
            byte == 0x44 ||
            byte == 0x54 ||
            byte == 0x64 ||
            byte == 0x74 ||
            byte == 0xD4 ||
            byte == 0xF4 ||
            byte == 0x80)
                opCode = NOP(1);
        else if (
            byte == 0x0C ||
            byte == 0x1C ||
            byte == 0x3C ||
            byte == 0x5C ||
            byte == 0x7C ||
            byte == 0xDC ||
            byte == 0xFC)
                opCode = NOP(2);
        else if (byte & 0xF == 0x8)
        {
            var opcodeTable = [PHP, CLC, PLP, SEC, PHA, CLI, PLA, SEI, DEY, TYA, TAY, CLV, INY, CLD, INX, SED];
            opCode = opcodeTable[byte >> 4];
        }
        else if (cc == 0)
        {
            if (bbb == 0x4) //Branches
            {
                var branchTable = [BPL, BMI, BVC, BVS, BCC, BCS, BNE, BEQ];
                opCode = branchTable[aaa];
                addressing = RELATIVE;
            }
            else
            {
                var opcodeTable = [null, BIT, JMP, JMA, STY, LDY, CPY, CPX];
                opCode = opcodeTable[aaa];

                var addressingTable = [IMMEDIATE, ZERO_PAGE, null, ABSOLUTE, null, ZERO_PAGE_X, null, ABSOLUTE_X];
                addressing = addressingTable[bbb];
            }
        }
        else if (cc == 1)
        {
            var opcodeTable = [ORA, AND, EOR, ADC, STA, LDA, CMP, SBC];
            opCode = opcodeTable[aaa];

            var addressingTable = [ZERO_PAGE_X_2, ZERO_PAGE, IMMEDIATE, ABSOLUTE, ZERO_PAGE_Y_2, ZERO_PAGE_X, ABSOLUTE_Y, ABSOLUTE_X];
            addressing = addressingTable[bbb];
        }
        else if (cc == 2)
        {
            var opcodeTable = [ASL, ROL, LSR, ROR, STX, LDX, DEC, INC];
            opCode = opcodeTable[aaa];

            var addressingTable = [IMMEDIATE, ZERO_PAGE, ACCUMULATOR, ABSOLUTE, null, ZERO_PAGE_X, null, ABSOLUTE_X];
            addressing = addressingTable[bbb];

            if ((opCode == STX || opCode == LDX) && addressing == ZERO_PAGE_X)
            {
                addressing = ZERO_PAGE_Y;
            }
            else if (opCode == LDX && addressing == ABSOLUTE_X)
            {
                addressing = ABSOLUTE_Y;
            }
        }

        return {code:opCode, addressing:addressing};
    }
}
