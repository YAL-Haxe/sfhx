package sf.test;

/**
 * ...
 * @author YellowAfterlife
 */@:native("test")
class SfTestFieldKinds {
	static var globalVar:Int = 0;
	static function globalFunc() trace("globalFunc");
	static dynamic function globalDyn() trace("globalDyn");
	//
	var instVar:Int = 0;
	function instFunc() trace("instFunc");
	dynamic function instDyn() trace("instDyn");
	//
	function new() { }
	//
	public static function main() {
		globalVar = 1;
		globalVar += 1;
		trace(globalVar);
		globalFunc();
		globalDyn();
		//
		var t = new SfTestFieldKinds();
		t.instVar = 1;
		t.instVar += 1;
		trace(t.instVar);
		t.instFunc();
		t.instDyn();
	}
}
