package sf.opt;

import sf.opt.SfOptImpl;
import sf.type.expr.SfExprDef.*;
import sf.type.*;
import sf.type.expr.*;
using sf.type.expr.SfExprTools;
import haxe.macro.Expr.Binop.*;
import haxe.macro.Expr.Unop.*;

/**
 * ...
 * @author YellowAfterlife
 */
class SfOptForInt extends SfOptImpl {
	
	override public function apply() {
		forEachExpr(function(e:SfExpr, w, f) {
			e.iter(w, f);
			function proc(
				v:SfVar, v1:SfVar, _decl:SfExpr, _from:SfExpr,
				_read:SfExpr, _loop:SfExpr, _loopExprs:Array<SfExpr>
			):Void {
				if (_loopExprs.length > 1 && v.equals(v1)) switch (_loopExprs[0].def) {
					case SfVarDecl(_iter, true,
						_.def => SfUnop(OpIncrement, true, _.def => SfLocal(v2))
					): {
						if (v.equals(v2) && _loop.countLocalExt(v).writes == 1) {
							_loopExprs.shift();
							var _post = e.mod(SfUnop(OpIncrement, true,
								e.mod(SfLocal(_iter))
							));
							_loopExprs.push(_post);
							function patchContinue(e:SfExpr, w, f) {
								e.iter(w, f);
								switch (e.def) {
									case SfContinue: e.setTo(SfBlock([
										_post.clone(), 
										e.mod(SfContinue),
									]));
									default:
								}
							}; patchContinue(_loop, null, patchContinue);
							_decl.setTo(SfVarDecl(_iter, true, _from));
							_read.setTo(SfLocal(_iter));
						}
					};
					default:
				}
			}
			switch (e.def) {
				case SfBlock([
					_decl = _.def => SfVarDecl(v, true, _from),
					_.def => SfWhile(_.def => SfParenthesis(_.def => SfBinop(OpLt,
								_read = _.def => SfLocal(v1),
							_)
						),
						_loop = _.def => SfBlock(_loopExprs),
					true)
				]): proc(v, v1, _decl, _from, _read, _loop, _loopExprs);
				case SfBlock([
					_decl = _.def => SfVarDecl(v, true, _from),
					_.def => SfVarDecl(t, _),
					_.def => SfWhile(
						_.def => SfParenthesis(_.def => SfBinop(OpLt,
								_read = _.def => SfLocal(v1),
								_.def => SfLocal(t1)
							)
						),
						_loop = _.def => SfBlock(_loopExprs),
					true)
				]): if (t.equals(t1)) proc(v, v1, _decl, _from, _read, _loop, _loopExprs);
				default:
			}
		});
	}
	
}
