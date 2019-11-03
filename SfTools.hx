package;
import haxe.macro.Context;
import haxe.macro.Expr;

/**
 * ...
 * @author YellowAfterlife
 */
class SfTools {
	
	/// C-style for-loop. Uses @pleclech's idea but on macros level.
	public static macro function cfor(init, cond, post, expr) {
		#if !display
		var func = null;
		func = function(expr:haxe.macro.Expr) {
			return switch (expr.expr) {
			case EContinue: macro { $post; $expr; }
			case EWhile(_, _, _): expr;
			case ECall(macro cfor, _): expr;
			case EFor(_): expr;
			//case EIn(_): expr;
			default: haxe.macro.ExprTools.map(expr, func);
			}
		}
		expr = func(expr);
		#end
		return macro @:pos(Context.currentPos()) {
			$init;
			while ($cond) {
				$expr;
				$post;
			}
		};
	}
	
	/** Shorthand enum matching. */
	public static macro function ematch(expr:Expr, match:Expr, then:Expr, ?not:Expr) {
		if (not == null) not = { expr: null, pos: null }; // macro { };
		return macro @:pos(Context.currentPos())
		switch ($expr) {
			case $match: $then;
			default: $not;
		}; 
	}
	
	public static macro function enmatch(expr:Expr, match:Expr, not:Expr, ?then:Expr) {
		if (then == null) then = macro { };
		return macro @:pos(Context.currentPos())
		switch ($expr) {
			case $match: $then;
			default: $not;
		}
	}
	
	/** raw("code", ...args) */
	public static macro function raw(e:Array<Expr>):ExprOf<Dynamic> {
		var pos = Context.currentPos();
		if (e.length < 1) Context.error("raw() requires at least one argument.", pos);
		var raw = macro @:pos(pos) untyped __raw__;
		return { expr: ECall(raw, e), pos: pos };
	}
	
}
