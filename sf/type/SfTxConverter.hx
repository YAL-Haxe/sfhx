package sf.type;
import haxe.macro.Type;
import haxe.macro.Type.TypedExprDef.*;
import sf.type.expr.SfExprDef.*;
import sf.type.expr.*;
import sf.SfCore.*;

/**
 * ...
 * @author YellowAfterlife
 */
class SfTxConverter {
	
	public static function typedExprsToSfExprs(arr:Array<TypedExpr>):Array<SfExpr> {
		var out:Array<SfExpr> = [];
		for (e in arr) out.push(typedExprToSfExpr(e));
		return out;
	}
	
	public static function typedExprToSfExpr(e:TypedExpr) {
		if (e == null) return null;
		inline function f(e1:TypedExpr):SfExpr {
			return typedExprToSfExpr(e1);
		}
		inline function fx(el:Array<TypedExpr>):Array<SfExpr> {
			return typedExprsToSfExprs(el);
		}
		inline function fv(v:TVar):SfVar {
			return SfVar.fromTVar(v);
		}
		inline function error<T>(e:TypedExpr, s:String):T {
			#if (macro)
			haxe.macro.Context.error("fromTypedExpr: " + s, e.pos);
			return null;
			#else
			throw s + " @ " + e.pos;
			#end
		}
		inline function warning(e:TypedExpr, s:String) {
			#if (macro)
			haxe.macro.Context.warning("fromTypedExpr: " + s, e.pos);
			#end
		}
		var d:SfExprData = e; // { expr: null, pos: e.pos, t: e.t }
		var i:Int, n:Int;
		var z:Bool;
		//{
		var sft:SfType;
		var sfc:SfClass;
		var sfArgs:Array<SfArgument>;
		var sfExprs:Array<SfExpr>;
		var sfStr:String;
		//}
		var r:SfExpr = null, rd:SfExprDef = null;
		switch (e.expr) {
			case TConst(c): rd = SfConst(c);
			case TLocal(v): rd = SfLocal(SfVar.fromTVar(v));
			case TArray(a, i): rd = SfArrayAccess(f(a), f(i));
			case TBinop(o, a, b): rd = SfBinop(o, f(a), f(b));
			case TIdent(s): rd = SfDynamic(s, []);
			case TField(o, _fa): {
				switch (_fa) {
					case FStatic(_ct, _cf): {
						var ct = _ct.get();
						var cf = _cf.get();
						var c = SfCore.sfGenerator.classMap.baseGet(ct);
						if (c != null) {
							var f = c.staticMap[cf.name];
							if (f != null) {
								rd = SfStaticField(c, f);
							} else {
								// probably untyped Class.field, suspicious!
								rd = SfDynamicField(new SfExpr(d, SfTypeExpr(c)), cf.name);
							}
						} else rd = SfDynamicField(new SfExpr(d, SfDynamic(ct.name, [])), cf.name);
					};
					case FInstance(_ct, _, _cf): {
						var ct = _ct.get();
						var cf = _cf.get();
						var c = SfCore.sfGenerator.classMap.baseGet(ct);
						if (c != null) {
							var sf = c.instMap[cf.name];
							if (sf != null) {
								rd = SfInstField(f(o), sf);
							} else rd = SfDynamicField(f(o), cf.name);
						} else rd = SfDynamicField(f(o), cf.name);
					};
					case FEnum(_et, ef): {
						var et = _et.get();
						var sfe = sfGenerator.enumMap.baseGet(et);
						if (sfe != null) {
							var sff = sfe.ctrList[ef.index];
							if (sff != null) {
								rd = SfEnumField(sfe, sff);
							} else error(e, "Could not find " + ef.name + " in " + et.name);
						} else error(e, "Could not find enum " + et.name);
					};
					case FClosure({ c: _.get() => c }, _.get() => cf): {
						var sfc = sfGenerator.classMap.baseGet(c);
						if (c != null) {
							var sff = sfc.instMap[cf.name];
							if (sff != null) {
								rd = SfClosureField(f(o), sff);
							} else error(e, "Could not find field " + cf.name);
						} else error(e, "Could not find class " + c.name);
					};
					case FDynamic(s): rd = SfDynamicField(f(o), s);
					case FAnon(_cf): rd = SfDynamicField(f(o), _cf.get().name);
					default: error(e, "Can't convert TField::" + _fa.getName());
				}
			};
			case TTypeExpr(mt): {
				var sft = switch (mt) {
					case TClassDecl(_c): sfGenerator.classMap.baseGet(_c.get());
					case TEnumDecl(_e): sfGenerator.enumMap.baseGet(_e.get());
					case TAbstract(_arg): sfGenerator.abstractMap.baseGet(_arg.get());
					default: error(e, "Can't convert TTypeExpr:" + mt.getName());
				}
				rd = SfTypeExpr(sft);
			}
			case TParenthesis(x): rd = SfParenthesis(f(x));
			case TObjectDecl(w): {
				var sfFields = [];
				for (o in w) sfFields.push({ name: o.name, expr: f(o.expr) });
				rd = SfObjectDecl(sfFields);
			};
			case TArrayDecl(w): rd = SfArrayDecl(fx(w));
			//
			case TCall(o, m): {
				r = null;
				function procTrace(m:Array<TypedExpr>) {
					var td = {
						fileName: "?",
						lineNumber: -1,
						className: "?",
						methodName: "?"
					};
					var args = [f(m[0])];
					var info = m[1];
					while (info != null) switch (info.expr) {
						case TMeta(_, x): info = x;
						case TCast(x, _): info = x;
						default: break;
					}
					switch (info.expr) {
						case TObjectDecl(w): {
							for (pair in w) switch (pair.name) {
								case "fileName": switch (pair.expr.expr) {
									case TConst(TString(s)): td.fileName = s;
									default:
								};
								case "lineNumber": switch (pair.expr.expr) {
									case TConst(TInt(i)): td.lineNumber = i;
									default:
								};
								case "customParams": switch (pair.expr.expr) {
									case TArrayDecl(rest): {
										for (v in rest) args.push(f(v));
									};
									default:
								};
								default:
							}
						};
						default: // error(info, "An unusual `trace data argument, " + info.expr.getName());
					}
					return new SfExpr(d, SfTrace(td, args));
				}
				switch (o.expr) {
					case TLocal({ name: _name }), TIdent(_name): switch (_name) {
						case "`trace": r = procTrace(m);
						case "__js__" | "__raw__": {
							if (m.length < 1) error(e, "Requires one or more arguments.");
							sfStr = switch (m[0].expr) {
								case TConst(TString(s)): s;
								default: error(m[0], "Expected a String constant.");
							};
							sfExprs = [];
							for (i in 1 ... m.length) sfExprs.push(f(m[i]));
							rd = SfDynamic(sfStr, sfExprs);
						};
						case "__define_feature__": {
							if (m.length < 1) error(e, "Expected two arguments.");
							r = f(m[1]);
						};
						case "__typeof__": rd = SfTypeOf(f(m[0]));
						case "__instanceof__": rd = SfInstanceOf(f(m[0]), f(m[1]));
						case "__feature__": {
							switch (m[0].expr) {
								case TConst(TString(s)): {
									i = s.lastIndexOf(".");
									if (i >= 0
									? sfGenerator.hasFeature(s.substring(0, i), s.substring(i + 1))
									: sfGenerator.hasFeature(s)
									) {
										r = f(m[1]);
									} else if (m.length > 2) {
										r = f(m[2]);
									} else rd = SfBlock([]);
								};
								default: error(m[0], "Expected a String argument.");
							}
						};
						default:
					}; // TLocal
					case TField(_, FieldAccess.FStatic(
						_.get() => { module: "haxe.Log" }, _.get() => { name: "trace" }
					)): r = procTrace(m);
					case TField(_, FieldAccess.FStatic(
						_.get() => { module: "js.Syntax" }, _.get() => fd
					)): {
						switch (fd.name) {
							#if (sfjs)
							case "construct": {
								var c = f(m[0]);
								var args = [];
								for (i in 1 ... m.length) {
									args.push(f(m[i]));
								}
								rd = SfCall(
									new SfExpr(c.data, SfDynamic("new {0}", [c])),
									args);
							};
							#end
							case "instanceof": rd = SfInstanceOf(f(m[0]), f(m[1]));
							case "typeof": rd = SfTypeOf(f(m[0]));
							case "strictEq": rd = SfStrictEq(f(m[0]), f(m[1]));
							case "code": {
								var args = fx(m);
								switch (args.shift().def) {
									case SfConst(TString(s)): {
										rd = SfDynamic(s, args);
									};
									default: error(m[0], "Expected a string");
								}
							};
							default: error(m[0], "SfTxConverter: Can't handle js.Syntax." + fd.name);
						}
					};
					default:
				} // switch (o.expr)
				if (r == null && rd == null) {
					var args = []; for (a in m) args.push(f(a));
					rd = SfCall(f(o), args);
				};
			};
			case TNew(_ct, _params, _args): {
				var ct = _ct.get();
				sfc = sfGenerator.classMap.baseGet(ct);
				if (sfc == null) {
					if (ct.module == "js.Boot" && ct.name == "HaxeError") {
						r = f(_args[0]);
					} else {
						sfc = new SfClass(ct);
						sfGenerator.classList.push(sfc);
						sfGenerator.classMap.sfSet(sfc, sfc);
						//warning(e, ct.name + " wasn't present in apiTypes."); // abug?
					}
				}
				if (sfc != null) {
					sfExprs = [];
					for (_arg in _args) sfExprs.push(f(_arg));
					rd = SfNew(sfc, _params, sfExprs);
				}
			};
			//
			case TUnop(o, p, x): rd = SfUnop(o, p, f(x));
			case TFunction(o): {
				var args:Array<SfArgument> = [];
				for (a in o.args) args.push(SfArgument.fromTyped(a));
				rd = SfFunction({ args: args, ret: o.t, expr: f(o.expr) });
			};
			case TVar(v, x): rd = SfVarDecl(SfVar.fromTVar(v), x != null, f(x));
			case TBlock(w): {
				var list = [];
				for (o in w) list.push(f(o));
				rd = SfBlock(list);
			};
			case TIf(c, a, b): rd = SfIf(f(c), f(a), b != null, f(b));
			case TWhile(c, x, n): rd = SfWhile(f(c), f(x), n);
			case TFor(v, o, x): rd = SfForEach(SfVar.fromTVar(v), f(o), f(x));
			case TSwitch(_expr, _cases, _default): {
				// prefer the authored order:
				_cases.sort(function(a, b) {
					inline function valOf(q) {
						return haxe.macro.PositionTools.getInfos(q.expr.pos).min;
					}
					return valOf(a) - valOf(b);
				});
				//
				var sfCases = [];
				for (_case in _cases) sfCases.push({
					values: fx(_case.values),
					expr: f(_case.expr),
				});
				rd = SfSwitch(f(_expr), sfCases, _default != null, f(_default)); 
			};
			case TTry(_expr, _catches): {
				var sfCatches = [];
				for (_catch in _catches) sfCatches.push({
					v: fv(_catch.v),
					expr: f(_catch.expr)
				});
				rd = SfTry(f(_expr), sfCatches);
			}
			case TReturn(r): rd = SfReturn(r != null, f(r));
			case TBreak: rd = SfBreak;
			case TContinue: rd = SfContinue;
			case TThrow(r): rd = SfThrow(f(r));
			case TCast(q, null): r = f(q);
			case TCast(q, mt): {
				// todo
				var sft:SfType = switch (mt) {
					case TClassDecl(_.get() => ct): sfGenerator.classMap.baseGet(ct);
					case TEnumDecl(_.get() => et): sfGenerator.enumMap.baseGet(et);
					case TTypeDecl(_.get() => tt): {
						var t = SfExprTools.resolve(tt.type);
						switch (t) {
							case TInst(_.get() => ct, _): sfGenerator.classMap.baseGet(ct);
							case TEnum(_.get() => et, _): sfGenerator.enumMap.baseGet(et);
							case TAbstract(_.get() => at, _): sfGenerator.abstractMap.baseGet(at);
							default: null;
						}
					}
					case TAbstract(_.get() => at): sfGenerator.abstractMap.baseGet(at);
					default: null;
				}
				if (sft != null) {
					rd = SfCast(f(q), sft);
				} else error(e, "Can't find " + mt);
			};
			case TMeta(m, x): rd = SfMeta(m, f(x));
			case TEnumIndex(x): {
				i = #if (gml) 0 #else 1 #end;
				rd = SfArrayAccess(f(x), new SfExpr(d, SfConst(TInt(i))));
			};
			case TEnumParameter(x, ef, i): {
				var et:EnumType;
				switch (x.t) {
					case TType(_.get() => {type: TEnum(_et, _)}, _): et = _et.get();
					case TEnum(_et, _): et = _et.get();
					default: error(e, "Taking enum parameter of non-enum type?");
				}
				var sfEnum = sfGenerator.enumMap.baseGet(et);
				if (sfEnum == null) error(e, "Could not find enum " + et.name);
				var sfEnumCtr = sfEnum.ctrMap[ef.name];
				if (sfEnumCtr == null) error(e, "Could not find " + ef.name + " in " + sfEnum.name);
				rd = SfEnumParameter(f(x), sfEnumCtr, i);
			};
			default: error(e, "Can't convert TExpr:" + e.expr.getName());
		}
		if (r != null) return r;
		if (rd != null) return new SfExpr(d, rd);
		return error(e, "No information was returned for " + e.expr.getName());
	}
}
