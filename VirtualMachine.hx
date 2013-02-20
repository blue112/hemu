import Decode6502.AddressingMode;
import Decode6502.Command;
import Decode6502.OPCode;

using StringTools;

class VirtualMachine
{
	var pc:Int; //Program counter (16b)
	var sp:Int; //Stack pointer (8b)
	var accumulator:Int; //8 bit
	var x:Int; //Register x
	var y:Int; //Register y

	//PROCESS FLAGS

	var cf:Bool; //Carry flag
	var zf:Bool; //Zero flag
	var id:Bool; //Interrupt Disable
	var dm:Bool; //Decimal Mode
	var bc:Bool; //Break Command
	var of:Bool; //Overflow Flag
	var nf:Bool; //Negative Flag

	var memory:IntHash<Int>;

	var decoder:Decode6502;

	private function new(decoder:Decode6502)
	{
		pc = 0; //?
		sp = 0; //??
		accumulator = 0;
		x = 0;
		y = 0;

		cf = false;
		zf = false;
		id = false;
		dm = false;
		bc = false;
		of = false;
		nf = false;

		memory = new IntHash();
		for (i in 0...0xFFFF)
			memory.set(i, 0);

		this.decoder = decoder;

		run();
	}

	private function run()
	{
		var op;
		do
		{
			op = decoder.getOP(pc);
			pc++;

			var value:Null<Int> = null;

			trace("Execute "+op.code);

			switch (op.code)
			{
				case STA: //Store Accumulator
					var ad = getAddress(op.addressing);
					memory.set(ad, accumulator);

				case STX:
					var ad = getAddress(op.addressing);
					memory.set(ad, x);

				case STY:
					var ad = getAddress(op.addressing);
					memory.set(ad, y);

				case SEI, CLI:
					id = op.code == SEI;

				case SED, CLD:
					dm = op.code == SED;

				case SEC, CLC:
					cf = op.code == SEC;

				case SBC:
					var ad = getAddress(op.addressing);
					var v = getValue(op.addressing, ad);
					accumulator = accumulator - v - (cf ? 0 : 1);
					if (accumulator > 0xFF)
					{
						cf = false;
						accumulator &= 0xFF;
					}
					value = accumulator;

				case LDA:
					var ad = getAddress(op.addressing);
					accumulator = getValue(op.addressing, ad);

					zf = accumulator == 0;
					nf = accumulator & 0x80 == 0x80;

				case LDX:
					var ad = getAddress(op.addressing);
					x = getValue(op.addressing, ad);

					zf = x == 0;
					nf = x & 0x80 == 0x80;

				case LDY:
					var ad = getAddress(op.addressing);
					y = getValue(op.addressing, ad);

					zf = y == 0;
					nf = y & 0x80 == 0x80;

				case INC:
					var ad = getAddress(op.addressing);
					value = memory.get(ad) + 1;
					memory.set(ad, value);

				case INX:
					var value = x++;

				case INY:
					value = y++;

				case DEC:
					var ad = getAddress(op.addressing);
					value = memory.get(ad) - 1;
					memory.set(ad, value);

				case TAX:
					x = value = accumulator;

				case TXA:
					accumulator = value = x;

				case TSX:
					x = value = sp;

				case TAY:
					y = value = accumulator;

				case TXS:
					sp = x;

				case TYA:
					sp = value = x;

				case NOP:
					continue; //No need to retrace instructions

				case BRK:
					break;

				default:
					trace("INSTRUCTION NOT IMPLEMENTED: "+op.code);
			}

			if (value != null)
			{
				zf = value == 0;
				nf = value & 0x80 == 0x80;
			}

			trace(dump_machine_state());
		}
		while (op != null);
	}

	private function getValue(add:AddressingMode, address:Int):Int
	{
		switch (add)
		{
			case IMMEDIATE:
				return address & 0xFF;
			default:
				return memory.get(address);
		}
	}

	private function getAddress(add:AddressingMode):Int
	{
		var address = 0;

		switch (add)
		{
			case ZERO_PAGE:
				address = decoder.getByte(pc);
				pc++;
			case IMMEDIATE:
				address = decoder.getByte(pc);
				pc++;
			default:
				trace("ADDRESSING MODE NOT IMPLEMENTED "+add);
		}

		return address;
	}

	private function dump_machine_state()
	{
		var out = "== MACHINE STATE =="+"\n";
		out += "PC => "+pc.hex(2)+"\n";
		out += "SP => "+sp.hex(2)+"\n";
		out += "AC => "+accumulator.hex(2)+"\n";
		out += "RX => "+x.hex(2)+"\n";
		out += "RY => "+y.hex(2)+"\n";
		out += "\n";
		out += "CF ZF ID DM"+"\n";
		out += (cf ? " 1" : " 0")+" "+(zf ? " 1" : " 0")+" "+(id ? " 1" : " 0")+" "+(dm ? " 1" : " 0")+"\n";
		out += "BC OF NF"+"\n";
		out += (bc ? " 1" : " 0")+" "+(of ? " 1" : " 0")+" "+(nf ? " 1" : " 0")+"\n";

		return out;
	}

	static public function main()
	{
		var d = new Decode6502(sys.io.File.getBytes("test.rom"));
		var vm = new VirtualMachine(d);
	}
}
