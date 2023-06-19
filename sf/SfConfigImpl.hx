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
			case "": "post";
			default: s;
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
	
	/** Are variables only available in their block (like `let` in JS)? */
	public var blockScoping:Bool = false;
	
	/** Whether to generate SfInstanceOf (as opposed to JS-specific checks) */
	public var instanceof:Bool = false;
	
	public var useBootError:Bool = false;
	
	/** Optional container package for non-extern `@:std` classes*/
	public var stdPack:String = string("sf-std-package");
	
	/** Whether ternary operators are okay */
	public var ternary:Bool = true;
	
	public function new() {
		//
	}
	
	public static function value(s:String):String {
		var v = Context.definedValue(s);
		if (v != null) return v;
		// if things didn't work out, see if it's about dashes<->underscores:
		if (s.indexOf("-") >= 0) {
			v = Context.definedValue(StringTools.replace(s, "-", "_"));
		} else if (s.indexOf("_") >= 0) {
			v = Context.definedValue(StringTools.replace(s, "_", "-"));
		}
		return v;
	}
	
	public static function bool(name:String, ?def:Bool):Bool {
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
	
	/**
	 * ("1.4", "2.0") -> -1
	 * ("2.3.4", "2.3") -> 1
	 * ("2.3.1", "2.3.1") -> 0
	 */
	public static function compare(a:String, b:String):Int {
		if (a == null) a = "";
		if (b == null) b = "";
		var aw = a.split(".");
		var bw = b.split(".");
		var an = aw.length;
		var bn = bw.length;
		for (i in 0 ... (an < bn ? an : bn)) {
			var ac = Std.parseInt(aw[i]); if (ac == null) ac = 0;
			var bc = Std.parseInt(bw[i]); if (bc == null) bc = 0;
			if (ac != bc) return ac < bc ? -1 : 1;
		}
		return (an != bn) ? (an < bn ? -1 : 1) : 0;
	}
}
