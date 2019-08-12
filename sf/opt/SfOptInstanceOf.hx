package sf.opt;

import sf.opt.SfOptImpl;
import sf.type.expr.SfExprDef.*;
import sf.type.*;
import sf.type.expr.*;
using sf.type.expr.SfExprTools;
import sf.SfCore.*;
import haxe.macro.Expr.Binop.*;
import haxe.macro.Expr.Unop.*;

/**
 * ...
 * @author YellowAfterlife
 */
class SfOptInstanceOf extends SfOptImpl {
	
	override public function apply() {
		forEachExpr(function(expr:SfExpr, w, f:SfExprIter) {
			expr.iter(w, f);
			var next:SfExprDef;
			inline function mod(d:SfExprDef):SfExpr {
				return expr.mod(d);
			}
			inline function setInstOf(x:SfExpr, t:SfType, not:Bool):Void {
				next = SfInstanceOf(x, mod(SfTypeExpr(t)));
				if (not) {
					expr.setTo(SfUnop(OpNot, false, mod(next)));
				} else expr.setTo(next);
			}
			switch (expr.def) {
				
				// `typeof(v) == "string"` -> instanceof(v, String)
				case SfBinop(op = OpEq | OpNotEq,
					_.def => SfTypeOf(x),
					_.def => SfConst(TString("string"))
				): setInstOf(x, sfGenerator.typeString, op == OpNotEq);
				
				// `typeof(v) == "number"` -> instanceof(v, Float)
				case SfBinop(op = OpEq | OpNotEq,
					_.def => SfTypeOf(x),
					_.def => SfConst(TString("number"))
				): setInstOf(x, sfGenerator.typeFloat, op == OpNotEq);
				
				// `typeof(v) == "boolean"` -> instanceof(v, Bool)
				case SfBinop(op = OpEq | OpNotEq,
					_.def => SfTypeOf(x),
					_.def => SfConst(TString("boolean"))
				): setInstOf(x, sfGenerator.typeBool, op == OpNotEq);
				
				// `typeof(v) == "number" && ((v | 0) === v)` -> instanceof(v, Int)
				case SfBinop(OpBoolAnd,
					_.def => SfInstanceOf(x1, _.def => SfTypeExpr(t1)),
					_.def => SfStrictEq(
						_.def => SfBinop(OpOr, x2, _.def => SfConst(TInt(0))),
						x3
					)
				) if (
					t1 == sfGenerator.typeFloat && x1.equals(x2) && x1.equals(x3)
				): setInstOf(x1, sfGenerator.typeInt, false);
				
				// `instanceof(v, Array) && v.__enum__ == null` -> instanceof(v, Array) [redundancy]
				case SfBinop(OpBoolAnd,
					_.def => x = SfInstanceOf(e, et = _.def => SfTypeExpr(t)),
					_.def => SfBinop(OpEq,
						_.def => SfDynamicField(e1, "__enum__"),
						_.def => SfConst(TNull)
					)
				) if (
					t == sfGenerator.typeArray && e.equals(e1)
				): expr.def = x;
				
				default:
			}
		});
	}
	
}
