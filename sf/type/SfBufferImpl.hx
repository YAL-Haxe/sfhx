package sf.type;
import haxe.macro.Expr;
import haxe.macro.Type;
import sf.SfCore.*;

#if (display)
private class SfBufferBase {
	public var length:Int;
	public function new() { }
	public function add<T>(v:T):Void { }
	public function addChar(c:Int):Void { }
	public function addSub(s:String, i:Int, ?n:Int):Void { }
	public function toString():String return "";
}
#else
private typedef SfBufferBase = StringBuf;
#end
/**
 * ...
 * @author YellowAfterlife
 */
class SfBufferImpl extends SfBufferBase {
	public var indent:Int = 0;
	/** Semicolons are not inserted before this offset */
	public var semicoAfter:Int = 0;
	public function new() {
		super();
	}
	public inline function addString(s:String) this.add(s);
	public inline function addInt(i:Int) this.add(i);
	public inline function addFloat(f:Float) this.add(f);
	public inline function addBuffer(b:SfBufferImpl) this.add(b);
	
	/** A shortcut to add two characters at once. */
	public inline function addChar2(c1:Int, c2:Int) {
		addChar(c1);
		addChar(c2);
	}
	
	/** A shortcut to add 3 characters at once. */
	public inline function addChar3(c1:Int, c2:Int, c3:Int) {
		addChar(c1);
		addChar(c2);
		addChar(c3);
	}
	
	/** A shortcut for adding a semicolon */
	public inline function addSemico() {
		if (length > semicoAfter) {
			addChar(";".code);
			semicoAfter = length;
		}
	}
	
	public inline function markSemico() {
		semicoAfter = length;
	}
	
	/** A shortcut for a comma + optional space */
	public inline function addComma() {
		addChar(",".code);
		addSep();
	}
	
	/** A shortcut for dot\period */
	public inline function addDot() addChar(".".code);
	
	public function addTypePath(s:SfType, sep:Int = ".".code) {
		var p = s.pack;
		var n = p.length;
		var i = 0;
		while (i < n) {
			addString(p[i]);
			addChar(sep);
			i += 1;
		}
		addString(s.name);
	}
	
	public function addFieldPath(s:SfField, packSep:Int = ".".code, dotSep:Int = ".".code) {
		var e = s.exposePath;
		if (e != null) {
			addString(e);
			return;
		}
		var l = length;
		var p = s.parentType.pack;
		var n = p.length;
		var i = 0;
		while (i < n) {
			addString(p[i]);
			addChar(packSep);
			i += 1;
		}
		addString(s.parentType.name);
		if (length > l) addChar(dotSep);
		addString(s.name);
	}
	
	/** Adds an expression */
	public inline function addExpr(e:SfExpr, wrap:Bool) {
		#if !display
		sfGenerator.printExpr(cast this, e, wrap);
		#end
	}
	
	/** Adds an { expression } */
	public inline function addBlockExpr(e:SfExpr) {
		addBlockOpen();
		if (SfExprTools.isEmpty(e)) {
			addSep();
		} else {
			addLine(1);
			addExpr(e, false);
			addSemico();
			addLine( -1);
		}
		addBlockClose();
	}
	
	/** Adds an argument name list `v1, v2`, for function declarations. */
	public function addArguments(args:Array<SfArgument>) {
		for (i in 0 ... args.length) {
			if (i > 0) addComma();
			addString(args[i].v.name);
		}
	}
	
	public function addTrailArgs(args:Array<SfArgument>) {
		for (i in 0 ... args.length) {
			addComma();
			addString(args[i].v.name);
		}
	}
	
	/** Adds a linebreak, changing indentation by the specified delta */
	public function addLine(delta:Int = 0) {
		if (delta != 0) this.indent += delta;
		addChar("\r".code);
		addChar("\n".code);
		var i = indent;
		while (--i >= 0) {
			addChar("\t".code);
		}
	}
	
	/** A shortcut for "{" */
	public inline function addBlockOpen() addChar("{".code);
	
	/** A shortcut for "}" */
	public inline function addBlockClose() {
		addChar("}".code);
		semicoAfter = length;
	}
	
	//{ ()
	
	/** A shortcut for "(" */
	public inline function addParOpen() addChar("(".code);
	
	/** A shortcut for ")" */
	public inline function addParClose() addChar(")".code);
	
	/** Adds */
	public inline function addParExpr(e:SfExpr) {
		addParOpen();
		addExpr(e, true);
		addParClose();
	}
	
	public inline function addParExpr2(e1:SfExpr, e2:SfExpr) {
		addParOpen();
		addExpr(e1, true);
		addComma();
		addExpr(e2, true);
		addParClose();
	}
	
	public inline function addParExpr3(e1:SfExpr, e2:SfExpr, e3:SfExpr) {
		addParOpen();
		addExpr(e1, true);
		addComma();
		addExpr(e2, true);
		addComma();
		addExpr(e3, true);
		addParClose();
	}
	//}
	//{ sep
	
	/** Adds an optional separator */
	public inline function addSep() {
		if (sfConfig.pretty) addChar(" ".code);
	}
	
	/** Adds a character, surrounded by separators */
	public inline function addSepChar(c:Int) {
		addSep();
		addChar(c);
		addSep();
	}
	
	/** Adds 2 characters, surrounded by separators */
	public inline function addSepChar2(c1:Int, c2:Int) {
		addSep();
		addChar(c1);
		addChar(c2);
		addSep();
	}
	
	/** Adds 3 characters, surrounded by separators */
	public inline function addSepChar3(c1:Int, c2:Int, c3:Int) {
		addSep();
		addChar(c1);
		addChar(c2);
		addChar(c3);
		addSep();
	}
	
	//}
	//{
	public inline function addHintOpen() addChar3("/".code, "*".code, " ".code);
	public inline function addHintClose() addChar3(" ".code, "*".code, "/".code);
	public inline function addHintString(s:String) {
		if (sfConfig.hint) {
			addHintOpen();
			addString(s);
			addHintClose();
		}
	}
	//}
	
}
