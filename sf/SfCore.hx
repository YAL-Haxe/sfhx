package sf;
import haxe.macro.JSGenApi;
import haxe.macro.Type;
import sf.SfGenerator;
import sf.type.SfBuffer;
import haxe.macro.Context;
import haxe.extern.Rest;

/**
 * ...
 * @author YellowAfterlife
 */
class SfCore {
	
	/** The current SfGenerator */
	public static var sfGenerator:SfGenerator = null;
	
	public static var jsGenAPI:JSGenApi;
	
	/** Config holder */
	public static var sfConfig:SfConfig = null;
	
	/**
	Formatted output. Supported tags:
	`         Optional space
	%`        An actual backtick
	;         Semicolon (omitted if immediately after a closing curly bracket)
	%s        A String
	%d        An Int
	%c        An Int as a charcode
	%x        An inline expression (flags=Expr)
	%w        A wrapped inline expression (flags=ExprWrap)
	%(const)  A TConst
	%(stat)   A wrapped statement (flags=StatWrap)
	%(block)  A statement in a block, if needed (flags=Stat)
	%(expr)   Same as %x
	%(args)   An array of arguments ([a, b, c] -> `a, b, c`) via addArguments
	%(targs)  An array of trailing arguments ([a, b, c] -> `, a, b, c`) via addTrailArgs
	%(+\n)    Adds a line break with increased indentation (e.g. "if (x) {%(+\n)...")
	%(-\n)    Adds a line break with decreased indentation (e.g. "...%(-\n)}")
	Generators may implement additional tags by overriding SfGenerator.printFormat
	**/
	public static var printf:SfCore_printf = Reflect.makeVarArgs(sf.type.SfPrintf.printf);
	
	/** Like printf, but returns a string */
	public static var sprintf:SfCore_sprintf = Reflect.makeVarArgs(sf.type.SfPrintf.sprintf);
	
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
		SfTimes.init();
		SfGenerator.main();
		if (Context.defined("js")) {
			var sfg = new SfGenerator();
			haxe.macro.Compiler.setCustomJSGenerator(function(api:JSGenApi) {
				jsGenAPI = api;
				try {
					sfg.compile(api.types, api.main, api.outputFile);
				} catch (e:Dynamic) {
					var stack = haxe.CallStack.exceptionStack();
					Sys.println("Stack: " + haxe.CallStack.toString(stack));
					Sys.println("Tag: " + Std.string(xt));
					Sys.println("Tag2: " + Std.string(xt2));
					Sys.println("Error: " + Std.string(e));
					#if !eval_stack
					if (stack.length == 0) Sys.println("(no eval-stack)");
					#end
					var pos = haxe.macro.PositionTools.make({min:0, max:0, file:api.outputFile});
					Context.error("Generator error (see full output): " + e, pos);
				}
				SfTimes.finish();
			});
		} else {
			var outPath = haxe.macro.Compiler.getOutput();
			if (!Context.defined("no-output")) outPath += ".cs";
			var sfg = new SfGenerator();
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
						if (sf.type.expr.SfExprTools.typeHasMeta(t, ":used")) {
							r = t;
						} else r = null;
					}
					if (r != null) types.push(r);
				}
				//
				sfg.compile(types, null, outPath);
			});
		}
		#end
	}
	
}

typedef SfCore_printf = (buf:SfBuffer, fmt:String, args:Rest<Dynamic>)->SfBuffer;
typedef SfCore_sprintf = (fmt:String, args:Rest<Dynamic>)->String;
