package sf.opt;
import sf.type.SfClass;
import sf.type.SfClassField;
import sf.type.SfExpr;
import sf.SfCore.*;
import sf.type.SfExprTools.SfExprIter;
import sf.type.SfExprTools.SfExprMatchIter;

/**
 * ...
 * @author YellowAfterlife
 */
class SfOptImpl {
	
	public function new() {
		xt = Type.getClassName(Type.getClass(this));
	}
	
	/** The magic goes here */
	public function apply() {
		
	}
	
	public var currentClass:SfClass;
	public var currentField:SfClassField;
	
	/** Applies an iterator to every top-level expression in the project. */
	public function forEachExpr(func:SfExprIter, ?stack:Array<SfExpr>) {
		var e:SfExpr;
		var g = sfGenerator;
		/*inline*/ function f(e1:SfExpr):Void {
			e = e1;
			if (e != null) {
				func(e, stack, func);
			}
		}
		for (_class in g.classList) {
			currentClass = _class;
			currentField = null;
			f(_class.init);
			for (_field in _class.fieldList) {
				xt2 = _field.expr;
				currentField = _field;
				f(_field.expr);
			}
			if (_class.constructor != null) {
				currentField = _class.constructor;
				xt2 = currentField.expr;
				f(_class.constructor.expr);
			}
		}
		currentClass = null;
		currentField = null;
		f(g.mainExpr);
	}
	
	public function matchEachExpr(func:SfExprMatchIter, ?stack:Array<SfExpr>):Bool {
		var e:SfExpr;
		var g = sfGenerator;
		inline function f(x:SfExpr):Bool {
			return func(x, stack, func);
		}
		for (c in g.classList) {
			currentClass = c;
			e = c.init;
			if (e != null) {
				currentField = null;
				if (f(e)) return true;
			}
			var ctr = c.constructor;
			if (ctr != null) {
				e = ctr.expr;
				if (e != null) {
					currentField = ctr;
					if (f(e)) return true;
				}
			}
			for (q in c.fieldList) {
				e = q.expr;
				if (e != null) {
					currentField = q;
					if (f(e)) return true;
				}
			}
		}
		e = g.mainExpr;
		if (e != null) {
			currentClass = null;
			currentField = null;
			if (f(e)) return true;
		}
		return false;
	}
}
