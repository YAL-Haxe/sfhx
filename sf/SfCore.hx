package sf;
import haxe.macro.Type;
import sf.SfGenerator;
import sf.type.SfBuffer;
import haxe.macro.Context;

/**
 * ...
 * @author YellowAfterlife
 */
class SfCore {
	
	/** The current SfGenerator */
	public static var sfGenerator:SfGenerator = null;
	
	/** Config holder */
	public static var sfConfig:SfConfig = null;
	
	public static var printf:SfBuffer->String->haxe.extern.Rest<Dynamic>->SfBuffer = Reflect.makeVarArgs(sf.type.SfPrintf.printf);
	
	public static var sprintf:String->haxe.extern.Rest<Dynamic>->String = Reflect.makeVarArgs(sf.type.SfPrintf.sprintf);
	
	/** exception tag */
	public static var xt:Dynamic = null;
	public static var xt2:Dynamic = null;
	
	private static var typesFound:Array<Type>;
	private static function indexType() {
		var t = Context.getLocalType();
		if (t != null) typesFound.push(t);
		return null;
	}
	
	/** Macros entrypoint */
	private static function main() {
		#if !sf_no_gen
		if (Context.defined("js")) {
			haxe.macro.Compiler.setCustomJSGenerator(function(api:haxe.macro.JSGenApi) {
				try {
					var sfg = new SfGenerator(api.outputFile);
					sfg.compile(api.types, api.main);
				} catch (e:Dynamic) {
					Sys.println("Stack: " + haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
					Sys.println("Tag: " + Std.string(xt));
					Sys.println("Tag2: " + Std.string(xt2));
					Sys.println("Error: " + Std.string(e));
					#if !eval_stack
					Sys.println("(no eval-stack)");
					#end
				}
			});
		} else {
			var outPath = haxe.macro.Compiler.getOutput();
			if (!Context.defined("no-output")) outPath += ".cs";
			var sfg = new SfGenerator(outPath);
			typesFound = [];
			Context.onGenerate(function(types) {
				typesFound = types;
			});
			Context.onAfterGenerate(function() {
				var types = [];
				for (t in typesFound) {
					var r;
					try {
						var s = haxe.macro.TypeTools.toString(t);
						var i = s.indexOf("<");
						if (i >= 0) s = s.substring(0, i);
						r = Context.getType(s);
					} catch (_:Dynamic) {
						if (sf.type.SfExprTools.typeHasMeta(t, ":used")) {
							r = t;
						} else r = null;
					}
					if (r != null) types.push(r);
				}
				//
				sfg.compile(types, null);
			});
		}
		#end
	}
	
}
