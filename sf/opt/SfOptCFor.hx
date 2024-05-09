package sf.opt;

import sf.opt.SfOptImpl;
import sf.type.expr.SfExprDef.*;
import sf.type.*;
import sf.type.expr.*;
using sf.type.expr.SfExprTools;

/**
 * Creates SfCFor structures out of matching { init; while (cond) { expr; post; } } blocks.
 * @author YellowAfterlife
 */
class SfOptCFor extends SfOptImpl {
	public function isValidInit(init:SfExpr, cond:SfExpr, loop:SfExpr, aWhile:SfExpr, block:SfExpr):Bool {
		switch (init.unpack().def) {
			case SfBlock(_): return false;
			case SfIf(_, _, _): return false;
			case SfWhile(_, _, _): return false;
			case SfCFor(_, _, _, _): return false;
			case SfForEach(_, _, _): return false;
			case SfSwitch(_, _, _): return false;
			case SfBreak | SfContinue: return false;
			case SfReturn(_): return false;
			case SfTry(_, _): return false;
			case SfThrow(_): return false;
			#if (gml)
			case SfCall(_, _): return false; // illegal now
			#end
			case SfVarDecl(v, z, _): {
				if (!z) return false;
				// declaration of a seemingly unrelated variable?
				if (cond.countLocal(v) == 0) return false;
				// not declared just for this loop?
				if (block.countLocal(v) > aWhile.countLocal(v)) return false;
			};
			case SfBinop(OpAssign, _.def => SfLocal(v), _): {
				// assignment of a seemingly unrelated variable
				if (cond.countLocal(v) == 0) return false;
			};
			case SfBinop(_, _, _): return false;
			default:
		}
		return true;
	}
	public function isValidPost(init:SfExpr, cond:SfExpr, loop:SfExpr, post:SfExpr):Bool {
		switch (post.unpack().def) {
			case SfVarDecl(_, _): return false;
			case SfBlock(_): return false;
			case SfIf(_, _, _): return false;
			case SfWhile(_, _, _): return false;
			case SfCFor(_, _, _, _): return false;
			case SfForEach(_, _, _): return false;
			case SfSwitch(_, _, _): return false;
			case SfBreak | SfContinue: return false;
			case SfReturn(_): return false;
			case SfTry(_, _): return false;
			case SfThrow(_): return false;
			// (or other non-standard things):
			case SfCall(_, _): return false;
			default:
		};
		return true;
	}
	public function isValidLoop(init:SfExpr, cond:SfExpr, loop:SfExpr, post:SfExpr):Bool {
		return true;
	}
	
	public function canMergePreInit(preInit:SfExpr, init:SfExpr, cond:SfExpr, loop:SfExpr, post:SfExpr, _while:SfExpr, blockNode:SfExpr):Bool {
		var v = switch (preInit.def) {
			case SfVarDecl(v, true, expr): v;
			default: return false;
		}
		//
		if (blockNode.countLocal(v) > _while.countLocal(v)) return false;
		//
		return true;
	}
	public function mergePreInit(preInit:SfExpr, init:SfExpr, cond:SfExpr, loop:SfExpr, post:SfExpr) {
		var initVar, initExpr;
		switch (init.def) {
			case SfVarDecl(v, true, x = _.def => SfConst(_)):
				initVar = v;
				initExpr = loop.countLocalExt(v).writes == 0 ? x : null;
			case SfVarDecl(v, true, x = _.def => SfLocal(otherVar)):
				initVar = v;
				initExpr = loop.countLocal(otherVar) == 0 ? x : null;
			case SfVarDecl(v, true, x):
				initVar = v;
				initExpr = null;
			default:
				initVar = null;
				initExpr = null;
		}
		//
		if (initExpr != null) {
			cond.replaceLocal(initVar, initExpr);
			loop.replaceLocal(initVar, initExpr);
			post.replaceLocal(initVar, initExpr);
			init.def = preInit.def;
			preInit.def = SfBlock([]);
		} else if (initVar != null
			&& (cond.countLocal(initVar) > 0 || loop.countLocal(initVar) > 0)
		) {
			#if gml
			init.setTo(SfBlock([
				preInit.mod(preInit.def),
				init.mod(init.def),
			]));
			preInit.def = SfBlock([]);
			#end
		}
	}
	
	function eachRec(block:SfExpr, w, f) {
		block.iter(w, f);
		do switch (block.def) {
			case SfBlock(nodes): {
				// [_init, SfWhile(_cond, _loop = SfBlock(_exprs), true)]
				var index = 0;
				var length = nodes.length;
				while (++index < length) {
					var preInit:SfExpr, init:SfExpr, cond:SfExpr, loop:SfExpr, data;
					var _while = nodes[index];
					var exprs:Array<SfExpr>, exprNum:Int;
					switch (_while.def) {
						case SfWhile(c, x = _.def => SfBlock(m), true): {
							exprNum = m.length;
							if (exprNum < 2) continue;
							preInit = nodes[index - 2];
							init = nodes[index - 1];
							data = _while.getData();
							cond = c;
							loop = x;
							exprs = m;
						};
						default: continue;
					}
					
					// Avoid producing odd for-loops:
					if (!isValidInit(init, cond, loop, _while, block)) continue;
					
					// Post-action cannot be a block:
					var post:SfExpr = exprs[exprNum - 1];
					if (!isValidPost(init, cond, loop, post)) continue;
					
					//
					if (!isValidLoop(init, cond, loop, post)) continue;
					
					//Sys.println("blcok: " + e.dump());
					//init.warning("init: " + init);
					//cond.warning("cond: " + cond);
					//loop.warning("loop: " + loop);
					//post.warning("post: " + post);
					
					// Ensure that the post-block does not use variables from body-block:
					var scopeValid = true;
					function checkScope(e:SfExpr, w, f) {
						if (scopeValid) switch (e.def) {
							case SfVarDecl(v, _, _): {
								if (post.countLocal(v) > 0) {
									scopeValid = false;
								}
							};
							default: e.iter(w, f);
						}
					}
					var i = exprNum - 1;
					while (--i >= 0) {
						checkScope(exprs[i], w, checkScope);
						if (!scopeValid) break;
					}
					if (!scopeValid) continue;
					
					// Ensure that continue-statements are paired with `post` copies:
					var notcfor = false;
					function check(e:SfExpr, w, f) {
						if (notcfor) return;
						switch (e.def) {
							case SfBlock([_post, _.def => SfContinue]): {
								if (!post.equals(_post)) notcfor = true;
							};
							case SfContinue: notcfor = true;
							default: e.iter(w, f);
						}
					}
					var i = exprNum - 1;
					while (--i >= 0) {
						check(exprs[i], w, check);
						if (notcfor) break;
					}
					if (notcfor) continue;
					
					// a number iterator perhaps?
					if (preInit != null
						&& canMergePreInit(preInit, init, cond, loop, post, _while, block)
					) {
						mergePreInit(preInit, init, cond, loop, post);
					}
					exprs.pop(); // remove post-expr
					
					// replace `{ $post; continue; }` with `continue;`:
					function replace(e:SfExpr, w, f) {
						switch (e.def) {
							case SfBlock([_, _.def => SfContinue]): e.setTo(SfContinue);
							default: e.iter(w, f);
						}
					}; replace(loop, null, replace);
					
					//
					nodes[index] = new SfExpr(data, SfCFor(init, cond.unpack(), post, loop));
					nodes.splice(index - 1, 1);
					index--;
					length--;
				};
			};
			default:
		} while (false);
	}
	function eachRoot(e:SfExpr, w, f) {
		if (currentField != null && currentField.meta.has(":noCFor")) return;
		eachRec(e, w, eachRec);
	}
	override public function apply() {
		var blockScoping = SfCore.sfConfig.blockScoping;
		forEachExpr(eachRoot);
	}
	
}
