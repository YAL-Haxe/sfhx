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
	
	override public function apply() {
		forEachExpr(function(e:SfExpr, w, f) {
			e.iter(w, f);
			do switch (e.def) {
				case SfBlock(nodes): {
					// [_init, SfWhile(_cond, _loop = SfBlock(_exprs), true)]
					var index = 0;
					var length = nodes.length;
					while (++index < length) {
						var init:SfExpr, cond:SfExpr, loop:SfExpr, data;
						var exprs:Array<SfExpr>, exprNum:Int;
						switch (nodes[index].def) {
							case SfWhile(c, x = _.def => SfBlock(m), true): {
								exprNum = m.length;
								if (exprNum < 2) continue;
								init = nodes[index - 1];
								data = nodes[index].getData();
								cond = c;
								loop = x;
								exprs = m;
							};
							default: continue;
						}
						// Avoid producing odd for-loops:
						switch (init.unpack().def) {
							case SfBlock(_): continue;
							case SfIf(_, _, _): continue;
							case SfWhile(_, _, _): continue;
							case SfCFor(_, _, _, _): continue;
							case SfForEach(_, _, _): continue;
							case SfSwitch(_, _, _): continue;
							case SfBreak | SfContinue: continue;
							case SfReturn(_): continue;
							case SfTry(_, _): continue;
							case SfThrow(_): continue;
							#if (gml)
							case SfCall(_, _): continue; // illegal now
							#end
							case SfVarDecl(v, z, _): {
								if (!z) continue;
								if (cond.countLocal(v) == 0) continue;
							};
							case SfBinop(OpAssign, _.def => SfLocal(v), _): {
								if (cond.countLocal(v) == 0) continue;
							};
							case SfBinop(_, _, _): continue;
							default:
						}
						// Post-action cannot be a block:
						var post:SfExpr = exprs[exprNum - 1];
						switch (post.unpack().def) {
							case SfVarDecl(_, _): continue;
							case SfBlock(_): continue;
							case SfIf(_, _, _): continue;
							case SfWhile(_, _, _): continue;
							case SfCFor(_, _, _, _): continue;
							case SfForEach(_, _, _): continue;
							case SfSwitch(_, _, _): continue;
							case SfBreak | SfContinue: continue;
							case SfReturn(_): continue;
							case SfTry(_, _): continue;
							case SfThrow(_): continue;
							// (or other non-standard things):
							case SfCall(_, _): continue;
							default:
						};
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
						exprs.pop();
						// replace `{ $post; continue; }` with `continue;`:
						function replace(e:SfExpr, w, f) {
							switch (e.def) {
								case SfBlock([_, _.def => SfContinue]): e.setTo(SfContinue);
								default: e.iter(w, f);
							}
						}; replace(loop, null, replace);
						nodes[index] = new SfExpr(data, SfCFor(init, cond.unpack(), post, loop));
						nodes.splice(index - 1, 1);
						index--;
						length--;
					};
				};
				default:
			} while (false);
		});
	}
	
}
