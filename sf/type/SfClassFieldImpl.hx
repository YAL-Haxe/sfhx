package sf.type;
import haxe.macro.Type;
import sf.type.SfBuffer;
import sf.SfCore.printf;
import sf.type.SfExprDef.*;

/**
 * ...
 * @author YellowAfterlife
 */
class SfClassFieldImpl extends SfField {
	
	/** */
	public var classField:ClassField;
	
	/** Parent class structure. null for anon fields */
	public var parentClass:SfClass;
	
	/** */
	public var kind:FieldKind;
	
	/** */
	public var func:TFunc = null;
	
	/** */
	public var expr:SfExpr;
	
	/** */
	public var typedExpr:TypedExpr;
	
	/** Whether this is an instance field. */
	public var isInst:Bool = false;
	
	/** Whether this is a variable (or a dynamic function) */
	public var isVar:Bool = true;
	
	/** Whether this is a dynamic function */
	public var isDynFunc:Bool = false;
	
	@:noCompletion public var cachedExpr:SfExpr = null;
	public function toExpr(?inst:SfExpr):SfExpr {
		var r = cachedExpr;
		if (r == null) {
			var data = { expr: null, pos: this.classField.pos, t: this.classField.type };
			if (isInst) {
				if (inst == null) {
					throw "Can't create expression for instance field without reference.";
				}
				r = new SfExpr(data, SfInstField(inst, cast this));
			} else {
				if (parentClass != null) {
					r = new SfExpr(data, SfStaticField(parentClass, cast this));
				} else haxe.macro.Context.error(
					"SfClassFieldImpl.toExpr: parent is not a class.",
					classField.pos);
			}
			cachedExpr = r;
		}
		return r;
	}
	
	public function new(parent:SfType, field:ClassField, inst:Bool) {
		super(parent, field);
		classField = field;
		if (Std.is(parent, SfClass)) {
			parentClass = cast parent;
		} else parentClass = null;
		kind = field.kind;
		typedExpr = field.expr();
		switch (type) {
			case TFun(f_args, f_out): {
				switch (kind) {
					case FMethod(MethDynamic) | FVar(_, _): isDynFunc = true;
					default: {
						if (meta.has(":isVar")) {
							isDynFunc = true;
						} else isVar = false;
					}
				}
				isCallable = true;
				type = f_out;
				var sfArgs:Array<SfArgument> = null;
				// if typedExpr is available, get argument data from it:
				if (typedExpr != null) switch (typedExpr.expr) {
					case TFunction(f): {
						sfArgs = [];
						for (f_arg in f.args) sfArgs.push(SfArgument.fromTyped(f_arg));
						type = f.t;
						typedExpr = f.expr;
					};
					default:
				}
				// otherwise get argument data from TFun:
				if (sfArgs == null) {
					sfArgs = [];
					if (f_args != null) for (arg in f_args) sfArgs.push(new SfArgument(
						new SfVar(arg.name, arg.t),
						arg.opt ? TNull : null
					));
				}
				this.args = sfArgs;
			};
			default:
		};
		isInst = inst;
	}
	
	override public function dumpTo(out:SfBuffer):Void {
		var metas = classField.meta.get();
		if (metas.length > 0) {
			SfDump.meta(metas, out); printf(out, "\n");
		}
		if (isHidden) printf(out, "extern ");
		if (classField.isPublic) printf(out, "public ");
		if (!isInst) printf(out, "static ");
		switch (classField.kind) {
			case FMethod(mk): switch (mk) {
				case MethInline: printf(out, "inline ");
				case MethDynamic: printf(out, "dynamic ");
				default:
			}
			default:
		}
		if (isVar && !isCallable) {
			printf(out, "var %s:", name); SfDump.type(type, out);
			if (expr != null) {
				printf(out, " = ");
				sf.type.SfDump.expr(expr, out);
			}
			printf(out, ";");
		} else {
			printf(out, "function %s(", name);
			dumpArguments(out);
			printf(out, "):");
			SfDump.type(type, out);
			if (expr != null) {
				out.addChar(" ".code);
				switch (expr.def) {
					case SfBlock(_): SfDump.expr(expr, out);
					default: {
						out.addChar("{".code);
						out.addLine(1);
						SfDump.expr(expr, out);
						out.addSemico();
						out.addLine( -1);
						out.addChar("}".code); 
					}
				};
			} else out.addSemico();
		}
	}
}
