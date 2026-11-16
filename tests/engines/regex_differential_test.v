module tests

import os
import x.json2
import valibro as v

fn test_ecmascript_regex_matches_reference_with_shared_state() {
 document := os.read_file(@VMODROOT+'/tests/fixtures/strings/regexp_ecmascript.json') or {panic(err)}
 cases := json2.decode[json2.Any](document) or {panic(err)}
 for fixture in cases.as_array() {
  fields := fixture.as_map()
  action := v.regex_with_flags(fields['pattern']!.str(),fields['flags']!.str())
  schema := v.pipe(v.string(),action)
  expected := fields['results']!.as_array()
  for index,input in fields['inputs']!.as_array() {
   matched := v.is_valid(schema,input.str()) or {panic(err)}
   assert matched==expected[index].as_map()['matched']!.bool(),fields['pattern']!.str()+' /'+fields['flags']!.str()+' '+input.str()
  }
 }
}
