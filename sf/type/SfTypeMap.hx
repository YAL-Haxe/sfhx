package sf.type;

import haxe.macro.Type;

/**
 * Allows to quickly locate the structures by module + name.
 * @author YellowAfterlife
 */
abstract SfTypeMap<T>(Map<String, Map<String, T>>) {
	public inline function new() {
		this = new Map();
	}
	public inline function exists(module:String, name:String):Bool {
		var map = this.get(module);
		return map != null ? map.exists(name) : false;
	}
	public inline function get(module:String, name:String):T {
		var map = this.get(module);
		return map != null ? map[name] : null;
	}
	public function safeGet(module:String, name:String):T {
		var map = this.get(module);
		if (map != null && map.exists(name)) {
			return map.get(name);
		}
		throw "Could not find " + module + ":" + name;
	}
	public inline function set(module:String, name:String, value:T):Void {
		var map = this.get(module);
		if (map == null) this[module] = map = new Map();
		map[name] = value;
	}
	//
	public inline function baseGet(t:BaseType):T {
		return get(t.module, t.name);
	}
	public inline function baseSet(t:BaseType, v:T):Void {
		set(t.module, t.name, v);
	}
	public inline function baseExists(t:BaseType):Bool {
		return exists(t.module, t.name);
	}
	//
	public inline function sfGet(t:SfType):T {
		return get(t.module, t.name);
	}
	public inline function sfSet(t:SfType, v:T):Void {
		set(t.module, t.name, v);
	}
	public function forEach(fn:String->String->T->Void):Void {
		for (k1 in this.keys()) {
			var m = this[k1];
			for (k2 in m.keys()) {
				fn(k1, k2, m[k2]);
			}
		}
	}
}
