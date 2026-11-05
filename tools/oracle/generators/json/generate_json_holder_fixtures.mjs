import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/json/generate_json_holder_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const v = await loadValibot();
const rows=[];
for(const text of ['1','"x"','null','[1,2,{"a":3}]','{"factor":2,"value":3,"drop":4}','{"value":3,"factor":2}','{"nested":{"factor":2,"value":3},"tail":4}','{"0":1,"2":2,"1":3,"drop":[1,2]}'])for(const mode of ['trace','siblings','drop'])for(const action of ['parse','stringify']) {
 const calls=[];
 function callback(key,value,context) {
  calls.push({key,value:structuredClone(value),holder:structuredClone(this),source:context?.source??null});
  if(mode==='drop'&&key==='drop')return undefined;
  if(mode==='siblings'&&typeof value==='number')return key==='value'?value*(this.factor??1):value+1;
  return value;
 }
 const result=action==='parse'?v.safeParse(v.pipe(v.string(),v.parseJson({reviver:callback})),text):v.safeParse(v.pipe(v.unknown(),v.stringifyJson({replacer:callback})),JSON.parse(text));
 rows.push({text,mode,action,output:result.output,calls});
}
writeReferenceFixture('json_holder', rows);
console.log(rows.length+' JSON holder outcomes');
