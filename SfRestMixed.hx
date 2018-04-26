package;

/**
 * ...
 * @author YellowAfterlife
 */
@:access(SfRest.create) @:forward
abstract SfRestMixed(SfRest<Dynamic>) {
	@:from static inline function create(args:Array<Dynamic>):SfRestMixed {
		return cast args;
	}
	@:arrayAccess inline function get(i:Int):Dynamic return this.get(i);
	@:arrayAccess inline function arrayWrite(i:Int, v:Dynamic):Dynamic {
		this.set(i, v);
		return v;
	}
}
