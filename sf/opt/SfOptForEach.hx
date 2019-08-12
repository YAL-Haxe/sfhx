package sf.opt;

import sf.opt.SfOptImpl;
import sf.type.expr.SfExprDef.*;
import sf.type.*;
import sf.type.expr.*;
using sf.type.expr.SfExprTools;

/**
 * ...
 * @author YellowAfterlife
 */
class SfOptForEach extends SfOptImpl {
	
	override public function apply() {
		var id:Int;
		function iter(e:SfExpr, w, f) {
			e.iter(w, f);
			inline function mod(x:SfExprDef):SfExpr {
				return e.mod(x);
			}
			switch (e.def) {
				case SfForEach(v, o, x): {
					var od = o.getData();
					var xd = x.getData();
					var iv = new SfVar("$it" + id++, o.getType());
					var ix = mod(SfLocal(iv));
					e.setTo((SfBlock([
						mod(SfVarDecl(iv, true, o)),
						mod(SfWhile(
							mod(SfParenthesis(
								mod(SfCall(mod(SfDynamicField(ix, "hasNext")), []))
							)),
							mod(SfBlock([
								mod(SfVarDecl(v, true,
									mod(SfCall(mod(SfDynamicField(ix, "next")), []))
								)),
								x,
							])),
							true
						))
					])));
				};
				default:
			}
		}
		forEachExpr(function(e, w, f) {
			id = 0;
			iter(e, w, iter);
		});
	}
	
}
