module tests

import valibro.jsoncodec

fn test_binary64_decoder_preserves_large_strings_while_masking_numbers() {
 text := 'a'.repeat(1024 * 1024)
 document := '{"data":"'+text+'","number":1e400,"escaped":"\\\"123"}'
 decoded := jsoncodec.decode(document,binary64_numbers:true) or {panic(err)}
 fields := decoded.as_map()
 assert fields['data']!.str()==text
 assert fields['number']!.f64()>1e308
 assert fields['escaped']!.str()=='"123'
}
