package sf.type;
import haxe.macro.Context;
import haxe.macro.Type;

/**
 * ...
 * @author YellowAfterlife
 */
class SfAnonImpl extends SfType {
	public var defType:DefType;
	public var anonType:AnonType;
	public var fields:Array<SfClassField> = [];
	public function new(t:DefType, at:AnonType) {
		super(t);
		defType = t;
		anonType = at;
		for (f in at.fields) {
			fields.push(new SfClassField(this, f, true));
		}
		fields.sort(fieldSort);
	}
	private static function fieldSort(a:SfClassField, b:SfClassField) {
		return Context.getPosInfos(a.classField.pos).min - Context.getPosInfos(b.classField.pos).min;
	}
}
