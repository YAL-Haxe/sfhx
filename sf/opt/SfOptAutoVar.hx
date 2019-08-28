package sf.opt;

import haxe.ds.Map;
import sf.opt.SfOptImpl;
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
		e.iter(w, f);
		switch (e.def) {
			case SfBlock([q = _.def => SfVarDecl(_, _, _)]): {
				e.setTo(q.def);
			};
			case SfBlock(m): {
				var k = m.length - 1;
				while (--k >= 0) switch (m[k].def) {
					case SfVarDecl(v, true, vx): do {
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
						if (vc.reads == 0) {
							if (e.countLocalExt(v).total == 0 && vx.isSimple()) { // not used at all?
								m.splice(k, 1);
							}
							continue;
						}
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
					} while (false);
					default:
				} // switch (m[k])
				if (m.length == 1) e.setTo(m[0].def);
			}; // case SfBlock
			default:
		}
	}
	
	private var inlineVarData:Map<String, { expr:SfExpr, val:SfExpr, par:SfExpr }>;
	public function inlineIter(e:SfExpr, w:SfExprList, f:SfExprIter) {
		e.iter(w, f);
		switch (e.def) {
			case SfVarDecl(v, _, x): {
				inlineVarData.set(v.name, { expr: e, val: x, par: w[0] });
			};
			case SfBlock(xw): {
				var n = xw.length;
				var i = -1; while (++i < n) {
					var curr = xw[i];
					// see that it's var v1 = v0;
					var v0:SfVar, v1:SfVar;
					switch (curr.def) {
						case SfVarDecl(v, true, _.def => SfLocal(vv)): v0 = vv; v1 = v;
						default: continue;
					};
					// see that v0 is declared in this same block:
					var data = inlineVarData.get(v0.name);
					if (data == null || data.par != e) continue;
					// see that v0 is never used again:
					var k = i; while (++k < n) {
						if (xw[k].countLocal(v0) > 0) break;
					}
					if (k < n) continue;
					//
					data.expr.def = SfVarDecl(v1, data.val != null, data.val);
					e.replaceLocal(v0, curr.mod(SfLocal(v1)));
					xw.splice(i, 1);
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
		forEachExpr(mainIter, []);
		forEachExpr(inlineIterOuter, []);
	}
	
}
