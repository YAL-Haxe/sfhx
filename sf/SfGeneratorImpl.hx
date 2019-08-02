package sf;

import haxe.macro.Context;
import haxe.macro.Expr.Position;
import sf.type.*;
import sf.type.SfTypeImpl;
import sf.opt.*;
import haxe.macro.JSGenApi;
import haxe.macro.Type;
import sys.io.File;
import Type in StdType;
import sf.type.SfTypeMap;

/**
 * ...
 * @author YellowAfterlife
 */
class SfGeneratorImpl {
	
	/** JS Generator */ 
	public var apiTypes:Array<Type>;
	public var apiMain:Null<TypedExpr>;
	public var outputPath:String;
	
	public var typeList:Array<SfType> = [];
	public var typeMap:SfTypeMap<SfType> = new SfTypeMap();
	public var classList:Array<SfClass> = [];
	public var classMap:SfTypeMap<SfClass> = new SfTypeMap();
	public var enumList:Array<SfEnum> = [];
	public var enumMap:SfTypeMap<SfEnum> = new SfTypeMap();
	public var abstractList:Array<SfAbstract> = [];
	public var abstractMap:SfTypeMap<SfAbstract> = new SfTypeMap();
	public var anonList:Array<SfAnon> = [];
	public var anonMap:SfTypeMap<SfAnon> = new SfTypeMap();
	public var realMap:Map<String, SfType> = new Map();
	
	//{ Default types
	public var typeArray:SfClass;
	private var typeArrayPath:String = "Array:Array";
	public var typeClass:SfAbstract;
	private var typeClassPath:String = "Class:Class";
	public var typeVoid:SfAbstract;
	private var typeVoidPath:String = "StdTypes:Void";
	public var typeFloat:SfAbstract;
	private var typeFloatPath:String = "StdTypes:Float";
	public var typeInt:SfAbstract;
	private var typeIntPath:String = "StdTypes:Int";
	public var typeBool:SfAbstract;
	private var typeBoolPath:String = "StdTypes:Bool";
	public var typeDynamic:SfAbstract;
	private var typeDynamicPath:String = "StdTypes:Dynamic";
	public var typeString:SfClass;
	private var typeStringPath:String = "String:String";
	public var typeBoot:SfClass;
	private var typeBootPath:String = "js.Boot:Boot";
	public function typeFind<T:SfType>(path:String, ?kind:Class<T>):T {
		var pos:Int = path.indexOf(":");
		var module:String = path.substring(0, pos);
		var name:String = path.substring(pos + 1);
		var res:T = cast switch (kind) {
			case SfAbstract: abstractMap.get(module, name);
			case SfClass: classMap.get(module, name);
			case SfEnum: enumMap.get(module, name);
			case SfAnon: anonMap.get(module, name);
			default: typeMap.get(module, name);
		}
		return res;
	}
	public function typeFindWrap<T:SfType>(path:String, ?kind:Class<T>):T {
		var res:T = typeFind(path, kind);
		if (res == null) Context.error("SfGeneratorImpl.typeFindWrap: Couldn't find " + path + " in AST.", Context.currentPos());
		return res;
	}
	public function typeFindReal<T:SfType>(path:String, ?kind:Class<T>, ?soft:Bool):T {
		var r:T = cast realMap[path];
		if (r == null && !soft) {
			Context.error('SfGeneratorImpl.typeFindReal: Couldn\'t find $path in AST.'
				+ haxe.CallStack.toString(haxe.CallStack.callStack()), Context.currentPos());
		}
		return r;
	}
	private function typeInit() {
		typeBoot = typeFindReal("js.Boot", SfClass, true);
		typeArray = typeFindReal("Array");
		typeClass = typeFindReal("Class");
		typeVoid = typeFindReal("Void");
		typeFloat = typeFindReal("Float");
		typeInt = typeFindReal("Int");
		typeBool = typeFindReal("Bool");
		typeDynamic = typeFindReal("Dynamic");
		typeString = typeFindReal("String");
	}
	//}
	
	/** "com.package.Type" -> SfType */
	public var featureMap:Map<String, SfType> = new Map();
	public function hasFeature(path:String, field:String = "*"):Bool {
		var sft = featureMap.get(path);
		if (sft != null) {
			if (Std.is(sft, SfClass)) {
				var sfc:SfClass = cast sft;
				return field == "*"
					|| sfc.staticMap.exists(field)
					|| sfc.instMap.exists(field);
			} else return (field == "*");
		} else return false;
	}
	/** Entrypoint expression */
	public var mainExpr:SfExpr = null;
	
	public var currentClass:SfClass = null;
	public var currentField:SfClassField = null;
	
	private function buildTypes() {
		var hasSuperClass = [];
		var sfts:Array<SfType> = [];
		for (nt in apiTypes) {
			inline function addClass(ct:ClassType):Void {
				if (classMap.baseExists(ct)) return;
				var sfc = new SfClass(ct);
				if (ct.superClass != null) hasSuperClass.push(sfc);
				classList.push(sfc);
				classMap.sfSet(sfc, sfc);
				sfts.push(sfc);
			}
			switch (nt) {
				case TInst(_.get() => ct, _): addClass(ct);
				case TEnum(_.get() => et, _): {
					var sfe = new SfEnum(et);
					enumList.push(sfe);
					enumMap.sfSet(sfe, sfe);
					sfts.push(sfe);
				};
				case TAbstract(_.get() => at, _): {
					var sfa = new SfAbstract(at);
					if (at.impl != null) {
						addClass(at.impl.get());
					}
					abstractList.push(sfa);
					abstractMap.sfSet(sfa, sfa);
					sfts.push(sfa);
				};
				case TType(_.get() => dt, _): {
					switch (dt.type) {
						case TAnonymous(_.get() => at): {
							var sfa = new SfAnon(dt, at);
							anonList.push(sfa);
							anonMap.sfSet(sfa, sfa);
							sfts.push(sfa);
						};
						default:
					}
				};
				default:
			} // switch (t)
			for (sft in sfts) {
				typeList.push(sft);
				typeMap.sfSet(sft, sft);
				realMap.set(sft.realPath, sft);
				var b = new SfBuffer();
				b.addTypePath(sft, ".".code);
				featureMap.set(b.toString(), sft);
			}
			sfts.resize(0);
		} // for (nt in api.types)
		
		// resolve abstract implementations:
		for (sfa in abstractList) {
			var impl = sfa.abstractType.impl;
			if (impl != null) {
				sfa.impl = classMap.baseGet(impl.get());
				if (sfa.impl == null) {
					Context.warning("Couldn't find implementation for " + sfa.name, sfa.abstractType.pos);
				} else {
					// abstract metas are split oddly between abstract/impl
					if (!sfa.impl.isExtern && sfa.meta.has(":std")) {
						var pkg = SfCore.sfConfig.stdPack;
						if (pkg != null) sfa.impl.pack.unshift(pkg);
					}
				}
			}
		}
		
		// resolve parent classes:
		for (sfc in hasSuperClass) {
			var sup = classMap.baseGet(sfc.classType.superClass.t.get());
			if (sup != null) {
				sfc.superClass = sup;
				sup.children.push(sfc);
			}
		}
		
		// methods with overrides have to be dynFunc or we'll get the C++ effect
		for (childClass in hasSuperClass) if (!childClass.isExtern) {
			var parentClass = childClass.superClass;
			for (childField in childClass.instList) {
				var fdName = childField.name;
				var isOverride = false;
				var iterClass = parentClass;
				while (iterClass != null) {
					var iterField = iterClass.instMap[fdName];
					if (iterField != null) {
						iterField.isDynFunc = true;
						iterField.isVar = true;
						isOverride = true;
					}
					iterClass = iterClass.superClass;
				}
				if (isOverride) {
					childField.isDynFunc = true;
					childField.isVar = true;
				}
			}
		}
		
		typeInit();
	}
	
	private function getPreproc():SfOptArray {
		var conf = SfCore.sfConfig;
		var r:Array<SfOptImpl> = [];
		r.push(new SfOptEnum());
		r.push(new SfOptFunc());
		r.push(new SfOptForInt());
		if (!conf.forEach) r.push(new SfOptForEach());
		if (conf.cfor) r.push(new SfOptCFor());
		if (conf.instanceof) r.push(new SfOptInstanceOf());
		return r;
	}
	
	private function getOptimizers():SfOptArray {
		var conf = SfCore.sfConfig;
		var r:Array<SfOptImpl> = [];
		if (conf.analyzer) {
			r.push(new SfOptStringConcat());
			r.push(new SfOptSwitchEnum());
			r.push(new SfOptSwitchSimple());
			r.push(new SfOptInlineBlock());
			r.push(new SfOptStrayStatements());
			r.push(new SfOptAutoVar());
			r.push(new SfOptVarDeclAssign());
		}
		return r;
	}
	
	private function buildFields() {
		SfCore.xt = "buildFields";
		for (sfClass in classList) if (sfClass.typedInit != null) {
			sfClass.init = SfExprTools.fromTypedExpr(sfClass.typedInit);
		}
		for (sfClass in classList) {
			for (sfField in sfClass.staticList) if (sfField.typedExpr != null) {
				sfField.expr = SfExprTools.fromTypedExpr(sfField.typedExpr);
			}
			var sfConstructor = sfClass.constructor;
			if (sfConstructor != null) if (sfConstructor.typedExpr != null) {
				sfConstructor.expr = SfExprTools.fromTypedExpr(sfConstructor.typedExpr);
			}
			for (sfField in sfClass.instList) if (sfField.typedExpr != null) {
				sfField.expr = SfExprTools.fromTypedExpr(sfField.typedExpr);
			}
		}
		if (apiMain != null) {
			mainExpr = SfExprTools.fromTypedExpr(apiMain);
			switch (mainExpr.def) {
				case SfCall(_.def => SfStaticField(_, f), []): {
					if (SfExprTools.isEmpty(f.expr)) {
						f.isHidden = true;
						mainExpr = null;
					}
				};
				default:
			}
		}
		//
		if (SfCore.sfConfig.dump == "pre") File.saveContent("sf.sfdump", SfDump.get());
		// small transformations:
		for (o in getPreproc()) {
			o.apply();
		}
		for (o in getOptimizers()) {
			o.apply();
		}
		SfCore.xt = null;
	}
	
	/** Should be overriden in the target library with actual printing routines. */
	public function printTo(path:String) {
		throw "Not implemented.";
	}
	
	public function printConst(r:SfBuffer, value:TConstant, expr:SfExpr) {
		var pos = SfExprTools.getPos(expr);
		switch (value) {
			case TInt(i): r.addInt(i);
			case TFloat(s): r.addString(s);
			case TString(s): {
				var q = s.indexOf('"') >= 0 && s.indexOf("'") < 0 ? "'".code : '"'.code;
				r.addChar(q);
				for (i in 0 ... s.length) {
					var c = StringTools.fastCodeAt(s, i), d;
					if (c < 32) switch (c) {
						case "\r".code: r.addChar2("\\".code, "r".code);
						case "\n".code: r.addChar2("\\".code, "n".code);
						case "\t".code: r.addChar2("\\".code, "t".code);
						default:
							r.addChar2("\\".code, "x".code);
							d = c >> 4; r.addChar(d < 10 ? 48 + d : 55 + d);
							d = c & 15; r.addChar(d < 10 ? 48 + d : 55 + d);
					} else {
						if (c == q || c == "\\".code) r.addChar("\\".code);
						r.addChar(c);
					}
				}
				r.addChar(q);
			};
			case TBool(b): if (b) r.addString("true"); else r.addString("false");
			case TNull: r.addString("null");
			case TThis: r.addString("this");
			default: Context.error("Can't print " + value.getName(), pos);
		}
	}
	
	/**
	 * Should print an expression to the given buffer.
	 * @param	r	Target buffer
	 * @param	expr	Expression to be printed.
	 * @param	wrap	Wrap mode (true: inline, null: normal, false: block)
	 */
	public function printExpr(r:SfBuffer, expr:SfExpr, ?wrap:Bool):Void {
		throw "Not implemented.";
	}
	
	public function getVarName(name:String) return name;
	
	public function printFormat(b:SfBuffer, fmt:String, val:Dynamic):Bool {
		return null;
	}
	
	public function new() {
		SfCore.sfGenerator = cast(this, SfGenerator);
		var conf = new SfConfig();
		SfCore.sfConfig = conf;
	}
	
	public function compile(apiTypes:Array<Type>, apiMain:Null<TypedExpr>, outputPath:String) {
		this.apiTypes = apiTypes;
		this.apiMain = apiMain;
		this.outputPath = outputPath;
		buildTypes();
		buildFields();
		if (SfCore.sfConfig.dump == "post") File.saveContent("sf.sfdump", SfDump.get());
		printTo(outputPath);
		var path2 = SfCore.sfConfig.also;
		if (path2 != null) printTo(path2);
	}
}

@:forward abstract SfOptArray(Array<SfOptImpl>) from Array<SfOptImpl> to Array<SfOptImpl> {
	public function contains(c:Class<SfOptImpl>):Bool {
		for (v in this) {
			if (StdType.getClass(v) == c) return true;
		}
		return false;
	}
	public function replace(c:Class<SfOptImpl>, v:SfOptImpl):Void {
		for (i in 0 ... this.length) {
			if (StdType.getClass(this[i]) == c) {
				this.splice(i, 1);
				this.insert(i, v);
				return;
			}
		}
		throw "Couldn't replace " + StdType.getClassName(c);
	}
	public function removeClass(c:Class<SfOptImpl>):Bool {
		for (i in 0 ... this.length) {
			if (StdType.getClass(this[i]) == c) {
				this.splice(i, 1);
				return true;
			}
		}
		return false;
	}
	public function moveToFront(c:Class<SfOptImpl>):Void {
		for (i in 0 ... this.length) {
			var v = this[i];
			if (StdType.getClass(v) == c) {
				this.splice(i, 1);
				this.unshift(v);
				return;
			}
		}
	}
	public function insertAfter(c:Class<SfOptImpl>, v:SfOptImpl):Void {
		for (i in 0 ... this.length) {
			if (StdType.getClass(this[i]) == c) {
				this.insert(i + 1, v);
				return;
			}
		}
		throw "Couldn't insertAfter " + StdType.getClassName(c);
	}
}
