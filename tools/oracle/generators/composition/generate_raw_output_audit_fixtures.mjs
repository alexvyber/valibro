import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {filterNativeDateRows} from '../../shared/native_scope.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/composition/generate_raw_output_audit_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from 'node:fs';import path from 'node:path';import {pathToFileURL} from 'node:url';
const v = await loadValibot();
function encode(value) {
 if(value===undefined)return {type:'undefined'};if(value===null)return {type:'null'};
 if(value instanceof Date)return {type:'date',value:isNaN(value.getTime())?'invalid-date':String(value.getTime())};
 if(typeof value==='bigint')return {type:'bigint',value:String(value)};
 if(typeof value==='number')return {type:'number',value:String(value)};
 if(typeof value==='string'||typeof value==='boolean')return {type:typeof value,value:String(value)};
 if(Array.isArray(value))return {type:'array',items:value.map(encode)};
 if(value instanceof Set)return {type:'set',items:[...value].map(encode)};
 if(value instanceof Map)return {type:'map',entries:[...value].map(([key,item])=>[encode(key),encode(item)])};
 return {type:'object',entries:Object.entries(value).map(([key,item])=>[encode(key),encode(item)])};
}
const rows=[];const stringBig=v.pipe(v.string(),v.toBigint());
for(const action of ['skipNumber','toNumber','toBigint','toDate','parseBoolean','parseJson'])for(const input of ['1',' 42 ','abc','bad','true','{"a":1}','2020-01-02'])for(const abortEarly of [false,true]) {
 const schema=action==='skipNumber'?v.pipe(v.string(),v.trim(),v.minLength(3),v.toNumber()):v.pipe(v.string(),v[action]());
 const result=v.safeParse(schema,input,{abortEarly});rows.push({family:'scalar',action,input,abort_early:abortEarly,success:result.success,typed:!!result.typed,raw:encode(result.output)});
}
for(const family of ['array','nested','record','map','set','struct'])for(const input of [['1','bad'],['01','bad','1','bad2'],['1','2']])for(const abortEarly of [false,true]) {
 const entries=input.map((item,i)=>[String.fromCharCode(97+i),item]);
 const schema=family==='array'?v.array(stringBig):family==='nested'?v.array(v.array(stringBig)):family==='record'?v.record(v.string(),stringBig):family==='map'?v.map(v.string(),stringBig):family==='set'?v.set(stringBig):v.object({a:stringBig,b:stringBig});
 const value=family==='array'?input:family==='nested'?[['1'],input]:family==='map'?new Map(entries):family==='set'?new Set(input):Object.fromEntries(entries);
 const result=v.safeParse(schema,value,{abortEarly});rows.push({family,input,abort_early:abortEarly,success:result.success,typed:!!result.typed,raw:encode(result.output)});
}
rows.splice(0,rows.length,...filterNativeDateRows('raw_output_audit',rows));
writeReferenceFixture('raw_output_audit', rows);console.log(rows.length+' raw output audit outcomes');
