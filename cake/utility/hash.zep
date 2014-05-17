namespace Cake\Utility;

class Hash {

	public static function get(data, path, defaultValue = null) {
		var parts, key, loopData;

		if empty data {
			return defaultValue;
		}
		if is_string(path) || is_numeric(path) {
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
