import Decode6502.OPCodes;
import haxe.io.Input;

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
    JMP_ABS; //Jump absolute
    STY; //Store Y (save it)
    LDY; //Load Y (load it)
    CPY; //Compare Y
    CPX; //Compare X


    BBC; //Branch if Carry Clear
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
    NOP; //No Operation
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
}

enum AdressingMode //http://www.obelisk.demon.co.uk/6502/addressing.html
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
    INDIRECT; //Only for jmp => Read 16b from address (16b) and jump there
    INDIRECT_INDEXED; //Wat
    INDEXED_INDIRECT; //Wat
}

class Decode6502
{
    var s:Input;

    static public function main()
    {

    }

    public function new(file:Input)
    {
        this.s = file;

        var data_available = true;
        while (data_available)
        {
            try
            {
                var b = s.readByte();
                decodeByte(b);
            }
            catch (e:haxe.io.Eof)
            {
                data_available = false;
            }
        }

        trace("File finished");
    }

    private function decodeByte(byte:Int)
    {
        var opCode:OPCode;
        var adressing:AdressingMode;

        var aaa = (byte & 0xE0) >> 5; //First 3 bytes
        var bbb = (byte & 0x1C) >> 2; //Middle 3 bits
        var cc = byte & 0x3; //Last two bytes

        if (cc == 0)
        {
            if (bbb == 0x4) //Branches
            {
                var branchTable = [BPL, BMI, BVC, BVS, BCC, BCS, BNE, BEQ];
            }

            var opcodeTable = [null, BIT, JMP, JMP_ABS, STY, LDY, CPY, CPX];
            opCode = opcodeTable[aaa];

            var adressingTable = [IMMEDIATE, ZERO_PAGE, null, ABSOLUTE, null, ZERO_PAGE_X, null, ABSOLUTE_X];
            adressing = adressingTable[bbb];
        }
        else if (cc == 1)
        {
            var opcodeTable = [ORA, AND, EOR, ADC, STA, LDA, CMP, SBC];
            opCode = opcodeTable[aaa];

            var adressingTable = [ZERO_PAGE_X_2, ZERO_PAGE, IMMEDIATE, ABSOLUTE, ZERO_PAGE_Y_2, ZERO_PAGE, ABSOLUTE_Y, ABSOLUTE_X];
            adressing = adressingTable[bbb];
        }
        else if (cc == 2)
        {
            var opcodeTable = [ASL, ROL, LSR, ROR, STX, LDX, DEC, INC];
            opCode = opcodeTable[aaa];

            //TODO : Decode BBB
        }
    }
}
