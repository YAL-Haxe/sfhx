package sf.macro;
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.TypeTools;

/**
 * ...
 * @author YellowAfterlife
 */
@:noCompletion
class StaticAccess {
	public static macro function build():Array<Field> {
		var fields = Context.getBuildFields();
		var result = fields.slice(0);
		for (fd in fields) {
			var fn:Function = switch (fd.kind) {
				case FFun(f): f;
				default: continue;
			};
			if (fd.access.indexOf(APublic) < 0) continue;
			if (fd.access.indexOf(AStatic) >= 0) continue;
			if (fd.name == "new") continue;
			var p = fd.pos;
			//
			var args:Array<Expr> = [];
			for (arg in fn.args) args.push({ expr: EConst(CIdent(arg.name)), pos: p });
			var expr:Expr = {
				expr: ECall({
					expr: EField({
						expr: EConst(CIdent("self")),
						pos: p,
					}, fd.name),
					pos: p,
				}, args),
				pos: p,
			};
			switch (fn.ret) {
				case TPath({ name: "Void" }): { };
				default: expr = { expr: EReturn(expr), pos: p };
			}
			//
			var meta:Metadata = [];
			var addNative:Bool = true;
			if (fd.meta != null) for (m in fd.meta) {
				switch (m.name) {
					case ":native": addNative = false;
					default: { };
				}
				meta.push(m);
			}
			if (addNative) meta.push({
				name: ":native",
				params: [{ expr: EConst(CString(fd.name)), pos: p }],
				pos: p
			});
			//
			result.push({
				name: "__" + fd.name,
				doc: fd.doc,
				access: [APublic, AStatic],
				pos: p,
				kind: FFun({
					args: [{
						name: "self",
						type: TypeTools.toComplexType(Context.getLocalType()),
					}].concat(fn.args),
					ret: fn.ret,
					expr: expr,
					params: fn.params
				}),
				meta: meta,
			});
		}
		return result;
	}
	private static macro function build_6013(clx:Expr):Array<Field> {
		var clt = Context.getType(ExprTools.toString(clx));
		var c:ClassType = switch (clt) {
			case Type.TInst(_.get() => v, _): v;
			default: {
				Context.error("Target type should be a class.", Context.currentPos());
				null;
			};
		}
		var cplt = TypeTools.toComplexType(clt);
		var r:Array<Field> = [];
		var c_fields:Array<ClassField> = c.fields.get();
		for (cf in c_fields) {
			if (!cf.isPublic) continue;
			if (!cf.kind.match(FMethod(MethNormal))) continue;
			switch (cf.expr().expr) {
				case TFunction(f): {
					var p = cf.pos;
					var rw:Array<FunctionArg> = [{ name: "self", type: cplt }];
					var xw:Array<Expr> = [];
					for (arg in f.args) {
						var argv = arg.v;
						var argq = arg.value;
						var argc:Constant = null;
						if (argq != null) argc = switch (argq) {
							case TInt(i): CInt(Std.string(i));
							case TFloat(s): CFloat(s);
							case TString(s): CString(s);
							case TBool(b): CIdent(b ? "true" : "false");
							case TThis: CIdent("this");
							case TNull: CIdent("null");
							case TSuper: CIdent("super");
						};
						rw.push({
							name: argv.name,
							type: TypeTools.toComplexType(argv.t),
							opt: arg.value != null,
							value: argc != null ? { expr: EConst(argc), pos: p } : null,
						});
						xw.push({ expr: EConst(CIdent(argv.name)), pos: p });
					}
					var rx = {
						expr: ECall({
							expr: EField({
								expr: EConst(CIdent("self")),
								pos: p
							}, cf.name),
							pos: p
						}, xw),
						pos: p
					};
					switch (f.t) {
						case TAbstract(_.get() => { name: "Void" }, _): { };
						default: rx = { expr: EReturn(rx), pos: p };
					}
					var md:Metadata = [];
					if (cf.meta.has(":doc")) md.push({ name: ":doc", pos: p });
					if (cf.meta.has(":native")) md.push({
						name: ":native",
						params: cf.meta.extract(":native")[0].params,
						pos: p
					});
					r.push({
						name: cf.name,
						doc: cf.doc,
						access: [APublic, AStatic],
						pos: p,
						kind: FFun({
							args: rw,
							ret: TypeTools.toComplexType(f.t),
							expr: rx
							// todo: params
						}),
						meta: md,
					});
				};
				default:
			} // switch
		} // for fields
		return r;
	}
}
