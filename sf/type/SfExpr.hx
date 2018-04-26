package sf.type;
import haxe.macro.Expr;
import haxe.macro.Expr.Binop;
import haxe.macro.Expr.Unop;
import haxe.macro.Type;

/**
 * ...
 * @author YellowAfterlife
 */
class SfExpr {
	public var data:SfExprData;
	public var def:SfExprDef;
	public function new(d:SfExprData, x:SfExprDef) {
		data = d;
		def = x;
	}
	public function getName():String {
		return def.getName();
	}
	public inline function mod(x:SfExprDef):SfExpr {
		return new SfExpr(data, x);
	}
	@:keep public function toString():String {
		return Std.string(def);
	}
}

typedef SfExprCase = {
	var values:Array<SfExpr>;
	var expr:SfExpr;
};
typedef SfExprCatch = { v:SfVar, expr:SfExpr };
typedef SfExprFunction = {
	@:optional var name:String;
	@:optional var sfvar:SfVar;
	var args:Array<SfArgument>;
	var ret:Type;
	var expr:SfExpr;
};
typedef SfTraceData = { fileName:String, lineNumber:Int, className:String, methodName:String };
typedef SfExprData = haxe.macro.Type.TypedExpr;
