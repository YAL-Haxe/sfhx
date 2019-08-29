package sf;
import haxe.Timer;

/**
 * ...
 * @author YellowAfterlife
 */
class SfTimes {
	static var buf:StringBuf = new StringBuf();
	static var time:Float;
	static var name:String;
	public static function init() {
		time = Timer.stamp();
		name = "init";
		buf.add("Compile time breakdown:");
	}
	public static function mark(newName:String):Void {
		#if sf_times
		var t = Timer.stamp();
		var dt = Std.int((t - time) * 1000);
		buf.add(StringTools.lpad(Std.string(dt), " ", 5));
		buf.add("ms   ");
		buf.add(name);
		buf.add("\n");
		name = newName;
		time = t;
		#end
	}
	public static function finish() {
		#if sf_times
		mark("OK!");
		Sys.println(buf.toString());
		#end
	}
}
