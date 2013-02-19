import Decode6502.AddressingMode;
import Decode6502.Command;
import Decode6502.OPCode;

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

			if (op == null)
				break;

			trace("Execute "+op.code);

			switch (op.code)
			{
				case STA: //Store Accumulator
					var ad = getAddress(op.addressing);
					memory.set(ad, accumulator);
					//TODO : set flags
				case LDA:
					var ad = getAddress(op.addressing);
					accumulator = memory.get(ad);
				case INC:
					var ad = getAddress(op.addressing);
					memory.set(ad, memory.get(ad) + 1);
				default:
					trace("INSTRUCTION NOT IMPLEMENTED: "+op.code);
			}

			trace(dump_machine_state());
		}
		while (op != null);
	}

	private function getAddress(add:AddressingMode):Int
	{
		var address = 0;

		switch (add)
		{
			case ZERO_PAGE:
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
		out += "PC => "+pc+"\n";
		out += "SP => "+sp+"\n";
		out += "AC => "+accumulator+"\n";
		out += "RX => "+x+"\n";
		out += "RY => "+y+"\n";
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
