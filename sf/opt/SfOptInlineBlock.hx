package sf.opt;

import sf.opt.SfOptImpl;
import sf.type.expr.SfExprDef.*;
import sf.type.*;
import sf.type.expr.*;
using sf.type.expr.SfExprTools;
import SfTools.*;

/**
 * This is just me fighting the Haxe compiler over redundant code generation.
 * @author YellowAfterlife
 */
class SfOptInlineBlock extends SfOptImpl {
	
	/**
	 * Time to time your `while (--i)` becomes replaced by `while (i -= 1)`.
	 */
	private function fixInlinePrefixes(e:SfExpr, w, f) {
		e.iter(w, f);
		switch (e.def) {
			case SfParenthesis(_.def => SfBinop(OpAssignOp(o = OpAdd | OpSub),
				x, _.def => SfConst(TInt(1))
			)) if (e.isInline(w)): {
				e.def = SfUnop(o == OpAdd ? OpIncrement : OpDecrement, false, x);
			};
			default:
		}
	}
	
	/**
	 * `if (a) return b; else return false;` -> `return a && b;`
	 */
	private function restoreBoolAndReturn(q:SfExpr, w, f) {
		q.iter(w, f);
		var a:SfExpr, b:SfExpr;
		// match `if (c) return x; else return false;`
		switch (q.def) {
			case SfIf(c, t, true, e): {
				a = c;
				b = switch (t.def) {
					case SfReturn(true, x): x;
					default: return;
				};
				switch (e.def) {
					case SfReturn(true, _.def => SfConst(TBool(false))): { }; // OK!
					default: return;
				};
			};
			default: return;
		}
		// only restore clearly-boolean returns:
		switch (b.getType()) {
			case TAbstract(_.get() => { name: "Bool" }, _): { }; // OK!
			default: return;
		}
		// unwrap first expression, unless it's a boolean OR:
		switch (a.def) {
			case SfParenthesis(p) if (!p.def.match(SfBinop(OpBoolOr, _, _))): a = p;
			default:
		}
		//
		q.def = SfReturn(true, q.mod(SfBinop(OpBoolAnd, a, b)));
	}
	
	/**
	 * `if (!a) return b; else return true;` -> `return a || b;`
	 */
	private function restoreBoolOrReturn(q:SfExpr, w, f) {
		q.iter(w, f);
		var a:SfExpr, b:SfExpr;
		// match `if (c) return x; else return false;`
		switch (q.def) {
			case SfIf(c, t, true, e): {
				a = switch (c.def) {
					case SfParenthesis(_.def => SfUnop(OpNot, false, q)): q;
					default: return;
				}
				b = switch (t.def) {
					case SfReturn(true, x): x;
					default: return;
				};
				switch (e.def) {
					case SfReturn(true, _.def => SfConst(TBool(true))): { }; // OK!
					default: return;
				};
			};
			default: return;
		}
		// only restore clearly-boolean returns:
		switch (b.getType()) {
			case TAbstract(_.get() => { name: "Bool" }, _): { }; // OK!
			default: return;
		}
		//
		q.def = SfReturn(true, q.mod(SfBinop(OpBoolOr, a, b)));
	}
	
	private function flipIfNot(q:SfExpr, w, f) {
		q.iter(w, f);
		switch (q.def) {
			case SfIf(c, t, true, e): {
				var cu = c.unpack();
				switch (cu.def) {
					case SfUnop(OpNot, false, x): {
						cu.def = x.def;
						q.def = SfIf(c, e, true, t);
					};
					default:
				}
			};
			default:
		}
	}
	
	/** `q = { var a = v; fn(a); }` -> `q = fn(v)` **/
	private function fixInlinePairBlock(e:SfExpr, w:SfExprList, f:SfExprIter) {
		e.iter(w, f);
		switch (e.def) {
			case SfBlock([_.def => SfVarDecl(v, true, r), x])
			if (x.countLocal(v) == 1 && e.isInline(w)): {
				x.replaceLocal(v, r);
				e.setTo(x.def);
			};
			default:
		}
	}
	
	private function procTenary() {
		var typeBoot = SfCore.sfGenerator.typeBoot;
		var fdTern = typeBoot != null ? typeBoot.staticMap["tern"] : null;
		var usesTern = false;
		if (!SfCore.sfConfig.ternary) forEachExpr(function(e:SfExpr, w:SfExprList, f:SfExprIter) {
			switch (e.def) {
				case SfIf(c, a, true, b): {
					var p = w[0];
					if (p != null && e.isInline(w)) switch (p.def) {
						case SfCall(_, _args) | SfNew(_, _, _args)
						if (!p.isInline(w, 1)): {
							var i = _args.length;
							if (a.isSimple() && b.isSimple()) {
								i = -1;
							} else while (--i >= 0) {
								var arg:SfExpr = _args[i];
								if (arg != e && !arg.isSimple()) break;
							}
							if (i < 0) {
								var v = new SfVar("__ternary__", e.getType());
								e.def = SfLocal(v.clone());
								p.def = SfBlock([
									p.mod(SfVarDecl(v, false, null)),
									p.mod(SfIf(c,
										a.mod(SfBinop(OpAssign, e.mod(SfLocal(v)), a)), true,
										b.mod(SfBinop(OpAssign, e.mod(SfLocal(v)), b))
									)),
									p.clone(),
								]);
							}
						};
						default: if (fdTern != null) {
							if (!a.isSimple() || !b.isSimple()) {
								e.warning("No ternary operator available - this may have side effects."
									+ a + " " + b);
							}
							switch (c.def) {
								case SfParenthesis(x): c = x;
								default:
							}
							e.def = SfCall(e.mod(SfStaticField(typeBoot, fdTern)), [c, a, b]);
							usesTern = true;
						};
					}
				};
				case SfVarDecl(v, true, vx): {
					switch (vx.def) {
						case SfIf(c, a, true, b): {
							e.setTo(SfBlock([
								e.mod(SfVarDecl(v, false, null)),
								e.mod(SfIf(c,
									a.mod(SfBinop(OpAssign, e.mod(SfLocal(v)), a)), true,
									b.mod(SfBinop(OpAssign, e.mod(SfLocal(v)), b))
								)),
							]));
						};
						default:
					}
				};
				case SfBinop(o = OpAssign | OpAssignOp(_), x, _.def => SfIf(c, a, true, b)): {
					e.setTo(SfIf(c,
						e.mod(SfBinop(o, x, a)), true,
						e.mod(SfBinop(o, x.clone(), b.clone()))
					));
				};
				case SfReturn(true, _.def => SfIf(c, a, true, b)): {
					e.def = SfIf(c,
						e.mod(SfReturn(true, a)), true,
						e.mod(SfReturn(true, b))
					);
				};
				default:
			}
			e.iter(w, f);
		}, []);
		if (!usesTern && fdTern != null) fdTern.isHidden = true;
	}
	
	/** `{ var a = v; var b; b = a; b; }` -> `v` */
	private function fixSimpleInlineJuggling() {
		forEachExpr(function(e:SfExpr, w, f) {
			e.iter(w, f);
			switch (e.def) {
				case SfBlock([
					_.def => SfVarDecl(v10, true, r),
					_.def => SfVarDecl(v20, false, _),
					_.def => SfBinop(OpAssign, _.def => SfLocal(v21), _.def => SfLocal(v11)),
					_.def => SfLocal(v22)
				]) if (v10.equals(v11) && v20.equals(v21) && v20.equals(v22)): {
					e.setTo(r.def);
				};
				default:
			}
		});
	}
	
	/**
	 * `some = { ...; value; }` -> `...; some = value;`
	 * `return { ...; value; }` -> `...; return value;`
	 */
	private function fixSimpleInlineBlockAssign() {
		forEachExpr(function(e:SfExpr, w, f) {
			e.iter(w, f);
			switch (e.def) {
				case SfReturn(true, rv): {
					var rvu = rv.unpack();
					switch(rvu.def) {
						case SfBlock(exprs):
							var val = exprs[exprs.length - 1];
							rvu.setTo(val.def);
							val.setTo(SfReturn(true, rv));
							e.setTo(SfBlock(exprs));
						default:
					}
				};
				case SfBinop(op = OpAssign | OpAssignOp(_), src, dst): {
					var dstu = dst.unpack();
					switch (dstu.def) {
						case SfBlock(exprs): {
							var value = exprs[exprs.length - 1];
							dstu.setTo(value.def);
							value.setTo(SfBinop(op, src, dst));
							e.setTo(SfBlock(exprs));
						};
						default:
					}
				};
				default:
			}
		});
	}
	
	/** `while ({ ...; value}) expr;` -> `while (true) { ...; if (!value) break; expr; }` */
	private function fixInlineWhileLoopConditionBlock() {
		forEachExpr(function(e:SfExpr, w, f) {
			e.iter(w, f);
			switch (e.def) {
				case SfWhile(cond, expr, true): {
					var condu = cond.unpack();
					switch (condu.def) {
						case SfBlock(cexprs): {
							var value = cexprs.pop();
							cexprs.push(e.mod(SfIf(
								e.mod(SfParenthesis(value.invert())),
								e.mod(SfBreak), false, null)
							));
							condu.setTo(SfConst(TBool(true)));
							e.setTo(SfWhile(cond, e.mod(SfBlock([
								e.mod(SfBlock(cexprs)),
								expr
							])), true));
						};
						default:
					};
				}
				default:
			}
		});
	}
	
	/** `while (true) { ...; if (!expr) break; }` -> `do { ... } while (expr);` */
	private function restoreDoWhile() {
		forEachExpr(function(e:SfExpr, w:Array<SfExpr>, f) {
			e.iter(w, f);
			// `while (true) { ... }` ? 
			var loop, exprs;
			switch (e.def) {
				case SfWhile(cond1, q = _.def => SfBlock(w), true): {
					switch (cond1.def) {
						case SfConst(TBool(true)): loop = q; exprs = w;
						default: return;
					}
				}; default: return;
			};
			//
			var count = exprs.length;
			var cond = if (count > 0) switch (exprs[count - 1].def) {
				case SfIf(c, _.def => SfBreak, false, _): {
					var c1 = c.unpack();
					switch (c1.def) {
						case SfUnop(OpNot, false, c): c;
						default: return;
					}
				};
				default: return;
			} else return;
			//
			exprs.pop();
			e.def = SfWhile(cond, loop, false);
		}, []);
	}
	
	public static function fixRedundantBoolAssigns(e:SfExpr, w:Array<SfExpr>, f) {
		e.iter(w, f);
		switch (e.def) {
			case SfIf(cond,
				_.def => SfBinop(OpAssign, thenTarget, _.unpack().def => SfConst(TBool(true))),
				true,
				_.def => SfBinop(OpAssign, elseTarget, _.unpack().def => SfConst(TBool(false)))
			): {
				switch (cond.unpack().def) {
					case SfBinop(OpEq | OpNotEq | OpGt | OpGte | OpLt | OpLte | OpBoolAnd | OpBoolOr, _, _): {};
					default: return;
				}
				if (!thenTarget.equals(elseTarget)) return;
				e.def = SfBinop(OpAssign, thenTarget, cond);
				
				// oh, but was it a `var tmp; if (x) tmp = true; else tmp = false; if (tmp)`?
				var tempVar = switch (thenTarget.def) {
					case SfLocal(_v) if (StringTools.startsWith(_v.name, "tmp")): _v;
					default: return;
				}
				
				//
				var outer = w[0];
				if (outer == null) return;
				var outerExprs = switch (outer.def) {
					case SfBlock(_exprs): _exprs;
					default: return;
				}
				
				//
				var exprAt = outerExprs.indexOf(e);
				if (exprAt <= 0 || exprAt >= outerExprs.length - 1) return;
				
				switch (outerExprs[exprAt - 1].def) {
					case SfVarDecl(_v, false, _) if (_v.equals(tempVar)): {}
					default: return;
				}
				
				if (outer.countLocal(tempVar) != 2) return;
				if (outerExprs[exprAt + 1].countLocal(tempVar) != 1) return;
				outerExprs[exprAt + 1].replaceLocal(tempVar, cond);
				outerExprs.splice(exprAt - 1, 2);
			}
			default:
		}
	}
	
	override public function apply() {
		forEachExpr(fixInlinePrefixes, []);
		forEachExpr(fixRedundantBoolAssigns, []);
		// `var t = c ? a : b; r = t` -> `if (c) r = a; else r = b;`
		forEachExpr(function(e:SfExpr, w, f) {
			e.iter(w, f);
			//
			var exprs = switch (e.def) {
				case SfBlock(m): m;
				default: return;
			}
			//
			var i = exprs.length;
			while (--i >= 1) {
				var prev = exprs[i - 1];
				// `var v = ?`:
				var v:SfVar, vx:SfExpr;
				switch (prev.def) {
					case SfVarDecl(v1, true, vx1): v = v1; vx = vx1;
					default: continue;
				}
				// `var v = (c ? a : b)`:
				var c, a, b;
				switch (vx.def) {
					case SfIf(c1, a1, true, b1): c = c1; a = a1; b = b1;
					default: continue;
				}
				// `r = v`:
				var curr = exprs[i];
				switch (curr.def) {
					case SfBinop(OpAssign,
						r, _.def => SfLocal(v1)
					) if (v.equals(v1) && e.countLocal(v) == 1): {
						exprs[i] = curr.mod(SfIf(c,
							a.mod(SfBinop(OpAssign, r, a)), true,
							b.mod(SfBinop(OpAssign, r.clone(), b))
						));
						exprs.splice(--i, 1);
					};
					default:
				}
			} // while
		});
		// deinline simple ternary blocks:
		procTenary();
		//
		forEachExpr(fixInlinePairBlock, []);
		fixSimpleInlineJuggling();
		fixSimpleInlineBlockAssign();
		fixInlineWhileLoopConditionBlock();
		restoreDoWhile();
		forEachExpr(restoreBoolAndReturn);
		forEachExpr(restoreBoolOrReturn);
		forEachExpr(flipIfNot);
		//
	}
	
}
