package sf.type;

import haxe.macro.Type;
import haxe.macro.Type.ClassType;
import sf.type.SfBuffer;
import sf.SfCore.printf;

/**
 * ...
 * @author YellowAfterlife
 */
class SfClassImpl extends SfType {
	
	/** */
	public var classType:ClassType;
	
	/** */
	public var superClass:SfClass = null;
	
	public var children:Array<SfClass> = [];
	
	public var fieldList:Array<SfClassField> = [];
	
	public var fieldMap:Map<String, SfClassField> = new Map();
	
	/** Static fields */
	public var staticList:Array<SfClassField> = [];
	
	/** */
	public var staticMap:Map<String, SfClassField> = new Map();
	
	/** Instance fields */
	public var instList:Array<SfClassField> = [];
	
	/** */
	public var instMap:Map<String, SfClassField> = new Map();
	
	/** original name -> class field */
	public var realMap:Map<String, SfClassField> = new Map();
	
	/** Constructor field (if any) */
	public var constructor:SfClassField = null;
	
	/** __init__ expression, if any */
	public var init:SfExpr = null;
	
	/** */
	public var typedInit:TypedExpr;
	
	/** Whether this is a :final class */
	public var isFinal:Bool;
	
	public function new(t:ClassType) {
		super(t);
		var self:SfClass = cast(this, SfClass);
		classType = t;
		for (f in t.statics.get()) addField(new SfClassField(self, f, false));
		for (f in t.fields.get()) addField(new SfClassField(self, f, true));
		if (t.constructor != null) {
			constructor = new SfClassField(cast this, t.constructor.get(), false);
		}
		typedInit = t.init;
	}
	
	public function addField(field:SfClassField) {
		fieldList.push(field);
		fieldMap.set(field.name, field);
		if (field.isInst) {
			instList.push(field);
			instMap.set(field.name, field);
		} else {
			staticList.push(field);
			staticMap.set(field.name, field);
		}
		realMap.set(field.realName, field);
	}
	
	public function addFieldBefore(field:SfClassField, ref:SfClassField) {
		var pos:Int;
		inline function findPos(arr:Array<SfClassField>) {
			pos = arr.indexOf(ref);
			if (pos < 0) pos = arr.length;
		}
		findPos(fieldList);
		fieldList.insert(pos, field);
		fieldMap.set(field.name, field);
		if (field.isInst) {
			findPos(instList);
			instList.insert(pos, field);
			instMap.set(field.name, field);
		} else {
			findPos(staticList);
			staticList.insert(pos, field);
			staticMap.set(field.name, field);
		}
		realMap.set(field.realName, field);
	}
	
	public function removeField(field:SfClassField) {
		if (field == null) return;
		if (fieldList.remove(field)) fieldMap.remove(field.name);
		if (field.isInst) {
			if (instList.remove(field)) instMap.remove(field.name);
		} else {
			if (staticList.remove(field)) staticMap.remove(field.name);
		}
	}
	
	public function renameField(field:SfClassField, newName:String) {
		var oldName = field.name;
		if (oldName == newName) return;
		fieldMap.remove(oldName);
		(field.isInst ? instMap : staticMap).remove(oldName);
		field.name = newName;
		fieldMap.set(newName, field);
		(field.isInst ? instMap : staticMap).set(newName, field);
	}
	
	override public function dumpTo(out:SfBuffer):Void {
		dumpMeta(out);
		if (isHidden) printf(out, "extern ");
		if (classType.isPrivate) printf(out, "private ");
		printf(out, "%s", classType.isInterface ? "interface " : "class ");
		out.addTypePath(this);
		if (superClass != null) { printf(out, " extends "); out.addTypePath(superClass); }
		printf(out, " {");
		var ctr = constructor;
		if (fieldList.length > 0 || ctr != null) {
			out.indent += 1;
			out.addLine();
			var sep = false;
			if (ctr != null) {
				ctr.dumpTo(out);
				sep = true;
			}
			for (f in fieldList) {
				if (sep) out.addLine(); else sep = true;
				f.dumpTo(out);
			}
			out.indent -= 1;
			out.addLine();
		} else printf(out, " ");
		printf(out, "}");
	}
}
