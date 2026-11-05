module valibro_test

import x.json2
import valibro as v
import valibro.types

pub struct MeasurementCase {
pub:
	input       string
	length      int
	bytes       int
	code_points int
}

fn test_measurements_match_supported_counts() {
	cases := json2.decode[[]MeasurementCase]($embed_file('../fixtures/strings/string_measurements.json').to_string()) or {
		panic(err)
	}
	for row in cases {
		for metric in ['length', 'bytes', 'code_points'] {
			count := match metric {
				'length' { row.input.runes().len }
				'bytes' { row.bytes }
				else { row.code_points }
			}

			for n in [0, count, count + 1] {
				mut actions := []types.Action[string]{}
				match metric {
					'length' {
						actions = [v.length(n), v.min_length(n),
							v.max_length(n), v.not_length(n)]
					}
					'bytes' {
						actions = [v.bytes(n), v.min_bytes(n),
							v.max_bytes(n), v.not_bytes(n)]
					}
					else {
						actions = [v.code_points(n), v.min_code_points(n),
							v.max_code_points(n), v.not_code_points(n)]
					}
				}

				for index, action in actions {
					expected := [count == n, count >= n, count <= n, count != n][index]
					result := v.safe_parse(v.pipe(v.string(), action), row.input)
					assert result.success == expected, '${action.type_name}: ${row.input}, count ${count}, requirement ${n}'
				}
			}
		}
	}
}
