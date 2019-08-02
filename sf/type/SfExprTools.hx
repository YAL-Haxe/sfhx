package sf.type;
import haxe.EnumTools;
#if (macro)
import haxe.macro.Context;
#end
import haxe.macro.Expr.Position;
import haxe.macro.Type;
import haxe.macro.Type.TypedExprDef.*;
import sf.type.SfExpr.SfExprData;
import sf.type.SfExpr;
import haxe.macro.Expr.Binop;
import haxe.macro.Expr.Unop;
import sf.type.SfExprDef.*;
import sf.SfCore.*;
import SfTools.*;
using sf.type.SfExprTools;

/**
 * Provides a number of functions to aid with pattern matching, checking, and iterating.
 * It's full of `switch`es.
 * @author YellowAfterlife
 */
class SfExprTools {
	/** Makes a deep copy of an expression. */
	public static function clone(expr:SfExpr):SfExpr {
		var d = getData(expr);
		inline function f(e:SfExpr):SfExpr {
			return clone(e);
		}
		var i:Int, n:Int, fxw:Array<SfExpr>, fxr:Array<SfExpr>;
		inline function fx(w:Array<SfExpr>):Array<SfExpr> {
			fxw = w; n = fxw.length; fxr = [];
			i = 0; while (i < n) {
				fxr.push(fxw[i].clone());
				i += 1;
			}
			return fxr;
		}
		var nd:SfExprDef = switch (expr.def) {
			case SfConst(c): SfConst(switch (c) {
				case TBool(b): TBool(b);
				case TInt(i): TInt(i);
				case TFloat(s): TFloat(s);
				case TString(s): TString(s);
				case TThis: TThis;
				case TNull: TNull;
				case TSuper: TSuper;
			});
			case SfLocal(v): SfLocal(v.clone());
			case SfDynamic(s, w): SfDynamic(s, fx(w));
			case SfUnop(o, p, x): SfUnop(o, p, f(x));
			case SfArrayAccess(o, i): SfArrayAccess(f(o), f(i));
			case SfInstField(o, i): SfInstField(f(o), i);
			case SfStaticField(c, _fd): SfStaticField(c, _fd);
			case SfDynamicField(o, s): SfDynamicField(f(o), s);
			case SfCall(x, w): SfCall(f(x), fx(w));
			case SfIf(x1, x2, z, x3): SfIf(f(x1), f(x2), z, f(x3));
			case SfParenthesis(x): SfParenthesis(f(x));
			case SfBinop(o, a, b): SfBinop(o, f(a), f(b));
			default: expr.error("SfExprTools.clone: Can't clone " + expr.getName());
		}
		return expr.mod(nd);
	}
	
	/** Provides tools for iterating on expressions. */
	public static function iter(expr:SfExpr, stack:Array<SfExpr>, func:SfExprIter):Void {
		if (stack != null) stack.unshift(expr);
		inline function f0():Void { };
		inline function f1(e:SfExpr):Void {
			func(e, stack, func);
		}
		inline function f2(e1:SfExpr, e2:SfExpr):Void {
			func(e1, stack, func);
			func(e2, stack, func);
		}
		function fx(w:Array<SfExpr>):Void {
			for (e in w) func(e, stack, func);
		}
		switch (expr.def) {
			case SfConst(_): f0();
			case SfLocal(_): f0();
			case SfDynamic(_, w): fx(w);
			case SfArrayAccess(a, i): f2(a, i);
			case SfEnumAccess(a, _, i): f2(a, i);
			case SfEnumParameter(e, _, _): f1(e);
			case SfBinop(_, a, b): f2(a, b);
			case SfStrictEq(a, b): f2(a, b);
			case SfInstField(o, _): f1(o);
			case SfClosureField(o, _): f1(o);
			case SfStaticField(_, _): f0();
			case SfDynamicField(o, _): f1(o);
			case SfEnumField(_, _): f0();
			case SfTypeExpr(_): f0();
			case SfParenthesis(e): f1(e);
			case SfObjectDecl(w): for (o in w) f1(o.expr);
			case SfArrayDecl(w): fx(w);
			case SfCall(e, w): f1(e); fx(w);
			case SfTrace(_, w): fx(w);
			case SfNew(_, _, w): fx(w);
			case SfUnop(_, _, e): f1(e);
			case SfFunction(o): f1(o.expr);
			case SfVarDecl(_, z, e): if (z) f1(e);
			case SfBlock(w): fx(w);
			case SfIf(c, a, z, b): f2(c, a); if (z) f1(b);
			case SfWhile(c, e, _): f2(c, e);
			case SfCFor(a, b, c, d): f2(a, b); f2(c, d);
			case SfForEach(_, o, e): f2(o, e);
			case SfSwitch(e, w, z, d): f1(e); for (o in w) f1(o.expr); if (z) f1(d);
			case SfTry(e, w): f1(e); for (o in w) f1(o.expr);
			case SfReturn(z, e): if (z) f1(e);
			case SfBreak: f0();
			case SfContinue: f0();
			case SfThrow(e): f1(e);
			case SfCast(e, _): f1(e);
			case SfTypeOf(e): f1(e);
			case SfInstanceOf(e, t): f2(e, t);
			case SfMeta(_, e): f1(e);
		}
		if (stack != null) stack.shift();
	}
	
	public static function matchIter(expr:SfExpr, stack:Array<SfExpr>, func:SfExprMatchIter):Bool {
		if (stack != null) stack.unshift(expr);
		inline function f0() return false;
		inline function f1(e:SfExpr) return func(e, stack, func);
		inline function f2(e1:SfExpr, e2:SfExpr) {
			return func(e1, stack, func) || func(e2, stack, func);
		}
		var fxw:Array<SfExpr>, i:Int, n:Int;
		inline function fx(w:Array<SfExpr>):Bool {
			fxw = w;
			n = fxw.length;
			i = 0;
			while (i < n) {
				if (func(fxw[i], stack, func)) break;
				i += 1;
			}
			return i < n;
		}
		var out:Bool = switch (expr.def) {
			case SfConst(_): f0();
			case SfLocal(_): f0();
			case SfDynamic(_, w): fx(w);
			case SfArrayAccess(a, i): f2(a, i);
			case SfEnumAccess(a, _, i): f2(a, i);
			case SfEnumParameter(e, _, _): f1(e);
			case SfBinop(_, a, b): f2(a, b);
			case SfStrictEq(a, b): f2(a, b);
			case SfInstField(o, _): f1(o);
			case SfClosureField(o, _): f1(o);
			case SfStaticField(_, _): f0();
			case SfDynamicField(o, _): f1(o);
			case SfEnumField(_, _): f0();
			case SfTypeExpr(_): f0();
			case SfParenthesis(e): f1(e);
			case SfObjectDecl(w): {
				n = w.length;
				i = 0; while (i < n) {
					if (f1(w[i].expr)) break;
					i += 1;
				}
				i < n;
			}
			case SfArrayDecl(w): fx(w);
			case SfCall(e, w): f1(e) || fx(w);
			case SfTrace(_, w): fx(w);
			case SfNew(_, _, w): fx(w);
			case SfUnop(_, _, e): f1(e);
			case SfFunction(o): f1(o.expr);
			case SfVarDecl(_, z, e): z && f1(e);
			case SfBlock(w): fx(w);
			case SfIf(c, a, z, b): f2(c, a) || (z && f1(b));
			case SfWhile(c, e, _): f2(c, e);
			case SfCFor(a, b, c, d): f2(a, b) || f2(c, d);
			case SfForEach(_, o, e): f2(o, e);
			case SfSwitch(e, w, z, d): {
				if (f1(e)) {
					true;
				} else {
					n = w.length;
					i = 0; while (i < n) {
						if (f1(w[i].expr)) break;
						i += 1;
					}
					i < n || (z && f1(d));
				}
			};
			case SfTry(e, w): {
				if (f1(e)) {
					true;
				} else {
					n = w.length;
					i = 0; while (i < n) {
						if (f1(w[i].expr)) break;
						i += 1;
					}
					i < n;
				}
			};
			case SfReturn(z, e): z && f1(e);
			case SfBreak: f0();
			case SfContinue: f0();
			case SfThrow(e): f1(e);
			case SfCast(e, _): f1(e);
			case SfTypeOf(e): f1(e);
			case SfInstanceOf(e, t): f2(e, t);
			case SfMeta(_, e): f1(e);
		}
		if (stack != null) stack.shift();
		return out;
	}
	
	public static function dump(expr:SfExpr):String {
		var buf = new SfBuffer();
		SfDump.expr(expr, buf);
		return buf.toString();
	}
	
	/** Recursively checks expression equality: */
	public static function equals(expr:SfExpr, other:SfExpr):Bool {
		inline function f(a:SfExpr, b:SfExpr):Bool return equals(a, b);
		inline function fi(a:EnumValue, b:EnumValue):Bool {
			return EnumValueTools.getIndex(a) == EnumValueTools.getIndex(b);
		}
		var l1:Array<SfExpr>, l2:Array<SfExpr>, i:Int, n:Int;
		inline function fx(a:Array<SfExpr>, b:Array<SfExpr>) {
			l1 = a;
			l2 = b;
			n = l1.length;
			if (n == l2.length) {
				i = 0;
				while (i < n) if (f(l1[i], l2[i])) {
					i++;
				} else break;
				return i >= n;
			} else return false;
		}
		return if (fi(expr.def, other.def)) switch ([expr.def, other.def]) {
			case [SfConst(c1), SfConst(c2)]: {
				if (fi(c1, c2)) switch ([c1, c2]) {
					case [TInt(i1), TInt(i2)]: i1 == i2;
					case [TFloat(s1), TFloat(s2)]: s1 == s2;
					case [TString(s1), TString(s2)]: s1 == s2;
					case [TBool(b1), TBool(b2)]: b1 == b2;
					case [TNull, TNull]: true;
					case [TThis, TThis]: true;
					case [TSuper, TSuper]: true;
					default: error(expr, "SfExprTools.equals: Can't compare " + c1.getName());
				} else false;
			};
			case [SfLocal(v1), SfLocal(v2)]: v1.name == v2.name;
			case [SfDynamic(s1, l1), SfDynamic(s2, l2)]: s1 == s2 && fx(l1, l2);
			case [SfArrayAccess(a1, i1), SfArrayAccess(a2, i2)]: f(a1, a2) && f(i1, i2);
			case [SfEnumAccess(a1, _, i1), SfEnumAccess(a2, _, i2)]: f(a1, a2) && f(i1, i2);
			//
			case [SfStaticField(c1, f1), SfStaticField(c2, f2)]: c1 == c2 && f1 == f2;
			case [SfInstField(q1, f1), SfInstField(q2, f2)]: f(q1, q2) && f1 == f2;
			//
			case [SfBinop(o1, a1, b1), SfBinop(o2, a2, b2)]: {
				if (fi(o1, o2) && f(a1, a2) && f(b1, b2)) switch ([o1, o2]) {
					case [OpAssignOp(q1), OpAssignOp(q2)]: fi(q1, q2);
					default: true;
				} else false;
			};
			//
			case [SfUnop(o1, p1, e1), SfUnop(o2, p2, e2)]: p1 == p2 && fi(o1, o2) && f(e1, e2);
			default: error(expr, "SfExprTools.equals: Can't compare " + expr.getName());
		} else false;
	}
	
	/** Returns whether an expression contains another expression anywhere in it. */
	public static function contains(expr:SfExpr, child:SfExpr):Bool {
		function q(e:SfExpr, w, f) {
			if (e == child) return true;
			return e.matchIter(w, f);
		}
		return q(expr, null, q);
	}
	
	/** Finds the base of the given type. */
	public static inline function resolve(t:Type):Type {
		while (t != null) switch (t) {
			case TType(_.get() => dt, _): {
				t = dt.type;
			}
			default: break;
		}
		return t;
	}
	
	public static inline function typeHasMeta(t:Type, m:String):Bool {
		return switch (t) {
			case TInst(_.get() => q, _): q.meta.has(m);
			case TEnum(_.get() => q, _): q.meta.has(m);
			case TAbstract(_.get() => q, _): q.meta.has(m);
			default: false;
		}
	}
	
	public static function typeEquals(t1:Type, t2:Type, ?pos:Position):Bool {
		if (t1.getIndex() != t2.getIndex()) return false;
		//
		var fxp1:Array<Type>, fxp2:Array<Type>, fxi:Int, fxn:Int, fxr:Bool;
		inline function fx(p1:Array<Type>, p2:Array<Type>):Bool {
			fxp1 = p1; fxp2 = p2;
			fxn = fxp1.length;
			if (fxp2.length == fxn) {
				fxi = 0; while (fxi < fxn) {
					if (typeEquals(fxp1[fxi], fxp2[fxi], pos)) {
						fxi += 1;
					} else break;
				}
				fxr = (fxi >= fxn);
			} else fxr = false;
			return fxr;
		}
		//
		var fb1:BaseType, fb2:BaseType;
		inline function fb(t1:BaseType, t2:BaseType) {
			fb1 = t1; fb2 = t2;
			return fb1.module == fb2.module && fb1.name == fb2.name;
		}
		//
		switch ([t1, t2]) {
			case [TType(_.get() => t1, p1), TType(_.get() => t2, p2)]: {
				return fb(t1, t2) && fx(p1, p2);
			}
			case [TInst(_.get() => t1, p1), TInst(_.get() => t2, p2)]: {
				return fb(t1, t2) && fx(p1, p2);
			}
			case [TMono(_.get() => t1), TMono(_.get() => t2)]: {
				if (t1 != null) {
					if (t2 != null) {
						return typeEquals(t1, t2);
					} else return false;
				} else return t2 == null;
			}
			case [TAbstract(_.get() => t1, p1), TAbstract(_.get() => t2, p2)]: {
				return fb(t1, t2) && fx(p1, p2);
			}
			case [TDynamic(a), TDynamic(b)]: {
				switch ([a != null, b != null]) {
					case [true, true]: return typeEquals(a, b, pos);
					case [false, false]: return true;
					default: return false;
				}
			};
			default: {
				var s = "SfExprTools.typeEquals: Can't compare " + t1.getName() + ".";
				#if (macro)
				if (pos != null) {
					Context.error(s, pos);
				} else
				#end
				throw s;
			}
		}
		return false;
	}
	
	/** Returns whether an expression is String-typed */
	public static function isString(expr:SfExpr):Bool {
		switch (expr.getType().resolve()) {
			case TInst(_.get() => c, _): {
				if (c.module == "String") return true;
			}
			default:
		}
		return false;
	}
	
	/** Throws an error at the position of this expr */
	public static function error<T>(expr:SfExpr, text:String):T {
		if (sfConfig.dump != null && sfConfig.dump != "pre") {
			sys.io.File.saveContent("sf.sfdump", SfDump.get());
		}
		#if (macro)
		var stack = haxe.CallStack.callStack();
		/*var depth = stack.length;
		if (depth > 3) {
			var loc = switch (stack[depth - 3]) {
				case FilePos(_, file, line): file.substring(file.lastIndexOf("sf/")) + ":" + line;
				default: Std.string(stack[depth - 3]);
			}
			text = '[$loc] ' + text;
		}*/
		text += haxe.CallStack.toString(stack);
		Context.error(text, getPos(expr));
		#else
		throw text;
		#end
		return null;
	}
	
	/** Throws an error at the position of this expr */
	public static function warning<T>(expr:SfExpr, text:String):T {
		#if (macro)
		haxe.macro.Context.warning(text, getPos(expr));
		#else
		trace(text);
		#end
		return null;
	}
	
	public static inline function setTo(expr:SfExpr, value:SfExprDef) {
		expr.def = value;
	}
	
	public static inline function getData(expr:SfExpr):SfExprData {
		return expr.data;
	}
	
	public static inline function getPos(expr:SfExpr):Position {
		return getData(expr).pos;
	}
	
	private static var sourceCache:Map<String, String> = new Map();
	/** Retrieves source code for given Position. This is not fast. */
	public static function getSource(pos:Position):String {
		var inf = Context.getPosInfos(pos), src:String;
		var file = inf.file;
		if (sourceCache.exists(file)) {
			src = sourceCache.get(file);
		} else {
			if (sys.FileSystem.exists(file)) {
				src = sys.io.File.getContent(file);
			} else src = "";
			sourceCache.set(file, src);
		}
		return src.substring(inf.min, inf.max);
	}
	
	public static inline function getType(expr:SfExpr):Type {
		return expr.data.t;
	}
	
	public static function getTypeNz(expr:SfExpr):Type {
		var t = getType(expr);
		return switch (t) {
			case TAbstract(_.get() => { name: "Null" }, [t1]): t1;
			default: t;
		}
	}
	
	public static inline function setType(expr:SfExpr, t:Type):Void {
		expr.data.t = t;
	}
	
	public static inline function unpack(expr:SfExpr):SfExpr {
		while (expr != null) switch (expr.def) {
			case SfParenthesis(next): expr = next;
			case SfBlock([next]): expr = next;
			case SfCast(next, _): expr = next;
			case SfMeta(_, next): expr = next;
			default: break;
		}
		return expr;
	}
	
	/** Returns whether an expression is nothing worth printing. */
	public static function isEmpty(expr:SfExpr):Bool {
		if (expr == null) return true;
		switch (expr.def) {
			case SfBlock(_exprs): {
				for (e in _exprs) {
					if (!isEmpty(e)) return false;
				}
				return true;
			};
			default: return false;
		}
	}
	
	/** Returns whether an expression should be fine on a single line. */
	public static function isSmall(expr:SfExpr):Bool {
		return switch (unpack(expr).def) {
			case SfBlock(w): w.length == 0 || (w.length == 1 && isSmall(w[0]));
			case SfIf(_, a, z, b): {
				if (a.def.match(SfIf(_, _, _))) {
					false;
				} else if (isSmall(a)) {
					if (z) switch (b.def) {
						case SfIf(_, _, _): false;
						default: isSmall(b);
					} else true;
				} else false;
			};
			case SfWhile(_, x, _): isSmall(x);
			case SfCFor(_, _, _, x): isSmall(x);
			case SfForEach(_, _, _): false;
			case SfSwitch(_, _, _, _): false;
			case SfTry(_, _): false;
			default: true;
		}
	}
	
	/** Returns whether an expression is simple (no possible side effects) */
	public static function isSimple(expr:SfExpr):Bool {
		return switch (unpack(expr).def) {
			case SfConst(_): true;
			case SfLocal(_): true;
			case SfArrayAccess(q, i): isSimple(q) && isSimple(i);
			case SfStaticField(_, _): true;
			case SfInstField(q, _), SfDynamicField(q, _): isSimple(q);
			case SfBinop(o, a, b): switch (o) {
				case Binop.OpAssign, Binop.OpAssignOp(_): false;
				default: isSimple(a) && isSimple(b);
			};
			case SfCall(q, w): {
				switch (q.def) {
					case SfStaticField(_, f) | SfInstField(_, f): {
						if (!f.meta.has(":pure")) return false;
					};
					default: return false;
				};
				for (a in w) if (!isSimple(a)) return false;
				return true;
			};
			default: false;
		}
	}
	
	/** Returns whether an expression is safely wrapped (no need for parenthesis). */
	public static function isWrapped(expr:SfExpr, stack:Array<SfExpr>):Bool {
		for (q in stack) {
			switch (q.def) {
				case SfMeta(_, _): continue;
				case SfCast(_, _): continue;
				default:
			}
			return switch (q.def) {
				case SfArrayAccess(_, x): x.contains(expr);
				case SfCall(x, _): !x.contains(expr);
				case SfTrace(_, _): true;
				default: false;
			}
		}
		return true;
	}
	
	/**
	 * Returns whether the expression is stored inline, as opposed to being a statement.
	 * null is returned if it can be either.
	 */
	public static function isInline(expr:SfExpr, stack:Array<SfExpr>, start:Int = 0):Bool {
		var q = expr;
		var n = stack.length;
		var i = start;
		while (i < n) {
			var o = stack[i];
			switch (o.def) {
				case SfMeta(_, _), SfCast(_, _): {
					q = o; continue;
				};
				default:
			}
			return switch (o.def) {
				case SfDynamic(_, _): null;
				case SfBlock(_): false;
				case SfIf(c, _, _): q == c;
				case SfWhile(c, _, _): q == c;
				case SfCFor(_, c, _, _): q == c;
				case SfForEach(_, c, _): q == c;
				case SfSwitch(c, _, _): q == c;
				default: true;
			}
		}
		return false;
	}
	
	/** !expr */
	public static function invert(expr:SfExpr):SfExpr {
		var rd = switch (unpack(expr).def) {
			case SfConst(TBool(b)): SfConst(TBool(!b));
			case SfBinop(OpEq, a, b): SfBinop(OpNotEq, a, b);
			case SfBinop(OpNotEq, a, b): SfBinop(OpEq, a, b);
			case SfBinop(OpLt, a, b): SfBinop(OpGte, a, b);
			case SfBinop(OpLte, a, b): SfBinop(OpGt, a, b);
			case SfBinop(OpGt, a, b): SfBinop(OpLte, a, b);
			case SfBinop(OpGte, a, b): SfBinop(OpLt, a, b);
			case SfUnop(OpNot, false, a): a.def;
			default: SfUnop(OpNot, false, expr);
		}
		return expr.mod(rd);
	}
	
	/** Modifies in place, (expr) -> (expr + delta) */
	public static function adjustByInt(expr:SfExpr, stack:SfExprList, delta:Int):Void {
		if (delta == 0) return;
		switch (expr.def) {
			case SfConst(TInt(i)): {
				expr.def = SfConst(TInt(i + delta));
				return;
			};
			default:
		}
		//
		if (stack != null && stack.length > 0)
		do switch (stack[0].def) {
			case SfBinop(o, a, b): {
				var mult:Int;
				switch (o) {
					// ((a + 1) > 1) -> (a > 0)
					case OpEq | OpNotEq | OpLt | OpLte | OpGt | OpGte: mult = -1;
					case OpAdd: mult = 1; // (a + 1) + 1 -> (a + 2)
					case OpSub: mult = -1; // ((a + 1) - 2) -> (a - 1)
					default: continue;
				}
				var c = a == expr ? b : a;
				switch (c.def) {
					case SfConst(TInt(k)): {
						c.def = SfConst(TInt(k + delta * mult));
						return;
					};
					default:
				}
			};
			default:
		} while (false);
		//
		expr.def = SfBinop(delta > 0 ? OpAdd : OpSub,
			expr.mod(expr.def),
			expr.mod(SfConst(TInt(delta > 0 ? delta : -delta)))
		);
		if (stack != null && !expr.isWrapped(stack)) {
			expr.def = SfParenthesis(expr.mod(expr.def));
		}
	}
	
	public static function countThis(expr:SfExpr):Int {
		var found:Int = 0;
		function seek(e:SfExpr, w, func:SfExprIter):Void {
			switch (e.def) {
				case SfConst(TThis): found += 1;
				default: iter(e, w, func);
			}
		}; seek(expr, null, seek);
		return found;
	}
	
	public static function countLocal(expr:SfExpr, local:SfVar):Int {
		var found:Int = 0;
		function seek(e:SfExpr, w, func:SfExprIter):Void {
			switch (e.def) {
				case SfLocal(v): if (v.equals(local)) found += 1;
				default: iter(e, w, func);
			}
		}; seek(expr, null, seek);
		return found;
	}
	
	/** Counts reads and writes of a local variable. */
	public static function countLocalExt(expr:SfExpr, local:SfVar):SfExprLocalCounts {
		var reads:Int = 0;
		var writes:Int = 0;
		function seek(e:SfExpr, w, func:SfExprIter):Void {
			switch (e.def) {
				case SfLocal(v): {
					if (v.equals(local)) reads++;
				};
				case SfUnop(OpIncrement | OpDecrement, _, _.def => SfLocal(v)): {
					if (v.equals(local)) {
						reads++;
						writes++;
					}
				};
				case SfBinop(OpAssign | OpAssignOp(_), _.def => SfLocal(v), x): {
					if (v.equals(local)) writes++;
					func(x, w, func);
				}
				default: iter(e, w, func);
			}
		}; seek(expr, null, seek);
		return new SfExprLocalCounts(reads, writes);
	}
	
	/** Counts the maximum number of uses of a variable across the expression branches. */
	public static function countLocalMax(expr:SfExpr, local:SfVar):Int {
		var r:Int;
		inline function f(x:SfExpr) return countLocalMax(x, local);
		inline function fx(w:Array<SfExpr>) for (x in w) r += f(x);
		inline function max(a:Int, b:Int) return (a < b ? b : a);
		return switch (expr.def) {
			case SfLocal(v): v.name == local.name ? 1 : 0;
			
			case SfConst(_) | SfStaticField(_, _) | SfBreak | SfContinue
			| SfTypeExpr(_) | SfEnumField(_, _)
			: 0;
			
			case SfArrayAccess(a, b) | SfEnumAccess(a, _, b) | SfBinop(_, a, b)
				| SfForEach(_, a, b) | SfWhile(a, b, _) | SfInstanceOf(a, b) | SfStrictEq(a, b)
			: f(a) + f(b);
			
			case SfThrow(x) | SfParenthesis(x) | SfEnumParameter(x, _, _)
				| SfInstField(x, _) | SfDynamicField(x, _) | SfClosureField(x, _)
				| SfMeta(_, x) | SfCast(x, _) | SfUnop(_, _, x) | SfTypeOf(x)
			: f(x);
			
			case SfArrayDecl(w) | SfNew(_, _, w) | SfBlock(w) | SfTrace(_, w) | SfDynamic(_, w)
			: r = 0; fx(w); r;
			
			case SfObjectDecl(w): r = 0; for (o in w) r += f(o.expr); r;
			case SfCall(x, w): r = f(x); fx(w); r;
			case SfVarDecl(_, z, x) | SfReturn(z, x): z ? f(x) : 0;
			case SfFunction(o): f(o.expr);
			case SfCFor(a, b, c, d): f(a) + f(b) + f(c) + f(d);
			case SfIf(c, a, z, b): {
				r = f(a);
				if (z) r = max(r, f(b));
				r + f(c);
			};
			case SfSwitch(x, w, z, d): {
				r = 0;
				if (z) r = f(d);
				for (o in w) r = max(r, f(o.expr));
				r + f(x);
			};
			case SfTry(x, w): {
				r = 0;
				for (o in w) r = max(r, f(o.expr));
				r + f(x);
			};
		}
	}
	
	/** Replaces all occurences of a local variable by the given expression. */
	public static function replaceLocal(expr:SfExpr, local:SfVar, repl:SfExpr):Void {
		switch (repl.def) {
			case SfBinop(_, _, _): repl = repl.mod(SfParenthesis(repl));
			default:
		}
		//
		function findAndReplace(e:SfExpr, w, f) {
			switch (e.def) {
				case SfLocal(v): if (v.equals(local)) e.def = repl.def;
				default: iter(e, w, f);
			}
		}; findAndReplace(expr, [], findAndReplace);
	}
	
	/** Returns whether all code path in an expresion end with return/break/continue/throw */
	public static function endsWithExits(expr:SfExpr, ignore:Int = 0):Bool {
		inline function f(x:SfExpr, i:Int) {
			return endsWithExits(x, i);
		}
		inline function fn(x:SfExpr, i:Int) {
			return endsWithExits(x, i) ? true : null;
		}
		var r:Bool, z:Bool;
		switch (expr.def) {
			case SfBlock(w): {
				for (x in w) {
					r = f(x, ignore);
					if (r != null) return r;
				}
				return null;
			};
			case SfIf(_, a, true, b): {
				r = f(a, ignore);
				if (r != null) {
					z = f(b, ignore);
					if (z != null) return r && z;
				}
			}
			case SfWhile(_, x, _) | SfCFor(_, _, _, x) | SfForEach(_, _, x): {
				return fn(x, ignore | 3);
			};
			case SfSwitch(_, w, true, x): {
				r = true;
				for (c in w) {
					z = f(c.expr, ignore);
					if (z != null) r = r && z; else return null;
				}
				z = f(x, ignore);
				if (z != null) r = r && z; else return null;
				return r;
			};
			case SfTry(x, w): {
				r = f(x, ignore);
				if (r == null) return null;
				for (c in w) {
					z = f(c.expr, ignore);
					if (z != null) r = r && z; else return null;
				}
				return r;
			};
			case SfReturn(_, x): return true;
			case SfBreak: return ignore & 1 == 0;
			case SfContinue: return ignore & 2 == 0;
			case SfThrow(_): return ignore & 4 == 0;
			case SfMeta(_, x): return f(x, ignore);
			default:
		}
		return null;
	}
	
	public static function fromTypedExprs(arr:Array<TypedExpr>):Array<SfExpr> {
		var out:Array<SfExpr> = [];
		for (e in arr) out.push(fromTypedExpr(e));
		return out;
	}
	
	public static inline function fromTypedExpr(e:TypedExpr):SfExpr {
		return SfTxConverter.typedExprToSfExpr(e);
	}
}

/** function(expr, stack, func) */
typedef SfExprIter = SfExpr->Array<SfExpr>->SfExprIter->Void;
typedef SfExprMatchIter = SfExpr->Array<SfExpr>->SfExprMatchIter->Bool;

abstract SfExprLocalCounts(Int) {
	public var reads(get, never):Int;
	private inline function get_reads() return this & 0xffff;
	public var writes(get, never):Int;
	private inline function get_writes() return this >> 16;
	public var total(get, never):Int;
	private inline function get_total() return reads + writes;
	public inline function new(reads:Int, writes:Int) {
		this = reads | (writes << 16);
	}
}

#if !macro

#elseif neko
private typedef SfExprInternal = {
	args: neko.NativeArray<Dynamic>,
	tag: Dynamic,
	index: Int
}
#elseif eval

#end
