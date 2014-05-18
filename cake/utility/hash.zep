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

}
