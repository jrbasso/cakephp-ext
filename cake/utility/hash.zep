namespace Cake\Utility;

class Hash {

	public static function get(data, path, defaultValue = null) {
		var parts, key, loopData;
		bool isString;

		if empty data {
			return defaultValue;
		}

		let isString = (bool)is_string(path);
		if isString && strpos(path, ".") === false {
			return isset data[path] ? data[path] : defaultValue;
		}

		if isString || is_numeric(path) {
			let parts = explode(".", path);
		} else {
			let parts = path;
		}

		let loopData = data;
		for key in parts {
			if !fetch loopData, loopData[key] {
				return defaultValue;
			}
		}
		return loopData;
	}

	public static function extract(array data, string path) -> array {
		var tokens, token, conditions, tmp, item, k, v, next, filter, context = [];
		string key = "__set_item__";

		if empty path {
			return data;
		}

/**
	Commenting this part out because the return is causing PHP to crash.
	This piece of code is just for optimization, so the functionality will
	work anyway.
	It seems to be some bug on zephir.

		if !memstr(path, "{") && !memstr(path, "[") {
			let tmp = self::get(data, path);
			return is_array(tmp) ? tmp : [tmp];
		}
*/

		if strpos(path, "[") === false {
			let tokens = explode(".", path);
		} else {
			let tokens = String2::tokenize(path, ".", "[", "]");
		}

		let context[key] = [data];
		for token in tokens {
			let next = [];

			let tmp = self::_splitConditions(token);
			let token = tmp[0];
			let conditions = tmp[1];

			for item in context[key] {
				if !is_array(item) {
					let item = is_null(item) ? [] : [item];
				}
				for k, v in item {
					if self::_matchToken(k, token) {
						let next[] = v;
					}
				}
			}

			// Filter for attributes.
			if conditions {
				let filter = [];
				for item in next {
					if is_array(item) && self::_matches(item, conditions) {
						let filter[] = item;
					}
				}
				let next = filter;
			}
			let context[key] = next;
		}
		return context[key]; 
	}

	protected static function _splitConditions(token) -> array {
		var conditions, position;

		let conditions = false;
		let position = strpos(token, "[");
		if position !== false {
			let conditions = substr(token, position);
			let token = substr(token, 0, position);
		}

		return [token, conditions];
	}

	protected static function _matchToken(key, token) -> bool {
		if token === "{n}" {
			return is_numeric(key);
		}
		if token === "{s}" {
			return is_string(key);
		}
		if is_numeric(token) {
			return key == token;
		}
		return key === token;
	}

	protected static function _matches(data, selector) -> bool {
		var conditions = null, cond, attr, op, val, prop;

		preg_match_all(
			"/(\\[ (?P<attr>[^=><!]+?) (\\s* (?P<op>[><!]?[=]|[><]) \\s* (?P<val>(?:\\/.*?\\/ | [^\\]]+)) )? \\])/x",
			selector,
			conditions,
			PREG_SET_ORDER
		);

		for cond in conditions {
			let attr = cond["attr"];
			let op = isset cond["op"] ? cond["op"] : null;
			let val = isset cond["val"] ? cond["val"] : null;

			// Presence test.
			if empty op && empty val && !isset data[attr] {
				return false;
			}

			// Empty attribute = fail.
			if !isset data[attr] {
				return false;
			}

			let prop = data[attr];
			if prop === true || prop === false {
				return prop ? "true" : "false";
			}

			// Pattern matches and other operators.
			if op === "=" && val && val[0] === "/" {
				if preg_match(val, prop) {
					return false;
				}
			} else {
				if (
					(op === "=" && prop != val) ||
					(op === "!=" && prop == val) ||
					(op === ">" && prop <= val) ||
					(op === "<" && prop >= val) ||
					(op === ">=" && prop < val) ||
					(op === "<=" && prop > val)
				) {
					return false;
				}
			}
		}
		return true;
	}

	public static function insert(array data, string path, values = null) -> array {
		bool noTokens;
		var tokens, token, nextPath, tmp, conditions, k, v;

		let noTokens = !memstr(path, "[");
		if noTokens && !memstr(path, ".") {
			let data[path] = values;
			return data;
		}

		if noTokens {
			let tokens = explode(".", path);
		} else {
			let tokens = String2::tokenize(path, ".", "[", "]");
		}

		if noTokens && !memstr(path, "{") {
			return self::_simpleOp("insert", data, tokens, values);
		}

		let token = array_shift(tokens);
		let nextPath = implode(".", tokens);

		let tmp = self::_splitConditions(token);
		let token = tmp[0];
		let conditions = tmp[1];

		for k, v in data {
			if self::_matchToken(k, token) {
				if conditions && self::_matches(v, conditions) {
					let data[k] = array_merge(v, values);
					continue;
				}
				if !conditions {
					let data[k] = self::insert(v, nextPath, values);
				}
			}
		}
		return data;
	}

	/**
	 * This method is different from CakePHP because Zephir doesn't
	 * support variables by reference
	 */
	protected static function _simpleOp(string op, data, path, values = null) -> array {
		int count;
		var key;

		let count = count(path);
		if count === 0 {
			return data;
		}
		let key = array_shift(path);

		if op === "insert" {
			if count === 1 {
				let data[key] = values;
			} else {
				if !isset data[key] {
					let data[key] = [];
				}
				let data[key] = self::_simpleOp(op, data[key], path, values);
			}
			return data;
		} else {
			if op === "remove" {
				if count === 1 {
					unset data[key];
					return data;
				}
				if !isset data[key] {
					return data;
				}
				let data[key] = self::_simpleOp(op, data[key], path, values);
			}
		}
		return [];
	}

	public static function remove(data, string path) -> array {
		bool noTokens, noExpansion;
		var tokens, token, nextPath, tmp, conditions, k, v, match;

		let noTokens = !memstr(path, "[");
		let noExpansion = !memstr(path, "{");

		if noExpansion && noTokens && !memstr(path, ".") {
			unset data[path];
			return data;
		}

		let tokens = noTokens ? explode(".", path) : String2::tokenize(path, ".", "[", "]");

/**
 * Similar of extract method, this code is causing the PHP to crash,
 * but it is also only for performance and can be skipped for now.
 *
		if noExpansion && noTokens {
			return self::_simpleOp("remove", data, tokens, null);
		}
*/

		let token = array_shift(tokens);
		let nextPath = implode(".", tokens);

		let tmp = self::_splitConditions(token);
		let token = tmp[0];
		let conditions = tmp[1];

		for k, v in data {
			let match = self::_matchToken(k, token);
			if match && typeof v === "array" {
				if conditions && self::_matches(v, conditions) {
					unset data[k];
					continue;
				}
				let data[k] = self::remove(v, nextPath);
				if empty data[k] {
					unset data[k];
				}
			} else {
				if match {
					unset data[k];
				}
			}
		}
		return data;
	}

	public static function combine(data, keyPath, valuePath = null, groupPath = null) -> array {
		var format, keys, vals = null, group, out = [], i;

		if empty data {
			return [];
		}

		if typeof keyPath === "array" {
			let format = array_shift(keyPath);
			let keys = self::format(data, keyPath, format);
		} else {
			let keys = self::extract(data, keyPath);
		}
		if empty keys {
			return [];
		}

		if !empty valuePath && typeof valuePath === "array" {
			let format = array_shift(valuePath);
			let vals = self::format(data, valuePath, format);
		} else {
			if !empty valuePath {
				let vals = self::extract(data, valuePath);
			}
		}
		if empty vals {
			let vals = array_fill(0, count(keys), null);
		}

		if count(keys) !== count(vals) {
			throw new \RuntimeException(
				"Hash::combine() needs an equal number of keys + values."
			);
		}

		if groupPath !== null {
			let group = self::extract(data, groupPath);
			if !empty group {
				for i in range(0, count(keys) - 1) {
					if !isset group[i] {
						let group[i] = 0;
					}
					let out[group[i]][keys[i]] = vals[i];
				}
				return out;
			}
		}
		if empty vals {
			return [];
		}
		return array_combine(keys, vals);
	}

	public static function format(data, paths, format) -> array {
		var extracted = [], count, i, j, out = [], countTwo, args = [];

		let count = count(paths);
		if !count {
			return [];
		}

		for i in range(0, count - 1) {
			let extracted[] = self::extract(data, paths[i]);
		}
		let data = extracted;
		let count = count(data[0]);

		let countTwo = count(data);
		for j in range (0, count - 1) {
			let args = [];
			for i in range (0, countTwo - 1) {
				if isset data[i][j] {
					let args[] = data[i][j];
				}
			}
			let out[] = vsprintf(format, args);
		}
		return out;
	}

	public static function contains(data, needle) -> bool {
		var stack = [], key, val, next, tmp;

		if empty data || empty needle {
			return false;
		}

		while !empty needle {
			let key = key(needle);
			let val = needle[key];
			unset needle[key];

			if isset data[key] && typeof val === "array" {
				let next = data[key];
				unset data[key];

				if !empty val {
					let stack[] = [val, next];
				}
			} else {
				if !isset data[key] || data[key] != val {
					return false;
				}
			}

			if empty needle && !empty stack {
				let tmp = array_pop(stack);
				let needle = tmp[0];
				let data = tmp[1];
			}
		}
		return true;
	}

	public static function check(data, path) -> bool {
		var results;

		let results = self::extract(data, path);
		if typeof results !== "array" {
			return false;
		}
		return !empty results;
	}

	public static function filter(data, callback = null) -> array {
		var k, v;

		if callback === null {
			let callback = ["Cake\\Utility\\Hash", "_filter"];
		}

		for k, v in data {
			if typeof v === "array" {
				let data[k] = self::filter(v, callback);
			}
		}
		return array_filter(data, callback);
	}

/**
 * A little different from CakePHP implementation because the
 * different type treatment on comparisons
 *
 * Also, this method is supposed to be protected, but zephir seems
 * to not treat local callbacks very well. Maybe it is a limitation on
 * PHP extensions, but either way setting it to public for while
 */
	public static function _filter(value) {
		if typeof value === "boolean" && value == false {
			return false;
		}
		return
			(typeof value === "integer" && value === 0) ||
			(typeof value === "string" && value === "0") ||
			!empty(value);
	}

}
