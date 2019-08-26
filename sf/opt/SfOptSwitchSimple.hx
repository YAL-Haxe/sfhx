package sf.opt;

import haxe.macro.Context;
import sf.opt.SfOptImpl;
import sf.type.expr.SfExprDef.*;
import sf.type.*;
import sf.type.expr.*;
using sf.type.expr.SfExprTools;

/**
 * Small tweaks for switch blocks
 * @author YellowAfterlife
 */
class SfOptSwitchSimple extends SfOptImpl {
	
	/**
	 * Converts single-case switches (mostly on enums) into if-blocks.
	 * As far as I can tell, Haxe4 should be doing this for you almost always..?
	 */
	private function applyIf() {
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
	
	/**
		Original code:
		@:sf.unwrapper function useOne(e:Enum) {
			switch (e) {
				case Enum.One(a): return a;
				default: return null;
			}
		}
		Compiled as:
		@:sf.unwrapper function useOne(e:Enum) {
			switch (e[0]) {
				case Enum.One: return e[1];
				default: return null;
			}
		}
		Converted to:
		@:sf.unwrapper function useOne(e:Enum) {
			return e[1];
		}
		This is handy if you are making an enum index -> enum constructor handler mapper.
	**/
	private function applyUnwrap() {
		for (sfc in SfCore.sfGenerator.classList) {
			for (sff in sfc.fieldList) {
				if (!sff.meta.has(":sf.unwrapper")) continue;
				var pos = sff.classField.pos;
				switch (sff.kind) {
					case FMethod(_): {};
					default: Context.error("Can't apply :sf.unwrapper to vars", pos); continue;
				}
				var expr = sff.expr;
				if (expr == null) {
					Context.error("Can't apply :sf.unwrapper to functions with no body", pos);
					continue;
				}
				var unpacked = expr.unpack();
				switch (unpacked.def) {
					case SfIf(cond, then, _, _): {
						unpacked.def = then.def;
					};
					default: {
						Context.error(":sf.unwrapper functions can only have a one-case switch, got "
							+ unpacked.def.getName(), pos);
					};
				}
			}
		}
	}
	
	override public function apply() {
		applyIf();
		applyUnwrap();
	}
}
