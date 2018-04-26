package;

/**
 * ...
 * @author YellowAfterlife
 */
@:native("SfRest")
abstract SfRest<T>(Array<T>) {
	@:from static function create<T>(args:Array<T>):SfRest<T> {
		return cast args;
	}
	
	public var length(get, never):Int;
	private function get_length() {
		return this.length;
	}
	
	@:arrayAccess public function get(i:Int):T {
		return this[i];
	}
	public function set(i:Int, v:T) {
		this[i] = v;
	}
	@:arrayAccess private inline function arrayWrite(i:Int, v:T) {
		set(i, v);
		return v;
	}
}
