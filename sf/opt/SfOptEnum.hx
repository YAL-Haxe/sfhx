package sf.opt;

import sf.opt.SfOptImpl;
import sf.type.SfExprDef.*;
import sf.type.*;
import haxe.macro.Type;
using sf.type.SfExprTools;

/**
 * Enum-related transformations.
 * @author YellowAfterlife
 */
class SfOptEnum extends SfOptImpl {
	
	override public function apply() {
		// `fakeEnum[0]` -> `fakeEnum`:
		forEachExpr(function(e, w, f) {
			e.iter(w, f);
			switch (e.def) {
				case SfArrayAccess(x, i): {
					switch (x.getType()) {
						case TEnum(_et, _)
							|TAbstract(_, [TEnum(_et, _)]) // subject of dispute
						: {
							var et = _et.get();
							var sfEnum = SfCore.sfGenerator.enumMap.baseGet(et);
							if (sfEnum == null) x.error("Could not find enum " + et.name);
							if (sfEnum.isFake) switch (i.unpack().def) {
								case SfConst(TInt(
								// Type.enumIndex controls how enum index is pulled out of exprs.
								#if (gml) 0 #else 1 #end
								)): {
									e.setTo(x.def);
									e.setType(x.getType());
								};
								default: {
									var b = new SfBuffer();
									SfDump.expr(i.unpack(), b);
									x.error("SfOptEnum: Can't access non-index of fake enums: "
									+ b.toString());
								}
							} else e.setTo(SfEnumAccess(x, sfEnum, i));
						}
						default:
					}
				};
				default:
			}
		});
		// `Type.createEnumIndex(FakeEnum, index, null)` -> `index`
		var _Type:SfClass = cast SfCore.sfGenerator.realMap["Type"];
		var _Type_createEnumIndex = _Type != null ? _Type.staticMap["createEnumIndex"] : null;
		if (_Type_createEnumIndex != null) forEachExpr(function(e, w, f) {
			e.iter(w, f);
			switch (e.def) {
				case SfCall(_.def => SfStaticField(c, f), [
					_.def => SfTypeExpr(t),
					ci,
					_.def => SfConst(TNull)
				]) if (c == _Type && f == _Type_createEnumIndex && Std.is(t, SfEnum)): {
					var et:SfEnum = cast t;
					if (et.isFake) {
						e.setTo(ci.def);
					}
				};
				default:
			}
		});
		//
	}
	
}
