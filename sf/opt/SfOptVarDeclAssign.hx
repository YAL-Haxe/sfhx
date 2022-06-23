package sf.opt;

import sf.opt.SfOptImpl;
import sf.type.expr.SfExprDef.*;
import sf.type.*;
import sf.type.expr.*;
using sf.type.expr.SfExprTools;

/**
 * `var some; some = value;` -> `var some = value;`
 * No longer used as of 2020.
 * @author YellowAfterlife
 */
class SfOptVarDeclAssign extends SfOptImpl {
	
	override public function apply() {
		forEachExpr(function(e:SfExpr, w, f) {
			e.iter(w, f);
			var exprs = switch (e.def) {
				case SfBlock(_exprs): _exprs;
				default: return;
			}
			var i = 0;
			var n = m.length - 1;
			while (i < n) {
				switch (m[i].def) {
					case SfVarDecl(v, false, _): {
						switch (m[i + 1].def) {
							case SfBinop(OpAssign, _.def => SfLocal(v1), x): {
								if (v.equals(v1)) {
									m[i].setTo(SfVarDecl(v, true, x));
									m.splice(i + 1, 1);
									n -= 1;
									continue;
								}
							};
							default:
						}
					};
					default:
				}
				i += 1;
			}
		});
	}
	
}
