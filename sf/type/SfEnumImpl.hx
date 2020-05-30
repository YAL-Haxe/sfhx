package sf.type;

import haxe.ds.Vector;
import haxe.macro.Type.EnumType;
import haxe.macro.Type.MetaAccess;
import sf.type.SfBuffer;
import sf.type.SfType;
import sf.SfCore.*;

/**
 * ...
 * @author YellowAfterlife
 */
class SfEnumImpl extends SfType {
	
	/** */
	public var enumType:EnumType;
	
	/** Constructors */
	public var ctrList:Array<SfEnumCtr> = [];
	
	public var ctrMap:Map<String, SfEnumCtr> = new Map();
	public var realMap:Map<String, SfEnumCtr> = new Map();
	
	public var indexMap:Vector<SfEnumCtr>;
	
	/** Whether this is a "fake" enum, which can be replaced with indexes. */
	public var isFake:Bool;
	
	/** Whether to call constructors even if they don't have parameters. */
	public var noRef:Bool;
	
	override public function metaHandle(meta:MetaAccess, ndoc:String) {
		super.metaHandle(meta, ndoc);
		noRef = meta.has(":noRef");
	}
	
	private static function enumCtrSort(a:SfEnumCtr, b:SfEnumCtr) return a.index - b.index;
	
	public function new(t:EnumType) {
		super(t);
		enumType = t;
		var hasArgs:Bool = false;
		for (c in t.constructs) {
			var sfc = new SfEnumCtr(cast this, c);
			ctrList.push(sfc);
			ctrMap[sfc.name] = sfc;
			realMap[sfc.realName] = sfc;
			hasArgs = hasArgs || sfc.args.length > 0;
		}
		ctrList.sort(enumCtrSort);
		if (ctrList.length > 0) {
			indexMap = new Vector(ctrList.length);
			for (sfc in ctrList) {
				indexMap[sfc.index] = sfc;
			}
		}
		isFake = !hasArgs;
	}
	
	public function renameCtr(c:SfEnumCtr, newName:String) {
		var oldName = c.name;
		if (oldName == newName) return;
		ctrMap.remove(oldName);
		c.name = newName;
		ctrMap.set(newName, c);
	}
	
	override public function dumpTo(out:SfBuffer):Void {
		dumpMeta(out);
		if (isHidden) printf(out, "extern ");
		printf(out, "enum %s {", name);
		out.indent += 1;
		//
		for (ctr in ctrList) {
			printf(out, "\n%s", ctr.name);
			if (ctr.args.length > 0) {
				printf(out, "(");
				ctr.dumpArguments(out);
				printf(out, ")");
			}
			printf(out, ";");
		}
		//
		printf(out, "%(-\n)}");
	}
	
	override public function toString() return name;
}
