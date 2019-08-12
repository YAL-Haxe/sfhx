package sf.type.expr;
import haxe.macro.Expr;
import haxe.macro.Expr.Binop;
import haxe.macro.Expr.Unop;
import haxe.macro.Type;
import sf.type.expr.SfExpr;

/**
 * ...
 * @author YellowAfterlife
 */
enum SfExprDef {
	
	/** A constant */
	SfConst(c:TConstant);
	
	/** Local variable */
	SfLocal(v:SfVar);
	
	/** A raw piece of target-specific code. For all your horrible hacks. */
	SfDynamic(code:String, args:Array<SfExpr>);
	
	/** array[index] */
	SfArrayAccess(array:SfExpr, index:SfExpr);
	
	/** enumValue[index]. 0 -> name, 1 -> ctrIndex, 2+ -> data */
	SfEnumAccess(expr:SfExpr, sfEnum:SfEnum, index:SfExpr);
	
	/** enumValue[fieldIndex] */
	SfEnumParameter(expr:SfExpr, field:SfEnumCtr, index:Int);
	
	/** a @ b*/
	SfBinop(op:Binop, a:SfExpr, b:SfExpr);
	
	/** @ expr */
	SfUnop(op:Unop, postFix:Bool, expr:SfExpr);
	
	/** inst.field */
	SfInstField(inst:SfExpr, field:SfClassField);
	
	/** class.field */
	SfStaticField(source:SfClass, field:SfClassField);
	
	/** class.func */
	SfClosureField(inst:SfExpr, field:SfClassField);
	
	/** object.field */
	SfDynamicField(object:SfExpr, fieldName:String);
	
	/** Enum.Ctr(...) */
	SfEnumField(source:SfEnum, field:SfEnumCtr);
	
	/** Type */
	SfTypeExpr(t:SfType);
	
	/** (expr) */
	SfParenthesis(expr:SfExpr);
	
	/** { name1: expr1, name2: expr2, ... } */
	SfObjectDecl(fields:Array<{ name: String, expr: SfExpr }>);
	
	/** [expr1, expr2, ...] */
	SfArrayDecl(values:Array<SfExpr>);
	
	/** expr(...args) */
	SfCall(expr:SfExpr, args:Array<SfExpr>);
	
	/** trace(...) */
	SfTrace(data:SfTraceData, args:Array<SfExpr>);
	
	/** new ClassName(...args) */
	SfNew(proto:SfClass, params:Array<Type>, args:Array<SfExpr>);
	
	/** function(...) { ... } */
	SfFunction(func:SfExprFunction);
	
	/** var name[=value] */
	SfVarDecl(v:SfVar, set:Bool, expr:Null<SfExpr>);
	
	/** { ... } */
	SfBlock(exprs:Array<SfExpr>);
	
	/** if (cond) ethen else eelse*/
	SfIf(cond:SfExpr, ethen:SfExpr, hasElse:Bool, eelse:Null<SfExpr>);
	
	/** while (cond) expr \ do expr while (cond) */
	SfWhile(cond:SfExpr, expr:SfExpr, normalWhile:Bool);
	
	/** for (init; cond; post) expr */
	SfCFor(init:SfExpr, cond:SfExpr, post:SfExpr, expr:SfExpr);
	
	/** for (value in iter) expr */
	SfForEach(iterator:SfVar, iterable:SfExpr, expr:SfExpr);
	
	/** switch (expr) { ...cases, default } */
	SfSwitch(expr:SfExpr, cases:Array<SfExprCase>, hasDefault:Bool, edefault:SfExpr);
	
	/** try expr [...catch (v:Type) expr]*/
	SfTry(expr:SfExpr, catches:Array<SfExprCatch>);
	
	/** return[ expr] */
	SfReturn(set:Bool, expr:Null<SfExpr>);
	
	/** break */
	SfBreak();
	
	/** continue */
	SfContinue();
	
	/** throw expr */
	SfThrow(expr:SfExpr);
	
	/** cast expr:type */
	SfCast(expr:SfExpr, type:SfType);
	
	/** typeof expr */
	SfTypeOf(expr:SfExpr);
	
	/** (expr instanceof type) */
	SfInstanceOf(expr:SfExpr, type:SfExpr);
	
	/** (@meta(...)expr) */
	SfMeta(meta:MetadataEntry, expr:SfExpr);
	
	/** JS-specific (a === b), is resolved in SfOptInstanceOf */
	SfStrictEq(a:SfExpr, b:SfExpr);
}
