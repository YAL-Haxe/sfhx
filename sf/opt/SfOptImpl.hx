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
	
	/** Causes forEach* operations to skip extern/@:remove items */
	public var ignoreHidden:Bool;
	
	public function forEachClassField(func:SfClassField->Void) {
		var g = sfGenerator;
		for (_class in g.classList) {
			if (ignoreHidden && _class.isHidden) continue;
			currentClass = _class;
			currentField = null;
			for (_field in _class.fieldList) {
				if (ignoreHidden && _field.isHidden) continue;
				xt2 = _field;
				currentField = _field;
				func(_field);
			}
			if (_class.constructor != null && (!ignoreHidden || !_class.constructor.isHidden)) {
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
			if (ignoreHidden && _class.isHidden) continue;
			currentClass = _class;
			currentField = null;
			f(_class.init);
			//
			for (_field in _class.fieldList) {
				if (ignoreHidden && _field.isHidden) continue;
				xt2 = _field.expr;
				currentField = _field;
				f(_field.expr);
			}
			//
			var _new = _class.constructor;
			if (_new != null && (!ignoreHidden || !_new.isHidden)) {
				currentField = _new;
				xt2 = _new.expr;
				f(_new.expr);
			}
		}
		currentClass = null;
		currentField = null;
		f(g.mainExpr);
	}
	
	public function matchEachExpr(func:SfExprMatchIter, ?stack:Array<SfExpr>):Bool {
		var e:SfExpr;
		var g = sfGenerator;
		var fx:SfExpr;
		inline function f(x:SfExpr):Bool {
			fx = x;
			return fx != null && func(fx, stack, func);
		}
		for (_class in g.classList) {
			if (ignoreHidden && _class.isHidden) continue;
			currentClass = _class;
			currentField = null;
			if (f(_class.init)) return true;
			//
			for (_field in _class.fieldList) {
				if (ignoreHidden && _field.isHidden) continue;
				xt2 = _field.expr;
				currentField = _field;
				if (f(_field.expr)) return true;
			}
			//
			var _new = _class.constructor;
			if (_new != null && (!ignoreHidden || !_new.isHidden)) {
				currentField = _new;
				xt2 = _new.expr;
				if (f(_new.expr)) return true;
			}
		}
		//
		currentClass = null;
		currentField = null;
		if (f(g.mainExpr)) return true;
		//
		return false;
	}
}
