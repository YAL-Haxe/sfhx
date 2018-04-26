package sf.test;

/**
 * ...
 * @author YellowAfterlife
 */
class SfTestInheritance {
	public static function main() {
		var par = new Par(0);
		par.test();
		par.over();
		var chi = new Chi(1, 2);
		chi.test();
		chi.test2();
		chi.over();
	}
}

class Par {
	public var one:Int;
	public function new(o:Int) {
		one = o;
	}
	public function test() {
		trace(one);
	}
	public function over() {
		trace("?");
	}
}

class Chi extends Par {
	var two:Int;
	public function new(o:Int, t:Int = 1) {
		super(o);
		two = t;
	}
	public function test2() {
		trace(one + " " + two);
	}
	override public function over() {
		super.over();
		trace("!");
	}
}

