package sf.opt;

import sf.opt.SfOptImpl;
import sf.type.SfExprDef.*;
import sf.type.*;
using sf.type.SfExprTools;

/**
 * Removes "stray" constants and local variables left mid-block.
 * @author YellowAfterlife
 */
class SfOptStrayStatements extends SfOptImpl {
	
	override public function apply() {
		var isVar:Bool = false;
		function iter(e:SfExpr, w:Array<SfExpr>, f:SfExprIter):Void {
			switch (e.def) {
				case SfBlock(exprs): {
					var i = 0;
					var n = exprs.length;
					while (i < n) {
						switch (exprs[i].def) {
							case SfLocal(_) | SfConst(_): {
								if (i == n - 1 && w.length == 0 && isVar) {
									// don't cull the last expression in variable init
									f(exprs[i], w, f);
									i++;
								} else {
									exprs.splice(i, 1);
									n--;
								}
							};
							default: {
								f(exprs[i], w, f);
								i++;
							};
						}
					}
				};
				default: e.iter(w, f);
			}
		}
		forEachExpr(function(e:SfExpr, w, f) {
			isVar = false;
			if (currentField != null) switch (currentField.kind) {
				case FVar(_, _): isVar = true;
				default:
			}
			iter(e, w, iter);
		}, []);
	}
	
}
