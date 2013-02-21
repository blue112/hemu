class TerminalFormatter
{
	static public function format(num:Int)
	{
		return "\033[1;31m"+StringTools.hex(num, 2)+"\033[0m";
	}

	static public function bold(text:String)
	{
		return "\033[1m"+text+"\033[0m";
	}
}
