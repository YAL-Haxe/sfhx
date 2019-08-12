package sf.type.expr;

/**
 * ...
 * @author YellowAfterlife
 */
class SfExprImpl {
	public var data:SfExprData;
	public var def:SfExprDef;
	public function new(d:SfExprData, x:SfExprDef) {
		data = d;
		def = x;
	}
	public function getName():String {
		return def.getName();
	}
	public inline function mod(x:SfExprDef):SfExpr {
		return new SfExpr(data, x);
	}
	@:keep public function toString():String {
		return Std.string(def);
	}
}
