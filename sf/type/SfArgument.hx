package sf.type;
import haxe.macro.Type;

/**
 * @author YellowAfterlife
 */
class SfArgument {
	public var v:SfVar;
	public var value:TConstant;
	public function new(v:SfVar, ?value:TConstant) {
		this.v = v;
		this.value = value;
	}
	public static function fromTyped(a:SfArgumentRaw) {
		#if (haxe_ver <= "4.0.0-preview.4")
		return new SfArgument(SfVar.fromTVar(a.v), a.value);
		#else
		var val:TConstant = null;
		var vx:TypedExpr = a.value;
		if (vx != null) switch (vx.expr) {
			case TConst(c): val = c;
			default: {};
		}
		return new SfArgument(SfVar.fromTVar(a.v), val);
		#end
	}
}
#if (haxe_ver <= "4.0.0-preview.4")
private typedef SfArgumentRaw = {v:TVar, value:Null<TConstant>};
#else
private typedef SfArgumentRaw = {v:TVar, value:Null<TypedExpr>};
#end
