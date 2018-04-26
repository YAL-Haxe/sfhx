package sf.opt;

import sf.opt.SfOptImpl;
import sf.type.SfExprDef.*;
using sf.type.SfExprTools;

/**
 * var func = function(...) { ... } -> function func(...) { ... }
 * { var func = function(...); func; } -> function func(...) { ... }
 * @author YellowAfterlife
 */
class SfOptFunc extends SfOptImpl {
	
	override public function apply() {
		forEachExpr(function(e, w, f) {
			switch (e.def) {
				case SfBlock([
					_.def => SfVarDecl(v, true, x),
					_.def => SfLocal(v1)
				]): {
					if (v1.id == v.id) switch (x.def) {
						case SfFunction(fx): {
							fx.name = v.name;
							fx.sfvar = v;
							e.getData().t = x.getData().t;
							e.setTo(x.def);
						};
						default:
					}
				};
				case SfVarDecl(v, true, x): {
					switch (x.def) {
						case SfFunction(fx): {
							fx.name = v.name;
							fx.sfvar = v;
							e.getData().t = x.getData().t;
							e.setTo(x.def);
						};
						default:
					}
				};
				default:
			}
			e.iter(w, f);
		});
	}
	
}
