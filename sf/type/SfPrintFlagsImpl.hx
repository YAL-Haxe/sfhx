package sf.type;

/**
 * ...
 * @author YellowAfterlife
 */
abstract SfPrintFlagsImpl(Int) from Int to Int {
	
	/** Is an expression, as opposed to a statement */
	public static inline var Inline:SfPrintFlags = (1 << 0);
	
	/** Is wrapped (expr: in parenthesis, statement: in curly brackets) */
	public static inline var Wrapped:SfPrintFlags = (1 << 1);
	
	/** Shortcut for `expr` */
	public static inline var Expr:SfPrintFlags = Inline;
	
	/** Just a statement, such as in `if (x) stat` */
	public static inline var Stat:SfPrintFlags = 0;
	
	/** Shortcut for `(expr)` */
	public static inline var ExprWrap:SfPrintFlags = Inline.with(Wrapped);
	
	/** Shortcut for `{stat}` */
	public static inline var StatWrap:SfPrintFlags = Wrapped;
	
	public static inline var MaxBase:SfPrintFlags = (1 << 2);
	//
	public inline function isInline():Bool {
		return has(Inline);
	}
	public inline function isStat():Bool {
		return !has(Inline);
	}
	public inline function needsWrap():Bool {
		return !has(Wrapped);
	}
	//
	public inline function has(flag:SfPrintFlags):Bool {
		return (this & flag) != 0;
	}
	public function hasAll(flag:SfPrintFlags):Bool {
		return (this & flag) == flag;
	}
	//
	public inline function with(flag:SfPrintFlags):SfPrintFlags {
		return this | flag;
	}
	public inline function without(flag:SfPrintFlags):SfPrintFlags {
		return this & ~flag;
	}
}