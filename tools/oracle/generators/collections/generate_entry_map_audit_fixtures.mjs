import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/collections/generate_entry_map_audit_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from 'node:fs';import path from 'node:path';import {pathToFileURL} from 'node:url';
const v = await loadValibot();
const rows=[];
for(const family of ['map','set'])for(const entries of [[['A',1],['a',2],['B',3]],[['bad',1],['A',-1]],[['A',1],['B',-1],['b',2]],[['A',1],['A',2]],[['a',1],['b',2]],[['A',1],['a',2],['bad',3]]])for(const abortEarly of [false,true]) {
 const pool=new Map(),outputs=new Map();const key=id=>{if(!pool.has(id))pool.set(id,{code:id,original:id});return pool.get(id);};
 const item=v.pipe(v.custom(value=>value.code!=='bad'),v.transform(value=>{const code=value.code.toLowerCase();if(!outputs.has(code))outputs.set(code,{code,original:value.original});return outputs.get(code);}));
 const schema=family==='map'?v.map(item,v.pipe(v.number(),v.minValue(0))):v.set(item);
 const input=family==='map'?new Map(entries.map(([id,value])=>[key(id),value])):new Set(entries.map(([id])=>key(id)));
 const result=schema['~run']({value:input},{abortEarly});const flat=result.issues?v.flatten(result.issues):{};
 rows.push({family,entries,abort_early:abortEarly,typed:!!result.typed,output:family==='map'?[...result.value].map(([key,value])=>({key,value})):[...result.value],issues:(result.issues??[]).map(i=>({code:i.type,message:i.message,key:i.path[0].key?.code??'',type:i.path[0].type})),flat:{root:flat.root??[],nested:flat.nested??{},other:flat.other??[]}});
}
writeReferenceFixture('entry_map_audit', rows);console.log(rows.length+' arbitrary-key map / comparator set observations');
