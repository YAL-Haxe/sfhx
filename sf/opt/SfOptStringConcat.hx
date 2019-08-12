package sf.opt;

import sf.opt.SfOptImpl;
import sf.type.expr.SfExprDef.*;
import sf.type.*;
import sf.type.expr.*;
import haxe.macro.Expr.Binop.*;
import haxe.macro.Type.TConstant.*;
using sf.type.expr.SfExprTools;

/**
 * Concats string constants.
 * @author YellowAfterlife
 */
class SfOptStringConcat extends SfOptImpl {
	
	override public function apply() {
		forEachExpr(function(e:SfExpr, w, f) {
			e.iter(w, f);
			switch (e.def) {
				case SfBinop(OpAdd,
					_.def => SfConst(TString(s1)),
					_.def => SfConst(TString(s2))
				): {
					e.setTo(SfConst(TString(s1 + s2)));
				};
				case SfBinop(OpAdd, _.def => SfConst(TString("")), x): {
					switch (x.unpack().def) {
						case SfBinop(OpAdd, _.def => SfConst(TString(_)), _)
						| SfBinop(OpAdd, _, _.def => SfConst(TString(_))): {
							// `"" + (a + "b")` -> `(a + "b")`
							e.setTo(x.clone().def);
						};
						default:
					}
				};
				case SfBinop(OpAdd,
					_.def => SfBinop(OpAdd, _.def => SfConst(TString("")), a),
					b = _.def => SfConst(TString(_))
				): {
					// `("" + a) + "b"` -> `a + "b"`
					e.setTo(SfBinop(OpAdd, a, b));
				};
				case SfBinop(OpAdd, _.def => SfConst(TString(s1)), x): {
					switch (x.unpack().def) {
						case SfBinop(OpAdd, _.def => SfConst(TString(s2)), v): {
							// "s1" + ("s2" + v)
							e.setTo(SfBinop(OpAdd, e.mod(SfConst(TString(s1 + s2))), v));
						};
						default:
					}
				};
				case SfBinop(OpAdd, x, _.def => SfConst(TString(s2))): {
					switch (x.unpack().def) {
						case SfBinop(OpAdd, v, _.def => SfConst(TString(s1))): {
							// (v + "s1") + "s2"
							e.setTo(SfBinop(OpAdd, v, e.mod(SfConst(TString(s1 + s2)))));
						};
						default:
					}
				};
				default:
			}
		});
	}
	
}
