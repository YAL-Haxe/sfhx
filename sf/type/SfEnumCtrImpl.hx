package sf.type;

import haxe.macro.Type;
import haxe.macro.Type.EnumField;

/**
 * ...
 * @author YellowAfterlife
 */
class SfEnumCtrImpl extends SfField {
	
	/** */
	public var enumField:EnumField;
	
	/** */
	public var parentEnum:SfEnum;
	
	/** Constructor index */
	public var index:Int;
	
	public function new(parent:SfEnum, field:EnumField) {
		super(parent, field);
		if (field.meta.has(":native")) {
			name = metaGetText(field.meta, ":native");
		}
		enumField = field;
		parentEnum = parent;
		index = field.index;
		switch (field.type) {
			case TFun(f_args, f_type): { // EnumField(...);
				isCallable = true;
				var sfArgs:Array<SfArgument> = [];
				for (f_arg in f_args) sfArgs.push(new SfArgument(
					new SfVar(f_arg.name, f_arg.t),
					f_arg.opt ? TNull : null
				));
				args = sfArgs;
				type = f_type;
			};
			default: { // EnumField;
				args = [];
			};
		}
	}
	
	override public function toString() {
		return parentEnum.name + "." + name;
	}
	
}
