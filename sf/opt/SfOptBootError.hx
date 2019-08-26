package sf.opt;

import haxe.ds.Map;
import sf.opt.SfOptImpl;
import sf.type.expr.SfExprDef.*;
import sf.type.*;
import sf.type.expr.*;
using sf.type.expr.SfExprTools;

/**
 * ...
 * @author YellowAfterlife
 */
class SfOptBootError extends SfOptImpl {
	override public function apply():Void {
		var _Error:SfClass = cast SfCore.sfGenerator.realMap["js._Boot.HaxeError"];
		if (_Error == null) return;
		forEachExpr(function(expr:SfExpr, stack:SfExprList, iter:SfExprIter) {
			switch (expr.def) {
				case SfNew(c, _, [x]) if (c == _Error): {
					expr.def = x.def;
				};
				case SfIf(
					_.def => SfParenthesis(_.def => SfInstanceOf(
						_.def => SfLocal(v1), _.def => SfTypeExpr(t)
					)),
					_.def => SfInstField(_.def => SfLocal(v2), { name: "val" }),
					true, x = _.def => SfLocal(v3)
				) if (t == _Error && v1.equals(v2) && v1.equals(v3)): {
					expr.def = x.def;
				};
				default:
			}
			expr.iter(stack, iter);
		});
		trace(_Error);
	}
}
