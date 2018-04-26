package sf.type;

/**
 * Just you look at that, a non-macros printf.
 * Does everything have to be such a trouble...
 * @author YellowAfterlife
 */
@:noCompletion
class SfPrintf {
	public static function parse(fmt:String):Array<SfPrintfNode> {
		var pos:Int = 0;
		var length:Int = fmt.length;
		var start:Int = 0;
		var out:Array<SfPrintfNode> = [];
		inline function flush() {
			if (start < pos) out.push(SfPrintfNode.addText(fmt.substring(start, pos)));
		}
		while (pos < length) {
			switch (StringTools.fastCodeAt(fmt, pos)) {
				case "\n".code: {
					flush();
					out.push(SfPrintfNode.addLine);
					start = pos + 1;
				};
				case ";".code: {
					flush();
					out.push(SfPrintfNode.addSemico);
					start = pos + 1;
				}
				case "{".code: {
					flush();
					out.push(SfPrintfNode.addBlockOpen);
					start = pos + 1;
				}
				case "}".code: {
					flush();
					out.push(SfPrintfNode.addBlockClose);
					start = pos + 1;
				}
				case "`".code: {
					flush();
					out.push(SfPrintfNode.addSep);
					start = pos + 1;
				};
				case "%".code: {
					flush();
					switch (StringTools.fastCodeAt(fmt, ++pos)) {
						case "`".code: out.push(SfPrintfNode.addAccent);
						case ";".code: out.push(SfPrintfNode.markSemico);
						case "s".code: out.push(SfPrintfNode.addString);
						case "d".code: out.push(SfPrintfNode.addInt);
						case "c".code: out.push(SfPrintfNode.addChar);
						case "x".code: out.push(SfPrintfNode.addExpr);
						case "(".code: {
							start = ++pos;
							pos = fmt.indexOf(")", start);
							var name = fmt.substring(start, pos);
							switch (name) {
								case "const": out.push(SfPrintfNode.addConst);
								case "stat": out.push(SfPrintfNode.addStat);
								case "block": out.push(SfPrintfNode.addBlock);
								case "expr": out.push(SfPrintfNode.addExpr);
								case "args": out.push(SfPrintfNode.addArgs);
								case "targs": out.push(SfPrintfNode.addTArgs);
								case "+\n": out.push(SfPrintfNode.addIncLine);
								case "-\n": out.push(SfPrintfNode.addDecLine);
								default: out.push(SfPrintfNode.addCustom(name));
							}
							start = pos + 1;
						};
						case "z".code: throw "No longer allowed.";
						default: throw fmt.charAt(pos) + " is not a known type.";
					}
					start = pos + 1;
				};
				default:
			}
			pos += 1;
		}
		flush();
		return out;
	}
	private static var cache:Map<String, Array<SfPrintfNode>> = new Map();
	private static inline function runInner(params:Array<Dynamic>, buf:SfBuffer) {
		var paramIndex = 0;
		inline function next():Any return params[paramIndex++];
		if (buf == null) buf = next();
		var fmt:String = next();
		var tks = cache.get(fmt);
		if (tks == null) {
			tks = parse(fmt);
			cache.set(fmt, tks);
		}
		for (i in 0 ... tks.length) switch (tks[i]) {
			case addText(s): buf.addString(s);
			case addLine: buf.addLine();
			case addSemico: buf.addSemico();
			case addBlockOpen: buf.addBlockOpen();
			case addBlockClose: buf.addBlockClose();
			case addSep: buf.addSep();
			case addAccent: buf.addChar("`".code);
			case markSemico: buf.markSemico();
			case addString: buf.addString(next());
			case addInt: buf.addInt(next());
			case addChar: buf.addChar(next());
			case addConst: SfCore.sfGenerator.printConst(buf, next(), null);
			case addExpr: buf.addExpr(next(), true);
			case addStat: buf.addExpr(next(), false);
			case addBlock: buf.addExpr(next(), null);
			case addArgs: buf.addArguments(next());
			case addTArgs: buf.addTrailArgs(next());
			case addIncLine: buf.addLine(1);
			case addDecLine: buf.addLine( -1);
			case addCustom(s): {
				var fr = SfCore.sfGenerator.printFormat(buf, s, params[paramIndex]);
				if (fr) {
					paramIndex += 1;
				} else if (fr == null) {
					throw s + " is not a known type.";
				}
			};
		}
	}
	public static function printf(params:Array<Dynamic>):Dynamic {
		runInner(params, null);
		return params[0];
	}
	public static function sprintf(params:Array<Dynamic>):Dynamic {
		var buf = new SfBuffer();
		runInner(params, buf);
		return buf.toString();
	}
}
enum SfPrintfNode {
	addText(s:String);
	addLine;
	addSemico;
	addBlockOpen;
	addBlockClose;
	addSep;
	addAccent;
	markSemico;
	addString;
	addInt;
	addChar;
	addConst;
	addExpr;
	addStat;
	addBlock;
	addArgs;
	addTArgs;
	addIncLine;
	addDecLine;
	addCustom(s:String);
}
