package;

/**
 * ...
 * @author YellowAfterlife
 */
#if (neko)
class SfEnumTools {
	private static inline function asValue<T>(q:EnumValue):SfEnumValue return cast q;
	public static inline function getParameter<T>(q:EnumValue, i:Int):Any {
		return asValue(q).args[i];
	}
	public static inline function setParameter<T>(q:EnumValue, i:Int, v:Any):Void {
		asValue(q).args[i] = v;
	}
	public static inline function getParameterCount<T>(q:EnumValue):Int {
		return neko.NativeArray.length(asValue(q).args);
	}
	public static function setTo<T:EnumValue>(q:T, v:T):Void {
		var qi = asValue(q);
		var vi = asValue(v);
		var vx = vi.args;
		if (vx != null) {
			qi.args = neko.NativeArray.sub(vx, 0, neko.NativeArray.length(vx));
		} else qi.args = null;
		qi.index = vi.index;
		qi.tag = vi.tag;
	}
}
private typedef SfEnumValue = {
	args: neko.NativeArray<Dynamic>,
	tag: Dynamic,
	index: Int
}
#elseif (cs)
class SfEnumTools {
	private static inline function asValue<T>(q:EnumValue):cs.internal.HxObject.ParamEnum {
		return cast q;
	}
	public static inline function getParameter<T>(q:EnumValue, i:Int):Any {
		return asValue(q).params[i];
	}
	public static inline function setParameter<T>(q:EnumValue, i:Int, v:Any):Void {
		asValue(q).params[i] = v;
	}
	public static inline function getParameterCount<T>(q:EnumValue):Int {
		return asValue(q).params.length;
	}
	public static function setTo<T:EnumValue>(q:T, v:T):Void {
		var qi = asValue(q);
		var vi = asValue(v);
		var vx = vi.params;
		if (vx != null) {
			qi.params = vx.copy();
		} else qi.params = null;
		qi.index = vi.index;
	}
}
//private typedef SfEnumValue = cs.internal.HxObject.ParamEnum;
/*private interface SfEnumValue {
	public var params:haxe.ds.Vector<Dynamic>;
	public var index:Int;
}*/
#else
class SfEnumTools {
	//private static inline function asValue<T>(q:EnumValue):SfEnumValue return cast q;
	public static inline function getParameter<T>(q:EnumValue, i:Int):Any {
		throw "Can't getParameter from " + q;
		//return asValue(q).args[i];
	}
	public static inline function setParameter<T>(q:EnumValue, i:Int, v:Any):Void {
		throw "Can't setParameter on " + q;
		//asValue(q).args[i] = v;
	}
	public static inline function getParameterCount<T>(q:EnumValue):Int {
		return 0;
		//return neko.NativeArray.length(asValue(q).args);
	}
	public static function setTo<T:EnumValue>(q:T, v:T):Void {
		trace(q);
		Sys.exit(0);
		/*var qi = asValue(q);
		var vi = asValue(v);
		var vx = vi.args;
		if (vx != null) {
			qi.args = neko.NativeArray.sub(vx, 0, neko.NativeArray.length(vx));
		} else qi.args = null;
		qi.index = vi.index;
		qi.tag = vi.tag;*/
	}
}
#end
