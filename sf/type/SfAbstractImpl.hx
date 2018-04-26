package sf.type;

import haxe.macro.Type.AbstractType;
import sf.type.SfBuffer;
import sf.type.SfType;
import sf.SfCore.printf;

/**
 * ...
 * @author YellowAfterlife
 */
class SfAbstractImpl extends SfType {
	public var abstractType:AbstractType;
	public var impl:SfClass;
	public function new(t:AbstractType) {
		super(t);
		abstractType = t;
	}
	
	override public function dumpTo(out:SfBuffer):Void {
		var at = abstractType;
		dumpMeta(out);
		if (isHidden) printf(out, "extern ");
		if (abstractType.isPrivate) printf(out, "private ");
		printf(out, "abstract ");
		out.addTypePath(this);
		printf(out, "(");
		SfDump.type(at.type, out);
		printf(out, ") {");
		out.indent += 1;
		var start = out.length;
		//
		
		//
		if (out.length > start) {
			printf(out, "%(-\n)");
		} else {
			printf(out, " ");
			out.indent -= 1;
		}
		printf(out, "}\n");
	}
}
