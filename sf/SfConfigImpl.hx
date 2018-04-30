package sf;
import haxe.macro.Context;

/**
 * ...
 * @author YellowAfterlife
 */
class SfConfigImpl {
	
	/** Output to second file */
	public var also:String = string("sf-also");
	
	/** Whether the target uses CustomJSGenerator */
	public var jsgen:Bool = bool("js");
	
	/** Reflects the usual -debug flag */
	public var debug:Bool = bool("debug");
	
	public var dump:String = {
		var s = string("sf-dump");
		switch (s) {
			case null: null;
			case "pre": s;
			default: "post";
		}
	};
	
	/** Whether to use sf-specific analyzer-like functions */
	public var analyzer:Bool = bool("sf-analyzer", !bool("analyzer"));
	
	/** Whether there should be hint-comments where appropriate */
	public var hint:Bool = bool("sf-hint", bool("debug"));
	
	/** Whether to add hint-comments for start/end of foldable sections */
	public var hintFolds:Bool = bool("sf-hint-folds", bool("debug"));
	
	/** Whether to include additional spacing for readability */
	public var pretty:Bool = bool("sf-pretty", bool("debug"));
	
	/** Whether to keep SfForEach */
	public var forEach:Bool = bool("sf-for-each", false);
	
	/** Whether to generate SfCFor */
	public var cfor:Bool = bool("sf-cfor", true);
	
	/** Whether to generate SfInstanceOf (as opposed to JS-specific checks) */
	public var instanceof:Bool = false;
	
	/** Optional container package for non-extern `@:std` classes*/
	public var stdPack:String = string("sf-std-package");
	
	/** Whether ternary operators are okay */
	public var ternary:Bool = true;
	
	public function new() {
		//
	}
	
	private static var value_1:Map<String, String> = new Map();
	private static function value(s:String):String {
		if (value_1.exists(s)) return value_1[s];
		var v = Context.definedValue(s);
		if (v != null) return v;
		// if things didn't work out, see if it's about dashes<->underscores:
		if (s.indexOf("-") >= 0) {
			v = Context.definedValue(StringTools.replace(s, "-", "_"));
		} else if (s.indexOf("_") >= 0) {
			v = Context.definedValue(StringTools.replace(s, "_", "-"));
		}
		value_1.set(s, v);
		return v;
	}
	
	public static function bool(name:String, def:Bool = false):Bool {
		var v = value(name);
		if (v != null) {
			return v != "0" && v != "false";
		} else return def;
	}
	
	public static function string(name:String, def:String = null):String {
		var v = value(name);
		if (v != null) return v; else return def;
	}
	
	public static function int(name:String, def:Int = 0):Int {
		var s = value(name);
		var v = s != null ? Std.parseInt(s) : null;
		return v != null ? v : def;
	}
}
