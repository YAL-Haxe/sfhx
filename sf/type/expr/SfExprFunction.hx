package sf.type.expr;
import haxe.macro.Type;

/**
 * A function expression
 * @author YellowAfterlife
 */
typedef SfExprFunction = {
	/** We'll try to resolve the name if possible */
	var ?name:String;
	
	/** Associated variable, if assigned on declaration */
	var ?sfvar:SfVar;
	
	var args:Array<SfArgument>;
	var ret:Type;
	var expr:SfExpr;
};