package sf.type;

import haxe.macro.Expr.Position;
import haxe.macro.Type.MetaAccess;

/**
 * ...
 * @author YellowAfterlife
 */
class SfStructImpl {
	
	/** Name of structure */
	public var name:String;
	
	/** Original (non-:native) name */
	public var realName:String;
	
	/** Package (com.company.name) */
	public var pack:Array<String>;
	
	/** Documentation (if any) */
	public var doc:String;
	
	/** Output path in target-specific format (if needed) */
	public var path:String;
	
	/** Path override */
	public var exposePath:String;
	
	/** Whether the structure should be omitted from the final output */
	public var isHidden:Bool = false;
	
	public var meta:MetaAccess;
	
	/**
	   Simple metadata string extractor.
	   If :name isn't present, returns null.
	   If :name has no parameters or parameters are wrong type, returns "".
	   Otherwise returns the first string param.
	**/
	public function metaString(name:String):String {
		if (metaString_1.exists(name)) return metaString_1[name];
		var val:String = null;
		if (meta.has(name)) {
			for (entry in meta.extract(name)) {
				for (param in entry.params) switch (param.expr) {
					case EConst(c): {
						switch (c) {
							case CIdent(s), CString(s): {
								val = s;
								break;
							};
							default:
						}
					}
					default:
				}
				if (val != null) break;
			}
			if (val == null) val = "";
		}
		metaString_1.set(name, val);
		return val;
	}
	private var metaString_1 = new Map<String, String>();
	
	public function metaHandle(meta:MetaAccess, ndoc:String) {
		//
		if (meta.has(":realPath")) {
			realName = metaGetText(meta, ":realPath");
		} else realName = name;
		//
		if (meta.has(":remove") || meta.has(":extern")
			//|| !(haxe.macro.Context.defined("js") || meta.has(":used") || meta.has(":keep"))
		) {
			isHidden = true;
		}
		//
		var exp = metaString(":expose");
		if (exp != null && exp != "") exposePath = exp;
		var doc = metaGetText(meta, ":doc", 1);
		if (doc == null && exp != null) doc = "";
		if (doc == "" && ndoc != null) doc = ndoc;
		if (doc != null) doc = StringTools.trim(doc);
		this.doc = doc;
		//
	}
	
	/**
	 * Retrieves the given metadata entry as a string.
	 * Flags:
	 * 1	Concat string parameters
	 * 2	Assume empty string if no parameter specified
	 */
	public function metaGetText(meta:MetaAccess, name:String, flags:Int = 0):String {
		inline function error(s:String, pos:Position) {
			#if macro
			haxe.macro.Context.error(s, pos);
			#else
			throw s + " @ " + pos;
			#end
		}
		if (meta.has(name)) {
			var arr = meta.extract(name);
			if (arr.length > 1) {
				error("Structure can only have one metadata of this type.", arr[1].pos);
				return null;
			}
			var params = arr[0].params;
			if (flags & 1 != 0) {
				var r:String = "";
				for (p in params) switch (p.expr) {
					case EConst(CString(s)): r += s;
					default: error("Expected a String", p.pos);
				}
				return r;
			} else switch (params) {
				case [{ expr: EConst(CString(s)) }]: return s;
				default: {
					if (params.length == 0 && (flags & 2) != 0) {
						return "";
					} else error("This metadata should have a single String parameter.", arr[0].pos);
				};
			}
		}
		return null;
	}
	
	public function dumpTo(out:SfBuffer):Void {
		out.addString(name);
	}
	
	public function toString() {
		return pack != null && pack.length > 0 ? pack.join(".") + name : name;
	}
}
