package sf.type;

import haxe.EnumTools;
import haxe.macro.Expr.Metadata;
import haxe.macro.Expr.Position;
import haxe.macro.Type;
import haxe.macro.Type.TypedExprDef.*;
import haxe.macro.Expr.Binop.*;
import sf.type.expr.SfExprDef.*;
import sf.SfCore.*;
import SfTools.*;
import sf.type.expr.*;
using sf.type.expr.SfExprTools;

/**
 * ...
 * @author YellowAfterlife
 */
class SfDump {
	
	public static function quoteString(s:String, r:SfBuffer) {
		var q = s.indexOf('"') >= 0 && s.indexOf("'") < 0 ? "'".code : '"'.code;
		r.addChar(q);
		for (i in 0 ... s.length) {
			var c = StringTools.fastCodeAt(s, i), d;
			if (c < 32) switch (c) {
				case "\r".code: r.addChar2("\\".code, "r".code);
				case "\n".code: r.addChar2("\\".code, "n".code);
				case "\t".code: r.addChar2("\\".code, "t".code);
				default:
					r.addChar2("\\".code, "x".code);
					d = c >> 4; r.addChar(d < 10 ? 48 + d : 55 + d);
					d = c & 15; r.addChar(d < 10 ? 48 + d : 55 + d);
			} else {
				if (c == q || c == "\\".code) r.addChar("\\".code);
				r.addChar(c);
			}
		}
		r.addChar(q);
	}
	
	public static function pos(p:Position, ?r:SfBuffer):String {
		var s:String = Std.string(p);
		var n:Int = s.length;
		if (r != null) {
			r.addSub(s, 5, n - 6);
			return null;
		} else return s.substring(5, n - 1);
	}
	
	public static function type(t:Type, ?r:SfBuffer):String {
		var ret = r == null;
		if (ret) r = new SfBuffer();
		var pack:Array<String>, i:Int, n:Int;
		inline function f(t:BaseType) {
			pack = t.pack;
			n = pack.length;
			i = 0; while (i < n) {
				r.addString(pack[i]);
				r.addChar(".".code);
				i += 1;
			}
			r.addString(t.name);
		}
		inline function p(m:Array<Type>) {
			if (m != null) {
				n = m.length;
				if (n > 0) {
					r.addChar("<".code);
					i = 0; while (i < n) {
						if (i > 0) r.addChar2(",".code, " ".code);
						SfDump.type(m[i], r);
						i += 1;
					}
					r.addChar(">".code);
				}
			}
		}
		switch (t) {
			case TEnum(_.get() => et, w): f(et); p(w);
			case TInst(_.get() => ct, w): f(ct); p(w);
			case TType(_.get() => dt, w): f(dt); p(w);
			case TFun(args, ret): {
				n = args.length;
				printf(r, "function(");
				i = 0; while (i < n) {
					if (i > 0) r.addString(", ");
					printf(r, "%s:", args[i].name); type(args[i].t, r);
					i += 1;
				}
				printf(r, "):"); type(ret, r);
			};
			case TDynamic(t): {
				if (t != null) {
					printf(r, "Dynamic<"); type(t, r); printf(r, ">");
				} else printf(r, "Dynamic");
			};
			case TLazy(_() => t): type(t, r);
			case TAbstract(_.get() => at, m): {
				f(at); p(m);
			}
			default: r.addString("?");
		}
		return ret ? r.toString() : null;
	}
	
	public static function meta(metas:Metadata, ?r:SfBuffer):String {
		var ret = r == null;
		if (ret) r = new SfBuffer();
		for (i in 0 ... metas.length) {
			var md = metas[i];
			if (i > 0) printf(r, " ");
			printf(r, "@%s", md.name);
			var params = md.params;
			if (params != null && params.length > 0) {
				printf(r, "(");
				for (k in 0 ... params.length) {
					if (k > 0) printf(r, ", ");
					var param = params[k];
					switch (param.expr) {
						case EConst(c): switch (c) {
							case CInt(s)|CFloat(s)|CIdent(s): printf(r, "%s", s);
							case CString(s): printf(r, '"%s"', s);
							case CRegexp(s, o): printf(r, "~/%s/%s", s, o);
							default: printf(r, "%s", c.getName());
						};
						default: {
							printf(r, "%s", haxe.macro.ExprTools.toString(param));
							//printf(r, "%s", params[k].expr.getName());
						}
					}
				}
				printf(r, ")");
			}
		}
		return ret ? r.toString() : null;
	}
	
	private static inline var EC_DEF = 0;
	private static inline var EC_PAR = 1;
	private static inline var EC_INLINE = 2;
	public static function expr(e:SfExpr, r:SfBuffer, q:Int = EC_DEF, ?p:SfExpr):Void {
		var i:Int, n:Int, w:Array<SfExpr>, z:Bool;
		inline function f(x:SfExpr) expr(x, r, EC_INLINE, e);
		inline function fb(x:SfExpr) expr(x, r, EC_DEF, e);
		inline function fw(x:SfExpr) expr(x, r, EC_PAR, e);
		inline function fbc(x:SfExpr) {
			r.addChar("{".code);
			r.addLine(1);
			expr(x, r, EC_DEF, e);
			r.addSemico();
			r.addLine(-1);
			r.addChar("}".code);
			r.markSemico();
		}
		inline function fpx(m:Array<SfExpr>) {
			w = m;
			n = w.length;
			i = 0;
			while (i < n) {
				if (i > 0) r.addString(", ");
				expr(w[i], r, EC_PAR);
				i += 1;
			}
		}
		switch (e.def) {
			case null: r.addString("null");
			case SfConst(c): {
				switch (c) {
					case TBool(b): r.addString(b ? "true" : "false");
					case TInt(i): r.addInt(i);
					case TFloat(s): r.addString(s);
					case TString(s): quoteString(s, r);
					case TNull: r.addString("null");
					case TThis: r.addString("this");
					case TSuper: r.addString("super");
					default: r.add(c);
				}
			}
			case SfArrayAccess(q, e): f(q); printf(r, "["); f(e); printf(r, "]");
			case SfEnumAccess(q, _, i): f(q); printf(r, "[EA:"); f(i); printf(r, "]");
			case SfEnumParameter(x, q, i): f(x); printf(r, "[EP:%d]", i);
			case SfEnumField(_, c): {
				r.addFieldPath(c, "_".code, "_".code);
			};
			case SfLocal(v): printf(r, "%s", v.name);
			case SfDynamic(s, []): printf(r, "raw("); quoteString(s, r); printf(r, ")");
			case SfDynamic(_code, _args): {
				if (_args.length >= 10) e.error("Too many arguments");
				printf(r, "raw(");
				quoteString(_code, r);
				w = _args; n = w.length;
				i = 0; while (i < n) {
					r.addComma(); f(w[i]); i += 1;
				}
				printf(r, ")");
			};
			case SfBinop(o, a, b): {
				i = switch (o) {
					case OpAssign: 1;
					case OpAssignOp(o1): o = o1; 2;
					default: 0;
				};
				if (q == EC_INLINE) r.addParOpen();
				f(a);
				r.addChar(" ".code);
				switch (o) {
					case OpAssign: printf(r, "=");
					case OpAdd: printf(r, "+");
					case OpSub: printf(r, "-");
					case OpMult: printf(r, "*");
					case OpDiv: printf(r, "/");
					case OpMod: r.addChar("%".code);
					case OpEq: printf(r, "==");
					case OpNotEq: printf(r, "!=");
					case OpLt: printf(r, "<");
					case OpLte: printf(r, "<=");
					case OpGt: printf(r, ">");
					case OpGte: printf(r, ">=");
					case OpBoolAnd: printf(r, "&&");
					case OpBoolOr: printf(r, "||");
					case OpAnd: printf(r, "&");
					case OpOr: printf(r, "|");
					case OpXor: printf(r, "^");
					case OpShl: printf(r, "<<");
					case OpShr: printf(r, ">>");
					case OpUShr: printf(r, ">>>");
					default: r.addString(o.getName());
				}
				if (i == 2) r.addChar("=".code);
				r.addChar(" ".code);
				if (i > 0) fw(b); else f(b);
				if (q == EC_INLINE) r.addParClose();
			}
			case SfUnop(o, p, e): {
				if (p) f(e);
				switch (o) {
					case OpIncrement: printf(r, "++");
					case OpDecrement: printf(r, "--");
					case OpNot: printf(r, "!");
					case OpNeg: printf(r, "-");
					case OpNegBits: printf(r, "~");
				}
				if (!p) f(e);
			}
			case SfObjectDecl(w): {
				n = w.length;
				if (n > 0) {
					printf(r, "{ ");
					i = 0; while (i < n) {
						if (i > 0) printf(r, ", ");
						printf(r, "%s: ", w[i].name); f(w[i].expr);
						i += 1;
					}
					printf(r, " }");
				} else printf(r, "{ }");
			};
			case SfArrayDecl(m): printf(r, "["); fpx(m); printf(r, "]");
			case SfCall(e, m): f(e); printf(r, "("); fpx(m); printf(r, ")");
			case SfTrace(_, m): printf(r, "trace("); fpx(m); printf(r, ")");
			case SfNew(q, _, m): {
				printf(r, "new "); r.addTypePath(q);
				printf(r, "("); fpx(m); printf(r, ")");
			};
			case SfFunction(q): {
				r.addString("function");
				if (q.name != null) printf(r, " %s", q.name);
				r.addParOpen();
				var args = q.args;
				n = args.length;
				i = 0; while (i < n) {
					if (i > 0) printf(r, ", ");
					printf(r, "%s:", args[i].v.name);
					type(args[i].v.type, r);
					i += 1;
				}
				r.addParClose();
				r.addChar(":".code);
				type(q.ret, r);
				printf(r, " "); f(q.expr);
			};
			case SfStaticField(c, _field): {
				if (_field != null) {
					r.addFieldPath(_field);
				} else {
					if (c != null) {
						r.addTypePathAuto(c);
					} else printf(r, "?");
					printf(r, ".?");
				}
			};
			case SfInstField(o, q): f(o); printf(r, ".%s", q.name);
			case SfDynamicField(o, s): f(o); printf(r, ".%s", s);
			case SfParenthesis(e): printf(r, "("); fw(e); printf(r, ")");
			case SfVarDecl(v, z, e): {
				printf(r, "var %s:", v.name); type(v.type, r);
				if (z) { printf(r, " = "); fw(e); }
			};
			case SfBlock(m): {
				printf(r, "{");
				n = m.length;
				if (n > 0) {
					r.indent += 1;
					i = 0; while (i < n) {
						printf(r, "\n");
						fb(m[i]);
						printf(r, ";");
						i += 1;
					}
					r.indent -= 1;
					r.addLine();
				} else r.addChar(" ".code);
				printf(r, "}");
			};
			case SfIf(c, x, _, e): {
				printf(r, "if "); f(c); printf(r, " ");
				z = switch (x.def) {
					case SfIf(_, _, _): false;
					default: if (e != null) switch (e.def) {
						case SfIf(_, _, _): z = false;
						default: if (p != null) switch (p.def) {
							case SfIf(_, _, _): false;
							default: true;
						} else true;
					} else true;
				}
				if (z) fb(x); else fbc(x);
				if (e != null) { printf(r, "; else "); fb(e); }
			};
			case SfWhile(c, x, true): printf(r, "while "); f(c); printf(r, " "); f(x);
			case SfWhile(c, x, false): printf(r, "do "); f(x); printf(r, "while "); f(c);
			case SfCFor(i, c, p, e): {
				printf(r, "for ("); fb(i);
				printf(r, "; "); fw(c);
				printf(r, "; "); fb(p);
				printf(r, ") "); fb(e);
			};
			case SfSwitch(x, m, _, d): {
				printf(r, "switch "); fw(x); printf(r, " {");
				r.indent += 1;
				for (c in m) {
					r.addLine();
					printf(r, "case ");
					var comma = false;
					for (v in c.values) {
						if (comma) printf(r, ", "); else comma = true;
						fw(v);
					}
					printf(r, ": ");
					var cx = c.expr;
					if (!cx.isEmpty()) {
						var wrap = if (cx.isSmall()) {
							false;
						} else switch (cx.def) {
							case SfBlock(_): false;
							default: true;
						}
						if (wrap) {
							printf(r, "{");
							r.addLine(1);
							fb(cx);
							r.addLine( -1);
							printf(r, "}");
						} else { fb(cx); printf(r, ";"); }
					}
				}
				if (d != null) {
					printf(r, "\ndefault: ");
					var wrap = if (d.isSmall()) {
						false;
					} else switch (d.def) {
						case SfBlock(_): false;
						default: true;
					}
					if (wrap) {
						printf(r, "{");
						r.addLine(1);
						fb(d);
						r.addLine( -1);
						printf(r, "}");
					} else { fb(d); printf(r, ";"); }
				}
				r.indent -= 1;
				printf(r, "\n}");
			}
			case SfReturn(_, e): {
				printf(r, "return");
				if (e != null) { printf(r, " "); f(e); }
			};
			case SfBreak: printf(r, "break");
			case SfContinue: printf(r, "continue");
			case SfCast(e, t): printf(r, "cast("); f(e); printf(r, ", %s)", t.name);
			case SfTypeOf(e): printf(r, "typeof("); f(e); printf(r, ")");
			case SfTry(x, cc): {
				printf(r, "try ");
				f(x);
				for (c in cc) {
					printf(r, " catch (%s) ", c.v.name);
					f(c.expr);
				}
			};
			case SfThrow(x): {
				printf(r, "throw "); f(x);
			};
			case SfStrictEq(a, b): {
				if (q == EC_INLINE) r.addParOpen();
				f(a); printf(r, " === "); f(b);
				if (q == EC_INLINE) r.addParClose();
			}
			case SfMeta(m, e): {
				printf(r, "@%s", m.name);
				var _params = m.params;
				if (_params != null) {
					printf(r, "(");
					for (i in 0 ... _params.length) {
						if (i > 0) printf(r, ", ");
						r.addString(haxe.macro.ExprTools.toString(_params[i]));
					}
					printf(r, ")");
				}
				printf(r, " "); f(e);
			};
			case SfTypeExpr(t): r.addTypePath(t, ".".code);
			case SfInstanceOf(x, t): f(x); printf(r, " is "); f(t);
			default: r.addString(e.getName());
		}
	}
	
	public static function get():String {
		var r:SfBuffer = new SfBuffer();
		printf(r, "%s\n", "// Generated at " + Date.now());
		for (t in sfGenerator.typeList) {
			t.dumpTo(r);
			r.addLine();
		}
		return r.toString();
	}
}
