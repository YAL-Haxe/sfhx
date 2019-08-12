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
						var status = 0;
						while (++i < n && status >= 0) {
							switch (_caseExprs[i].def) {
								case SfVarDecl(_var, true,
									_repl = _.def => SfEnumParameter(_src, _, _index)
								) if (_src.equals(_enumValue)): {
									if (status == 0) {
										if (_caseExpr.countLocalExt(_enumVar).writes > 0) {
											status = -1;
											continue;
										} else status = 1;
									}
									var found = _caseExpr.countLocalMax(_var);
									if (found <= 1) {
										if (found > 0) _caseExpr.replaceLocal(_var, _repl);
										_caseExprs.splice(i, 1);
										i -= 1;
										n -= 1;
									}
								};
								default: status = -1;
							};
						}
					};
				};
				default:
			} while (false);
		});
	}
	
}
