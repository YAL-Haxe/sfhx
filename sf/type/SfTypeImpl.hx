package sf.type;

import haxe.macro.Type.BaseType;
import haxe.macro.Type.MetaAccess;
import sf.SfCore.printf;

/**
 * ...
 * @author YellowAfterlife
 */
class SfTypeImpl extends SfStruct {
	
	/** */
	public var baseType:BaseType;
	
	/** */
	public var module:String;
	
	public var realPath:String;
	
	/** Whether this is an extern type. */
	public var isExtern:Bool;
	
	/** Whether the structure has `@:nativeGen` meta */
	public var nativeGen:Bool;
	
	public function new(t:BaseType) {
		baseType = t;
		name = t.name;
		pack = t.pack;
		module = t.module;
		isExtern = t.isExtern;
		if (isExtern) isHidden = true;
		meta = t.meta;
		nativeGen = meta.has(":nativeGen");
		realPath = metaGetText(meta, ":realPath");
		if (realPath == null) {
			var b = new SfBuffer();
			b.addTypePath(cast this, ".".code);
			realPath = b.toString();
		}
		metaHandle(meta, t.doc);
	}
	
	public inline function hasMeta(name:String) {
		return baseType.meta.has(name);
	}
	
	override public function metaHandle(meta:MetaAccess, ndoc:String) {
		super.metaHandle(meta, ndoc);
		if (!isExtern && meta.has(":std")) {
			var pkg = SfCore.sfConfig.stdPack;
			if (pkg != null) pack.unshift(pkg);
		}
	}
	
	/** Should output the structyure into the given buffer. */
	public function printTo(out:SfBuffer, init:SfBuffer):Void {
		//
	}
	
	private function dumpMeta(out:SfBuffer):Void {
		printf(out, "// %s:%s\n", baseType.module, baseType.name);
		var metas = baseType.meta.get();
		if (metas.length > 0) {
			SfDump.meta(metas, out); printf(out, "\n");
		}
	}
	
	override public function dumpTo(out:SfBuffer):Void {
		dumpMeta(out);
		if (isHidden) printf(out, "extern ");
		printf(out, "typedef ");
		out.addTypePath(cast this);
		printf(out, " { }");
	}
	
}
