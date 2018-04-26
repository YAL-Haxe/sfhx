package sf.type;
import haxe.macro.Type;

/**
 * ...
 * @author YellowAfterlife
 */
class SfVar {
	public var name:String;
	public var id:Int;
	public var type:Type;
	public function new(name:String, type:Type, ?id:Int) {
		this.name = SfCore.sfGenerator.getVarName(name);
		this.type = type;
		this.id = id;
	}
	public function clone() {
		return new SfVar(name, type, id);
	}
	public inline function equals(v:SfVar):Bool {
		return id != null ? id == v.id : name == v.name;
	}
	public static inline function fromTVar(tv:TVar) {
		return new SfVar(tv.name, tv.t, tv.id);
	}
	public function toString():String {
		return "SfVar(" + name + ":" + haxe.macro.TypeTools.toString(type) + ")";
	}
}
