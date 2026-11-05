import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/json/generate_json_number_audit_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from 'node:fs';import path from 'node:path';import {pathToFileURL} from 'node:url';
const v = await loadValibot();
const numbers=['-0','0','0.1','9007199254740993','18446744073709551615','-9223372036854775809','1'.repeat(90),'1e309','-1e309','1e-400','1.7976931348623157e308','4.9406564584124654e-324'];
const rows=[];
for(const number of numbers)for(const text of [number,`[${number},1]`,`{"n":${number},"x":[${number}]}`]) {
 const calls=[];const action=v.pipe(v.string(),v.parseJson({reviver:(key,value,context)=>{if(context.source!==undefined)calls.push({key,source:context.source,number:typeof value==='number'?String(value):''});return value;}}),v.stringifyJson());
 const result=v.safeParse(action,text);
 rows.push({text,success:result.success,output:result.output,calls});
}
for(const text of ['01','-','1.','1e','+1','NaN','Infinity','[1,]','{"a":01}','{"a":-01}','[.5]','[1 2]','{"a":1"b":2}'])rows.push({text,success:v.safeParse(v.pipe(v.string(),v.parseJson()),text).success,output:'',calls:[]});
writeReferenceFixture('json_number_audit', rows);console.log(rows.length+' binary64 JSON observations');
