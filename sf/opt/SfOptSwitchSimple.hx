package sf.opt;

import sf.opt.SfOptImpl;
import sf.type.SfExprDef.*;
import sf.type.*;
using sf.type.SfExprTools;

/**
 * Converts single-case switches (mostly on enums) into if-blocks.
 * @author YellowAfterlife
 */
class SfOptSwitchSimple extends SfOptImpl {
	
	override public function apply() {
		forEachExpr(function(e, w, f) {
			e.iter(w, f);
			switch (e.def) {
				case SfSwitch(_expr, [{ values: [_val], expr: _then }], _, _else): {
					var op = haxe.macro.Expr.Binop.OpEq;
					if (_then.isEmpty() && _else != null) {
						op = haxe.macro.Expr.Binop.OpNotEq;
						_then = _else;
						_else = null;
					}
					if (_else != null && _else.isEmpty()) _else = null;
					var _cond = _expr.mod(SfBinop(op, _expr.unpack(), _val));
					e.setTo(SfIf(e.mod(SfParenthesis(_cond)), _then, _else != null, _else));
				};
				default:
			}
		});
	}
}
