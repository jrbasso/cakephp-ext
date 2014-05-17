namespace Cake\Utility;

class String2 {

	public static function tokenize(string data, separator = ",", leftBound = "(", rightBound = ")") {
		if empty data {
			return [];
		}

		int depth = 0,
			offset = 0,
			length = 0,
			tmpOffset = -1,
			i;
		bool open = false;
		string buffer = "";
		var results = [], offsets;

		let length = data->length();
		while offset <= length {
			let tmpOffset = -1;
			let offsets = [
				strpos(data, separator, offset),
				strpos(data, leftBound, offset),
				strpos(data, rightBound, offset)
			];
			for i in range(0, 2) {
				if offsets[i] !== false && (offsets[i] < tmpOffset || tmpOffset == -1) {
					let tmpOffset = (int)offsets[i];
				}
			}
			if tmpOffset !== -1 {
				string c;
				let c = data[tmpOffset]; // Zephir consider data[tmpOffset] and integer and fail on the compares

				let buffer .= substr(data, offset, tmpOffset - offset);
				if !depth && c == separator {
					let results[] = buffer;
					let buffer = "";
				} else {
					let buffer .= c;
				}
				if leftBound != rightBound {
					if c == leftBound {
						let depth++;
					}
					if c == rightBound {
						let depth--;
					}
				} else {
					if c == leftBound {
						if open === false {
							let depth++;
							let open = true;
						} else {
							let depth--;
						}
					}
				}
				let tmpOffset++;
				let offset = tmpOffset;
			} else {
				let results[] = buffer . substr(data, offset);
				let offset = length + 1;
			}
		}
		if empty results && !empty buffer {
			let results[] = buffer;
		}
		if !empty results {
			return array_map("trim", results);
		}
		return [];
	}
}
