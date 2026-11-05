import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/composition/generate_default_context_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const v = await loadValibot();
const rows=[];
for(const name of ['optional','exactOptional','nullable','nullish','undefinedable'])for(const input of [undefined,null,' xxx '])for(const lang of ['','ru'])for(const abortEarly of [false,true])for(const invalid of [false,true]) {
 const calls=[];
 const callback=(dataset,config)=>{calls.push({present:!!dataset,state:dataset?.value===null?'null':dataset?.value===undefined?'undefined':'value',value:dataset?.value??'',lang:config?.lang??'',abort_early:config?.abortEarly??false});return invalid?' x ':' xxx ';};
 const schema=v[name](v.pipe(v.string(),v.trim(),v.minLength(3)),callback);
 const config={lang,abortEarly};
 const introspection=v.getDefault(schema,undefined,config);v.getDefault(schema,{value:'manual',typed:true},config);const result=schema['~run']({value:input},config);
 rows.push({name,input_state:input===undefined?'undefined':input===null?'null':'value',input:input??'',lang,abort_early:abortEarly,invalid,introspection,typed:!!result.typed,output_state:result.value===undefined?'undefined':result.value===null?'null':'value',output:result.value??'',calls,issues:(result.issues??[]).map(i=>({code:i.type,expected:i.expected??'',received:i.received,message:i.message}))});
}
writeReferenceFixture('default_context', rows);
console.log(rows.length+' computed default context outcomes');
