package;
import haxe.macro.Context;
import haxe.macro.Expr;
using haxe.macro.ExprTools;

/**
 * ...
 * @author YellowAfterlife
 */
@:noCompletion
class ArrayObject {
	public static function build(?type:Expr):Array<Field> {
		if (type.expr.match(EConst(CIdent("null")))) type = null;
		switch (Context.getLocalType()) {
			case TEnum(_, _): return buildEnum(type);
			case TAbstract(_, _), TInst(_, _): return buildAbstract(type);
			default: {
				Context.error("ArrayObject must be applied to abstract or enum.", Context.currentPos());
				return null;
			}
		}
	}
	private static function buildEnum(tx:Expr):Array<Field> {
		var fields = Context.getBuildFields();
		var pos = Context.currentPos();
		switch (Context.getType(tx.toString())) {
			case TAbstract(_.get() => t, _): {
				for (f in t.impl.get().statics.get()) // all fields are static in enum impls
				if (f.name != "sizeof") switch (f.kind) {
					case FVar(AccNormal, AccNormal), FVar(AccCall, AccCall): {
						fields.push({
							name: f.name,
							kind: FVar(null, null),
							pos: pos
						});
					};
					default:
				}
			};
			default:
		};
		return fields;
	}
	private static function buildAbstract(indexType:Expr):Array<Field> {
		var fields:Array<Field> = Context.getBuildFields();
		//
		var nextIndex:Int = 0;
		var sizeField:Field = null;
		var ctrField:Field = null;
		var fieldIt = -1;
		var initExprs:Array<Expr> = [];
		while (++fieldIt < fields.length) {
			var field:Field = fields[fieldIt];
			var fname = field.name;
			switch (fname) {
				case "sizeof": sizeField = field; continue;
				case "_new": ctrField = field; continue;
			}
			var fpos = field.pos;
			switch (field.kind) {
				case FVar(t, val): {
					field.kind = FProp("get", "set", t);
					for (it in 0 ... 2) {
						var set = it > 0, ix:Expr, nimpl:Expr;
						if (indexType != null) {
							ix = { expr: EField(indexType, fname), pos: fpos };
						} else ix = { expr: EConst(CInt(Std.string(nextIndex))), pos: fpos };
						if (set) {
							nimpl = macro { set($ix, v); return v; };
						} else nimpl = macro return get($ix);
						var nfunc:Function = {
							args: set ? [{ name: "v", type: t }] : [],
							ret: t, expr: nimpl
						};
						var nfield:Field = {
							name: (set ? "set_" : "get_") + fname,
							access: [APrivate, AInline],
							kind: FFun(nfunc),
							pos: fpos,
						};
						fields.insert(fieldIt + it + 1, nfield);
					} // for (it)
					if (val != null && !val.expr.match(EConst(CIdent("null")))) {
						initExprs.push(macro $i{"set_" + fname}($val));
					}
					nextIndex += 1;
				}; // case FVar
				default:
			} // switch (field.kind)
		} // for (field in fields)
		//
		if (initExprs.length == 0) {
			// OK!
		} else if (ctrField == null) {
			Context.error("Abstract has no constructor?", Context.getLocalClass().get().pos);
		} else switch (ctrField.kind) {
			case FFun(f): {
				// append initializers after `this = ...` in constructor:
				var found = false;
				f.expr = haxe.macro.ExprTools.map(f.expr, function(e:Expr):Expr {
					if (e.expr.match(EBinop(OpAssign, _.expr => EConst(CIdent("this")), _))) {
						found = true;
						return {
							expr: EBlock([e].concat(initExprs)),
							pos: e.pos
						};
					} else return e;
				});
				if (!found) Context.error("Constructor does not assign `this`..?", ctrField.pos);
			};
			default: Context.error("Unexpected kind for constructor: " + ctrField.kind, ctrField.pos);
		}
		//
		if (sizeField != null) switch (sizeField.kind) {
			case FVar(t, _): {
				sizeField.kind = FVar(t, {
					expr: EConst(CInt(Std.string(nextIndex))),
					pos: sizeField.pos,
				});
				if (sizeField.access.indexOf(AInline) < 0) sizeField.access.push(AInline);
			};
			default:
		}
		//
		return fields;
	}
}

/*// Sample 1
 * import haxe.ds.Vector;
class Test {
	static function main() {
		var q = new TestAbstract();
		trace(q.some);
		q.etc = "hi";
	}
}

@:build(ArrayObject.build())
abstract TestAbstract(Vector<Any>) {
	static inline var sizeof:Int = 0;
	public var some:Int;
	public var etc:String;
	public function new() this = new Vector(sizeof);
	public inline function get(i:Int) return this[i];
	public inline function set(i:Int, v:Any) this[i] = v;
}
*/
/*// Sample 2
import haxe.ds.Vector;
class Test {
	static function main() {
		var q = new TestAbstract();
		trace(q.some);
	}
}

@:build(ArrayObject.build(TestEnum))
abstract TestAbstract(Vector<Dynamic>) {
	static inline var sizeof:Int = 1;
	public var some:Int;
	public function new() {
		this = new Vector(sizeof);
	}
	public inline function get(i:TestEnum) return this[i.getIndex()];
	public inline function set(i:TestEnum, v:Any) this[i.getIndex()] = v;
}
@:build(ArrayObject.build(TestAbstract))
@:fakeEnum(Int) enum TestEnum { }
*/
