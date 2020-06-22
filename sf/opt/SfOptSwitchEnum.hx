package sf.opt;

import sf.opt.SfOptImpl;
import sf.type.expr.SfExprDef.*;
import sf.type.*;
import sf.type.expr.*;
using sf.type.expr.SfExprTools;

/**
 * Eliminates single-use local variables in switches.
 * @author YellowAfterlife
 */
class SfOptSwitchEnum extends SfOptImpl {
	
	override public function apply() {
		forEachExpr(function(e, w, f) {
			e.iter(w, f);
			do switch (e.def) {
				case SfSwitch(_switchValue, _cases, _, _default): {
					var _enumValue:SfExpr;
					var _enumVar:SfVar;
					switch (_switchValue.unpack().def) {
						case SfEnumAccess(_val, _, _.def => SfConst(TInt(
							#if (gml) 0 #else 1 #end
						))): {
							_enumValue = _val;
							switch (_val.def) {
								case SfLocal(_var): _enumVar = _var;
								default: continue;//_switchValue.warning(_switchValue.dump());
							}
						}
						default: continue;
					}
					for (_case in _cases) {
						var _caseExpr:SfExpr = _case.expr;
						var _caseExprs:Array<SfExpr> = switch (_caseExpr.def) {
							case SfBlock(w): w;
							default: continue;
						};
						var i = -1, n = _caseExprs.length;
						var checkCaseExpr = true;
						while (++i < n) {
							var _repl:SfExpr, _var:SfVar;
							switch (_caseExprs[i].def) {
								case SfVarDecl(v, true,
									r = _.def => SfEnumParameter(_src, _, _index)
								) if (_src.equals(_enumValue)): {
									_var = v;
									_repl = r;
								};
								default: break;
							}
							
							// (on first encountered variable)
							if (checkCaseExpr) {
								if (_caseExpr.countLocalExt(_enumVar).writes > 0) break;
								checkCaseExpr = false;
							}
							
							// Haxe might reuse _g variables! How kind.
							// ... except we wanted to inline _g[ind] in place of one-off variable uses
							// so we have to check if the variable isn't being redeclared
							// and not inline if the original declaration is being shadowed
							var isReDecl = false;
							function checkForRedeclaration(x:SfExpr, st, it) {
								var _stats:Array<SfExpr> = switch (x.def) {
									case SfBlock(_stats1): _stats1;
									case SfLocal(_var1): {
										if (isReDecl && _var1.equals(_var)) {
											//x.warning("redecl of " + _enumVar + " for " + _var);
											return true;
										} else return false;
									}
									default: return x.matchIter(st, it);
								};
								var wasReDecl = isReDecl;
								var result = false;
								for (_stat in _stats) {
									switch (_stat.def) {
										case SfVarDecl(_itvar, _, _) if (_enumVar.name == _itvar.name): {
											isReDecl = true;
										};
										default: {
											if (checkForRedeclaration(_stat, null, it)) {
												result = true;
												break;
											}
										};
									}
								}
								isReDecl = wasReDecl;
								return result;
							}
							if (_caseExpr.matchIter(null, checkForRedeclaration)) {
								continue;
							}
							
							//
							var found = _caseExpr.countLocalMax(_var);
							if (found > 1) continue;
							if (found > 0) _caseExpr.replaceLocal(_var, _repl);
							_caseExprs.splice(i, 1);
							i -= 1;
							n -= 1;
						}
					};
				};
				default:
			} while (false);
		});
	}
	
}
