package sf.opt;
import sf.type.SfClass;
import sf.type.SfClassField;
import sf.type.expr.SfExpr;
import sf.SfCore.*;
import sf.type.expr.SfExprTools.SfExprIter;
import sf.type.expr.SfExprTools.SfExprMatchIter;

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
	
	public function forEachClassField(func:SfClassField->Void) {
		var g = sfGenerator;
		for (_class in g.classList) {
			currentClass = _class;
			currentField = null;
			for (_field in _class.fieldList) {
				xt2 = _field;
				currentField = _field;
				func(_field);
			}
			if (_class.constructor != null) {
				xt2 = _class.constructor;
				currentField = _class.constructor;
				func(_class.constructor);
			}
		}
		currentClass = null;
		currentField = null;
	}
	
	/** Applies an iterator to every top-level expression in the project. */
	public function forEachExpr(func:SfExprIter, ?stack:Array<SfExpr>) {
		var g = sfGenerator;
		function f(e1:SfExpr):Void {
			var e = e1;
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
