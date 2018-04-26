package sf.opt;

import sf.opt.SfOptImpl;
import sf.type.SfExprDef.*;
import sf.type.*;
using sf.type.SfExprTools;
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
			switch (expr.def) {
				case SfBinop(op = OpEq | OpNotEq,
					_.def => SfCall(_.def => (
						SfDynamic("__typeof__", _) |
						SfStaticField({ realName: "Syntax" }, { realName: "typeof" })
					), [x]),
					_.def => SfConst(TString("string"))
				): { // `__typeof__(v) == "string"`
					next = SfInstanceOf(x, mod(SfTypeExpr(sfGenerator.typeString)));
					if (op == OpNotEq) {
						expr.setTo(SfUnop(OpNot, false, mod(next)));
					} else expr.setTo(next);
				};
				case SfBinop(op = OpEq | OpNotEq,
					_.def => SfCall(_.def => (
						SfDynamic("__typeof__", _) |
						SfStaticField({ realName: "Syntax" }, { realName: "typeof" })
					), [x]),
					_.def => SfConst(TString("number"))
				): { // `__typeof__(v) == "number"`
					next = SfInstanceOf(x, mod(SfTypeExpr(sfGenerator.typeFloat)));
					if (op == OpNotEq) {
						expr.setTo(SfUnop(OpNot, false, mod(next)));
					} else expr.setTo(next);
				};
				case SfBinop(op = OpEq | OpNotEq,
					_.def => SfCall(_.def => (
						SfDynamic("__typeof__", _) |
						SfStaticField({ realName: "Syntax" }, { realName: "typeof" })
					), [x]),
					_.def => SfConst(TString("boolean"))
				): { // `__typeof__(v) == "boolean"`
					next = SfInstanceOf(x, mod(SfTypeExpr(sfGenerator.typeBool)));
					if (op == OpNotEq) {
						expr.setTo(SfUnop(OpNot, false, mod(next)));
					} else expr.setTo(next);
				};
				case SfCall(_.def => SfDynamic("__strict_eq__", _), [
					_.def => SfParenthesis(_.def => SfBinop(OpOr,
						e, _.def => SfConst(TInt(0))
					)),
					e1
				]) if (e.equals(e1)): { // `__strict_eq__((e|0), e)`
					expr.setTo(SfInstanceOf(e, mod(SfTypeExpr(sfGenerator.typeInt))));
				};
				case SfBinop(OpBoolAnd,
					_.def => SfCall(_.def => SfDynamic("__instanceof__", _), [
						e, et = _.def => SfTypeExpr(t)
					]),
					_.def => SfBinop(OpEq,
						_.def => SfDynamicField(e1, "__enum__"),
						_.def => SfConst(TNull)
					)
				), SfBinop(OpBoolAnd,
					_.def => SfInstanceOf(e, et = _.def => SfTypeExpr(t)),
					_.def => SfBinop(OpEq,
						_.def => SfDynamicField(e1, "__enum__"),
						_.def => SfConst(TNull)
					)
				) if (
					t == sfGenerator.typeArray && e.equals(e1)
				): { // `__instanceof__(e, Type) && e.__enum__ != null`
					expr.setTo(SfInstanceOf(e, et));
				};
				default:
			}
		});
	}
	
}
