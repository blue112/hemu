class TerminalFormatter
{
	static public function format(num:Int)
	{
		if (VirtualMachine.colorEnabled)
			return "\033[1;31m"+StringTools.hex(num, 2)+"\033[0m";
		else
			return StringTools.hex(num, 2);
	}

	static public function yellow(text:String)
	{
		if (VirtualMachine.colorEnabled)
			return "\033[1;33m"+text+"\033[0m";
		else
			return text;
	}

	static public function bold(text:String)
	{
		if (VirtualMachine.colorEnabled)
			return "\033[1m"+text+"\033[0m";
		else
			return text;
	}
}
