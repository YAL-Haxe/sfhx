package sf.test;

/**
 * ...
 * @author YellowAfterlife
 */
class SfTestOptArg {
	public static function test(a:String, b:String = "?", ?c:String) {
		trace(a);
		trace(b);
		trace(c);
	}
	public static function main() {
		test("1");
		test("1", "2");
		test("1", "2", "3");
	}
	
}
