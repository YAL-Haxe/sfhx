package sf.type.expr;
import haxe.macro.Expr;
import haxe.macro.Expr.Binop;
import haxe.macro.Expr.Unop;
import haxe.macro.Type;
import sf.type.expr.SfExpr;

/**
 * Position information for trace(...) calls
 * @author YellowAfterlife
 */
typedef SfTraceData = {
	var fileName:String;
	var lineNumber:Int;
	var className:String;
	var methodName:String;
};