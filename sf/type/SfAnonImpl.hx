package sf.type;
import haxe.ds.Map;
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
	public var fieldMap:Map<String, SfClassField> = new Map();
	public function new(t:DefType, at:AnonType) {
		super(t);
		defType = t;
		anonType = at;
		for (f in at.fields) {
			var sf = new SfClassField(this, f, true);
			fields.push(sf);
			fieldMap.set(sf.name, sf);
		}
		fields.sort(fieldSort);
	}
	private static function fieldSort(a:SfClassField, b:SfClassField) {
		return Context.getPosInfos(a.classField.pos).min - Context.getPosInfos(b.classField.pos).min;
	}
}
