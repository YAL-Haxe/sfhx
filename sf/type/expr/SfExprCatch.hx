package sf.type.expr;

/**
 * A try-catch block
 * @author YellowAfterlife
 */
typedef SfExprCatch = {
	/** capture variable */
	var v:SfVar;
	
	/** catch-block */
	var expr:SfExpr;
};