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

	var memory:Map<Int, Int>;

	var decoder:Decode6502;

	static public var colorEnabled:Bool = true;
	static private inline var INTERRUPT_VECTOR_NMI = 0xFFFA; // Non-maskable interrupt.
	static private inline var INTERRUPT_VECTOR_RESET = 0xFFFC; // Reset interrupt.
	static private inline var INTERRUPT_VECTOR_IRQ = 0xFFFE; // Interrupt request or BRK instruction.

	private function new(decoder:Decode6502)
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

		memory = new Map();
		for (i in 0...0xFFFF)
			memory.set(i, 0);

		for (i in 0...0x07FF)
			memory.set(i, 0xFF);

		//Load rom into ram
		/*for (i in 0x8000...0xFFFF)
		{
			memory.set(i, decoder.getByte(i - 0x8000));
		}*/
		for (i in 0x8000...0xBFFF)
		{
			memory.set(i, decoder.getByte(i - 0x8000));
		}
		for (i in 0xC000...0xFFFF)
		{
			memory.set(i, decoder.getByte(i - 0xC000));
		}

		memory.set(0x2002, 0x80);

		this.decoder = decoder;

		//pc = 0x8000;
		pc = 0x8000;
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

	private function setProcessorFlags(value:Int):Void
	{
		cf = value & 0x1 != 0;
		zf = value & 0x2 != 0;
		id = value & 0x4 != 0;
		dm = value & 0x8 != 0;
		bc = value & 0x10 != 0;
		of = value & 0x40 != 0;
		nf = value & 0x80 != 0;
	}

	private inline function sbc(v:Int)
	{
		var acc_anc_value = accumulator;

		accumulator = accumulator - v - (cf ? 0 : 1);
		//trace(acc_anc_value.format()+" - "+v.format()+" "+cf+" = "+accumulator);
		if (accumulator > 0xFF || accumulator < 0) //Overflow
		{
			cf = false;
		}
		else
		{
			cf = true;
		}

		if (accumulator < 0)
			accumulator += 0xFF + 1;

		if (acc_anc_value > 0x7F && accumulator < 0x7F)
		{
			of = true;
		}
		else
		{
			of = false;
		}

		return accumulator;
	}

	private inline function adc(v:Int)
	{
		var acc_anc_value = accumulator;

		accumulator = accumulator + v + (cf ? 1 : 0);
		if (accumulator > 0xFF)
		{
			cf = true;
			accumulator &= 0xFF;
		}
		else
		{
			cf = false;
		}

		if (acc_anc_value <= 0x7F && accumulator > 0x7F && v & 0x80 != 0x80)
		{
			of = true;
		}
		else
		{
			of = false;
		}

		return accumulator;
	}

	private function run()
	{
		var op;
		do
		{
			var b = memory.get(pc);
			op = decoder.decodeByte(b);

			var value:Null<Int> = null;

			Sys.print("\n"+pc.hex(4)+" "+Std.string(op.code).rpad(" ", 6).yellow()+" "+b.format());
			pc++;

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

				case SAX:
					var ad = getAddress(op.addressing);
					memory.set(ad, x & accumulator);

				case SEI, CLI:
					id = op.code == SEI;

				case SED, CLD:
					dm = op.code == SED;

				case SEC, CLC:
					cf = op.code == SEC;

				case CLV:
					of = false;

				case BIT:
					var ad = getAddress(op.addressing);
					var v = getValue(op.addressing, ad);
					zf = accumulator & v == 0;
					of = v & 0x40 != 0;
					nf = v & 0x80 != 0;

				case CMP, CPY, CPX:
					var ad = getAddress(op.addressing);
					var v = getValue(op.addressing, ad);

					var compare_to = switch (op.code)
					{
						case CMP: accumulator;
						case CPX: x;
						default: y;
					}

					var tmp = compare_to - v;
					if (tmp < 0)
						tmp += 0xFF + 1;

					cf = compare_to >= v;
					zf = compare_to == v;
					nf = tmp & 0x80 == 0x80;

				case DCP: //DEC + CMP
					var ad = getAddress(op.addressing);
					var v = getValue(op.addressing, ad) - 1;
					v &= 0xFF;
					memory.set(ad, v);

					var tmp = accumulator - v;
					if (tmp < 0)
						tmp += 0xFF + 1;

					cf = accumulator >= v;
					zf = accumulator == v;
					nf = tmp & 0x80 == 0x80;

				case ADC:
					var ad = getAddress(op.addressing);
					var v = getValue(op.addressing, ad);

					value = adc(v);

				case RRA:
					var ad = getAddress(op.addressing);
					var v = getValue(op.addressing, ad);
					var new_cf = v & 1 != 0;
					value = (v >> 1) & 0xFF;
					value += cf ? 0x80 : 0;

					cf = new_cf;
					memory.set(ad, value);

					value = accumulator = adc(value);

				case SBC:
					var ad = getAddress(op.addressing);
					var v = getValue(op.addressing, ad);
					value = sbc(v);

				case ISB:
					var ad = getAddress(op.addressing);
					var v = getValue(op.addressing, ad);
					v++;
					v &= 0xFF;
					memory.set(ad, v);

					value = sbc(v);

				case JSR:
					var ad = getAddress(op.addressing);
					pushStack(pc - 1 >> 8);
					pushStack(pc - 1 & 0xFF);

					pc = ad;

				case RTS:
					var to = pullStack();
					to += pullStack() << 8;
					pc = to + 1;

				case RTI:
					setProcessorFlags(pullStack());
					var to = pullStack();
					to += pullStack() << 8;

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

				case SRE:
					var ad = getAddress(op.addressing);
					var v = getValue(op.addressing, ad);
					cf = v & 1 != 0;
					value = v >> 1;

					memory.set(ad, value);

					accumulator = value ^ accumulator;
					value = accumulator;

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

				case RLA:
					var ad = getAddress(op.addressing);
					var v = getValue(op.addressing, ad);
					var new_cf = v & 0x80 != 0;
					value = (v << 1) & 0xFF;
					value += cf ? 1 : 0;

					memory.set(ad, value);
					cf = new_cf;

					//AND
					accumulator &= value;
					value = accumulator;

				case SLO:
					var ad = getAddress(op.addressing);
					var v = getValue(op.addressing, ad);

					cf = v & 0x80 != 0;
					v = (v << 1) & 0xFF;
					memory.set(ad, v);

					//OR
					accumulator |= v;
					value = accumulator;

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
					{
						pc = jump_to;
					}

				case JMP:
					var ad = getAddress(op.addressing);
					pc = ad;

				case JMA:
					var ad = getAddress(INDIRECT);
					pc = ad;

				case LAX: //LDX + TXA
					//LDX
					var ad = getAddress(op.addressing);
					x = getValue(op.addressing, ad);

					//TXA
					accumulator = value = x;

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
					y = getValue(op.addressing, ad) & 0xFF;

					zf = y == 0;
					nf = y & 0x80 == 0x80;

				case PHA:
					pushStack(accumulator);

				case PHP:
					var arFlags = [cf, zf, id, dm, true, true, of, nf]; //BC is always pushed as true
					var value = 0;
					for (i in 0...arFlags.length)
					{
						if (arFlags[i])
							value |= 1 << i;
					}
					pushStack(value);

				case PLP:
					var value = pullStack();
					setProcessorFlags(value);

				case PLA:
					accumulator = value = pullStack();

				case INC:
					var ad = getAddress(op.addressing);
					value = memory.get(ad) + 1;
					value &= 0xFF;
					memory.set(ad, value);

				case INX:
					x = (x + 1);
					x &= 0xFF;
					value = x;

				case INY:
					y = y + 1;
					y &= 0xFF;
					value = y;

				case DEC:
					var ad = getAddress(op.addressing);
					value = memory.get(ad) - 1;
					value &= 0xFF;
					memory.set(ad, value);

				case EOR:
					var ad = getAddress(op.addressing);
					value = getValue(op.addressing, ad);
					accumulator = value ^ accumulator;
					value = accumulator;

				case ORA:
					var ad = getAddress(op.addressing);
					value = getValue(op.addressing, ad);
					accumulator |= value;
					value = accumulator;

				case DEX:
					x = (x - 1) & 0xFF;
					value = x;

				case DEY:
					y = (y - 1) & 0xFF;
					value = y;

				case TAX:
					x = value = accumulator;

				case TXA:
					accumulator = value = x;

				case TSX:
					x = value = sp;

				case TAY:
					y = value = accumulator & 0xFF;

				case TXS:
					sp = x;

				case TYA:
					accumulator = value = y;

				case NOP(ignore):
					pc += ignore;
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

		//Try to output test result
		/*if (memory.get(0x6001) == 0xDE && memory.get(0x6002) == 0xB0)
		{
			var out = "";
			var pos = 0x6004;
			var value;
			do
			{
				value = memory.get(pos);
				out += String.fromCharCode(value);
				pos++;
			}
			while (value != 0);
			trace(out);
		}
		else
		{
			trace("Nothing like that in ram :/");
		}*/
	}

	private function getValue(add:AddressingMode, address:Int):Int
	{
		switch (add)
		{
			case IMMEDIATE:
				return address & 0xFF;

			case ACCUMULATOR:
				return accumulator;

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
			return -((~(byte - 1)) & 0xFF);
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
			case ACCUMULATOR:
				address = 0; //Handled in getValue

			case ZERO_PAGE:
				address = memory.get(pc);
				pc++;

			case ZERO_PAGE_X, ZERO_PAGE_Y:
				address = memory.get(pc);
				pc++;

				if (add == ZERO_PAGE_X)
					address += x;
				else if (add == ZERO_PAGE_Y)
					address += y;

				address &= 0xFF;

			case IMMEDIATE:
				address = memory.get(pc);
				pc++;

			case RELATIVE:
				address = getSigned(memory.get(pc));
				pc++;

				address += pc;

			case INDIRECT:
				address = memory.get(pc) + (memory.get(pc + 1) << 8);
				pc += 2;

				var next_addr = address + 1;
				if (next_addr & 0xFF == 0x00)
				{
					next_addr -= 0x0100;
				}

				address = memory.get(address) + (memory.get(next_addr) << 8);

			case ZERO_PAGE_X_2:
				address = memory.get(pc);
				pc++;

				address += x;
				address &= 0xFF;

				address = memory.get(address) + (memory.get((address + 1) & 0xFF) << 8);

			case ZERO_PAGE_Y_2:
				address = memory.get(pc);
				pc++;

				address = memory.get(address) + (memory.get((address + 1) & 0xFF) << 8);
				address += y;
				address &= 0xFFFF;

			case ABSOLUTE, ABSOLUTE_X, ABSOLUTE_Y:
				address = memory.get(pc) + (memory.get(pc + 1) << 8);
				pc += 2;

				if (add == ABSOLUTE_X)
					address += x;
				else if (add == ABSOLUTE_Y)
					address += y;

				address &= 0xFFFF;
		}

		return address;
	}

	private function dump_machine_state()
	{
		var out = " -- ";
		out += "AC:"+accumulator.format()+" ";
		//out += "PC:"+pc.format()+" ";
		out += "RX:"+x.format()+" ";
		out += "RY:"+y.format()+" ";
		out += "SP:"+sp.format()+" ";
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
		var args = Sys.args();
		var fileName = args[0];

		if (args.length > 1)
		{
			VirtualMachine.colorEnabled = args[1] != "--no-colors";
		}

		var d = new Decode6502(sys.io.File.getBytes(fileName), 0x10);
		var vm = new VirtualMachine(d);
	}
}
