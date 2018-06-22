package sf.type;

import haxe.macro.Type;
import sf.SfCore.*;

/**
 * ...
 * @author YellowAfterlife
 */
class SfFieldImpl extends SfStruct {
	
	/** */
	public var typeField:TypeField;
	
	/** The type that this field resides in */
	public var parentType:SfType;
	
	/** Field type (return type if callable) */
	public var type:Type;
	
	/** Arguments (if callable) */
	public var args:Array<SfArgument> = null;
	
	/** Where the rest-argument starts */
	public var restOffset:Int = 0;
	
	/** Whether this is a callable field/constructor */
	public var isCallable:Bool = false;
	
	public function new(t:SfType, f:TypeField) {
		typeField = f;
		parentType = t;
		name = f.name;
		pack = t.pack;
		type = f.type;
		meta = f.meta;
		metaHandle(f.meta, f.doc);
	}
	
	public function dumpArguments(out:SfBuffer):Void {
		for (i in 0 ... args.length) {
			if (i > 0) out.addString(", ");
			var v = args[i].v;
			printf(out, "%s:", v.name); SfDump.type(v.type, out);
		}
	}
}

typedef TypeField = {
	var name:String;
	var type:Type;
	var doc:Null<String>;
	var pos:haxe.macro.Expr.Position;
	var meta:MetaAccess;
}
