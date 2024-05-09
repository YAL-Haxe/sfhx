package sf.opt;

import haxe.ds.Map;
import sf.opt.SfOptImpl;
import sf.opt.SfOptInlineBlock;
import sf.type.expr.SfExprDef.*;
import sf.type.*;
import sf.type.expr.*;
using sf.type.expr.SfExprTools;

/**
 * Merge automatically declared single-use variables before expressions.
 * @author YellowAfterlife
 */
class SfOptAutoVar extends SfOptImpl {
	
	public function hasSideEffects(expr:SfExpr, stack:Array<SfExpr>, repl:SfExpr):Bool {
		var last = expr;
		for (next in stack) {
			switch (next.def) {
				case SfIf(x, _, _)
					|SfBinop(OpBoolAnd | OpBoolOr, x, _)
					|SfSwitch(x, _, _)
					|SfCFor(x, _, _, _)
					: if (x != last) return true;
				case SfWhile(_, _, _)
					|SfForEach(_, _, _)
					|SfTry(_, _)
					|SfUnop(OpIncrement | OpDecrement, _, _)
					: return true;
				default:
			}
			last = next;
		}
		return false;
	}
	
	public function canInsertInto(expr:SfExpr):Bool {
		return true;
	}
	
	public function mainIter(e:SfExpr, w:SfExprList, f:SfExprIter) {
		switch (e.def) {
			case SfCFor(init, cond, post, expr):
				// don't try to merge expressions inside cfor inits,
				// that can eat a variable declaration
				if (w != null) w.unshift(expr);
				f(post, w, f);
				f(expr, w, f);
				if (w != null) w.shift();
			default:
				e.iter(w, f);
		}
		
		switch (e.def) {
			case SfBlock([q = _.def => SfVarDecl(_, _, _)]): {
				e.setTo(q.def);
			};
			case SfBlock(m): {
				var k = m.length - 1;
				while (--k >= 0) {
					var v:SfVar, vx:SfExpr;
					switch (m[k].def) {
						case SfVarDecl(_v, true, _vx): v = _v; vx = _vx;
						default: continue;
					}
					var done = false;
					do {
						// avoid certain expressions:
						switch (vx.def) {
							case SfFunction(_): continue; // don't rearrange functions
							case SfUnop(OpIncrement | OpDecrement, _, _): continue;
							default:
						}
						//
						var next = m[k + 1];
						if (!canInsertInto(next)) continue;
						// must contain exactly one read:
						var vc = next.countLocalExt(v);
						if (vc.writes != 0) continue;
						if (vc.reads != 1) continue;
						// must be the only occurrence in the block too:
						if (e.countLocalExt(v).total != 1) continue;
						//
						function sideEffectsIter(e:SfExpr, w, f) {
							switch (e.def) {
								case SfLocal(v1) if (v1.equals(v)): {
									if (hasSideEffects(e, w, vx)) return true;
								};
								default:
							}
							return e.matchIter(w, f);
						};
						if (sideEffectsIter(e, [], sideEffectsIter)) continue;
						//
						vx.setType(v.type);
						next.replaceLocal(v, vx);
						m.splice(k, 1);
						done = true;
					} while (false);
					if (!done && e.countLocal(v) == 0 && vx.isSimple()) {
						// not used at all?
						m.splice(k, 1);
					}
				}
				if (m.length == 1) e.setTo(m[0].def);
			}; // case SfBlock
			default:
		}
	}
	
	private var inlineVarData:Map<String, { expr:SfExpr, val:SfExpr, par:SfExpr }>;
	public function inlineIter(expr:SfExpr, st:SfExprList, it:SfExprIter) {
		expr.iter(st, it);
		switch (expr.def) {
			case SfVarDecl(v, _, x): {
				inlineVarData.set(v.name, { expr: expr, val: x, par: st[0] });
			};
			case SfBlock(stats): {
				var n = stats.length;
				var i = -1; while (++i < n) {
					var curr = stats[i];
					
					// see that it's `var vDef = /* local */vVal`;
					var vDef:SfVar, vVal:SfVar;
					switch (curr.def) {
						case SfVarDecl(vd, true, _.def => SfLocal(vv)): {
							vDef = vd;
							vVal = vv;
						};
						default: continue;
					};
					
					// see that vVal is declared in this same block:
					var data = inlineVarData.get(vVal.name);
					if (data == null || data.par != expr) continue;
					
					// see that vVal is never used afterwards:
					var k = i; while (++k < n) {
						if (stats[k].countLocal(vVal) > 0) break;
					}
					if (k < n) continue;
					
					//
					data.expr.def = SfVarDecl(vDef, data.val != null, data.val);
					expr.replaceLocal(vVal, curr.mod(SfLocal(vDef)));
					var ndata = inlineVarData[vDef.name];
					if (ndata != null) {
						ndata.expr = data.expr;
						ndata.val = data.val;
					}
					stats.splice(i, 1);
					i -= 1; n -= 1;
				}
			};
			default:
		}
	}
	public function inlineIterOuter(e:SfExpr, w:SfExprList, f:SfExprIter) {
		inlineVarData = new Map();
		inlineIter(e, w, inlineIter);
	}
	
	override public function apply() {
		#if !sf_no_opt_auto_var
		forEachExpr(mainIter, []);
		forEachExpr(inlineIterOuter, []);
		/*
		We need a second pass with this since `if (e.match(E(_))) {}`
		produces `var tmp; if (e.index == E) { var _g = e; ...; tmp = true; } else { tmp = false; }`
		*/
		forEachExpr(SfOptInlineBlock.fixRedundantBoolAssigns, []);
		#end
	}
	
}
