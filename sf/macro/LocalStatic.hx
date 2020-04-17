package sf.macro;
import haxe.ds.Map;
import haxe.macro.Context;
import haxe.macro.Expr;
using haxe.macro.ExprTools;

/**
 * Allows to do
 * @:static var x = ...
 * inside methods, which will create static variables only visible for that method.
 * @author YellowAfterlife
 */
class LocalStatic {
	public static macro function build():Array<Field> {
		#if display
		return null;
		#else
		var fields = Context.getBuildFields();
		var newFields:Array<Field> = [];
		var fieldMap = new Map<String, Field>();
		for (fd in fields) fieldMap[fd.name] = fd;
		for (fd in fields) switch (fd.kind) {
			case FFun(f): {
				var found = new Map<String, String>();
				function rec(e:Expr):Expr {
					switch (e.expr) {
						case EMeta({ name: ":static" }, _.expr => EVars(vs)): {
							for (v in vs) {
								var v1pre = "__" + fd.name + "__" + v.name;
								var v1 = v1pre, v1ind = 0;
								while (fieldMap.exists(v1)) v1 = v1pre + "_" + ++v1ind;
								found[v.name] = v1;
								var sfd:Field = {
									name: v1,
									kind: FVar(v.type, v.expr),
									access: [APrivate, AStatic],
									pos: e.pos,
									meta: [{ name: ":noCompletion", pos: e.pos }],
								};
								fieldMap[v1] = sfd;
								newFields.push(sfd);
							}
							return { expr: EBlock([]), pos: e.pos };
						};
						case EConst(CIdent(s)): {
							var v1 = found[s];
							if (v1 != null) return {
								expr: EConst(CIdent(v1)),
								pos: e.pos,
							};
						};
						default:
					}
					return e.map(rec);
				}
				if (f.expr != null) {
					f.expr = rec(f.expr);
				}
			};
			default:
		}
		return fields.concat(newFields);
		#end
	}
}