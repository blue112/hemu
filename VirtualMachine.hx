import Decode6502.AddressingMode;
import Decode6502.Command;
import Decode6502.OPCode;

using StringTools;
using TerminalFormatter;

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
	var stack:Array<Int>;

	var decoder:Decode6502;

	private function new(decoder:Decode6502, ?startPoint:Int = 0x10)
	{
		pc = 0;
		sp = 0xFD;
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
		for (i in 0...0x07FF)
			memory.set(i, 0xFF);

		this.decoder = decoder;

		pc = startPoint;
		run();
	}

	private function pullStack():Int
	{
		sp++;
		var value = memory.get(0x100 + sp);

		return value;
	}

	private function pushStack(value:Int):Void
	{
		memory.set(0x100 + sp, value);
		sp--;
	}

	private function run()
	{
		var op;
		do
		{
			op = decoder.getOP(pc);
			pc++;

			var value:Null<Int> = null;

			Sys.print("\nExecute \033[1;33m"+op.code+"\033[0m");

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

				case BIT:
					var ad = getAddress(op.addressing);
					var v = getValue(op.addressing, ad);
					zf = accumulator == v;
					of = v & 0x40 != 0;
					nf = v & 0x80 != 0;

				case SBC:
					var ad = getAddress(op.addressing);
					var v = getValue(op.addressing, ad);
					accumulator = accumulator - v - (cf ? 0 : 1);
					if (accumulator > 0xFF)
					{
						cf = false;
						accumulator &= 0xFF;
					}

					//Overflow flag ??

					value = accumulator;

				case CMP, CPY, CPX:
					var ad = getAddress(op.addressing);
					var v = getValue(op.addressing, ad);

					var compare_to = switch (op.code)
					{
						case CMP: accumulator;
						case CPX: x;
						default: y;
					}

					cf = compare_to >= v;
					zf = compare_to == v;
					nf = false; //?

				case ADC:
					var ad = getAddress(op.addressing);
					var v = getValue(op.addressing, ad);
					accumulator = accumulator + v + (cf ? 1 : 0);
					if (accumulator > 0xFF)
					{
						cf = true;
						accumulator &= 0xFF;
					}

					//Overflow flag ??

					value = accumulator;

				case JSR:
					var ad = getAddress(op.addressing);
					pushStack(pc & 0xFF);
					pushStack(pc >> 8);

					pc = ad;

				case RTS:
					var to = pullStack() << 8;
					to += pullStack();
					pc = to;

				case AND:
					var ad = getAddress(op.addressing);
					var v = getValue(op.addressing, ad);

					accumulator &= v;
					value = accumulator;

				case ASL:
					var ad = getAddress(op.addressing);
					var v = getValue(op.addressing, ad);

					cf = v & 0x80 != 0;
					value = (v << 1) & 0xFF;

					if (op.addressing == ACCUMULATOR)
					{
						accumulator = value;
					}
					else
					{
						memory.set(ad, value);
					}

				case LSR:
					var ad = getAddress(op.addressing);
					var v = getValue(op.addressing, ad);
					cf = v & 1 != 0;
					value = v >> 1;

					if (op.addressing == ACCUMULATOR)
					{
						accumulator = value;
					}
					else
					{
						memory.set(ad, value);
					}

				case ROL:
					var ad = getAddress(op.addressing);
					var v = getValue(op.addressing, ad);
					var new_cf = v & 0x80 != 0;
					value = (v << 1) & 0xFF;
					value += cf ? 1 : 0;

					cf = new_cf;
					if (op.addressing == ACCUMULATOR)
					{
						accumulator = value;
					}
					else
					{
						memory.set(ad, value);
					}

				case ROR:
					var ad = getAddress(op.addressing);
					var v = getValue(op.addressing, ad);
					var new_cf = v & 1 != 0;
					value = (v >> 1) & 0xFF;
					value += cf ? 0x80 : 0;

					cf = new_cf;
					if (op.addressing == ACCUMULATOR)
					{
						accumulator = value;
					}
					else
					{
						memory.set(ad, value);
					}

				case BCC, BCS, BEQ, BMI, BNE, BPL, BVC, BVS:
					var to_check = switch (op.code)
					{
						case BCC, BCS:
							cf;
						case BEQ, BNE:
							zf;
						case BMI, BPL:
							nf;
						case BVC, BVS:
							of;
						default: false;
					}

					var check_against = switch (op.code)
					{
						case BCS, BEQ, BMI, BVS:
							true;
						default:
							false;
					}

					var jump_to = getAddress(op.addressing);

					if (to_check == check_against)
						pc = jump_to;

				case JMP:
					var ad = getAddress(op.addressing);
					pc = ad;

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

				case EOR:
					var ad = getAddress(op.addressing);
					value = getValue(op.addressing, ad);
					accumulator = value ^ accumulator;
					value = accumulator;

				case ORA:
					var ad = getAddress(op.addressing);
					value = getValue(op.addressing, ad);
					accumulator = value | accumulator;
					value = accumulator;

				case DEX:
					x--;
					value = x;

				case DEY:
					y--;
					value = y;

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
					//Nothing to do

				case BRK:
					trace(dump_machine_state());
					break;

				default:
					trace("INSTRUCTION NOT IMPLEMENTED: "+op.code);
					break;
			}

			if (value != null)
			{
				zf = value == 0;
				nf = value & 0x80 == 0x80;
			}

			Sys.print(dump_machine_state());
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

	private function getSigned(byte:Int)
	{
		byte = byte & 0xFF;

		var negative = byte & 0x80 != 0;
		if (negative)
		{
			return ~(byte - 1);
		}
		else
		{
			return byte;
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
			case RELATIVE:
				address = getSigned(decoder.getByte(pc));
				pc++;

				address += pc;
			case ABSOLUTE:
				address = decoder.getByte(pc) + (decoder.getByte(pc + 1) << 8);
				pc += 2;
			default:
				trace("ADDRESSING MODE NOT IMPLEMENTED "+add);
		}

		return address;
	}

	private function dump_machine_state()
	{
		var out = " -- ";
		out += "PC:"+pc.format()+" ";
		out += "SP:"+sp.format()+" ";
		out += "AC:"+accumulator.format()+" ";
		out += "RX:"+x.format()+" ";
		out += "RY:"+y.format()+" ";
		out += (if (cf) "CF".bold() else "CF")+" ";
		out += (if (zf) "ZF".bold() else "ZF")+" ";
		out += (if (id) "ID".bold() else "ID")+" ";
		out += (if (dm) "DM".bold() else "DM")+" ";
		out += (if (bc) "BC".bold() else "BC")+" ";
		out += (if (of) "OF".bold() else "OF")+" ";
		out += (if (nf) "NF".bold() else "NF");

		return out;
	}

	static public function main()
	{
		var fileName = Sys.args()[0];

		var d = new Decode6502(sys.io.File.getBytes(fileName), 0xC000 - 0x10);
		var vm = new VirtualMachine(d, 0xC000);
	}
}
