import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/json/generate_maybe_json_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from 'node:fs';import path from 'node:path';import {pathToFileURL} from 'node:url';
const v = await loadValibot();const rows=[];
for(const payload of ['string','number','hook','date','bigint'])for(const state of ['missing','undefined','null','value'])for(const placement of ['root','array','map','field','nested'])for(const mode of ['plain','recover','whitelist','omit_root']) {
 // JSON-valued replacers cannot carry bigint. Verify its rejection and container-level omission.
 if(payload==='bigint'&&state==='value'&&(mode==='recover'||(['root','nested'].includes(placement)&&mode==='omit_root')))continue;
 const calls=[];const item=payload==='string'?'hello':payload==='number'?42:payload==='date'?new Date(0):payload==='bigint'?42n:{toJSON(key){calls.push('H:'+key);return {key,value:42};}};
 const value=state==='value'?item:state==='null'?null:undefined;
 const input=placement==='root'||placement==='nested'?value:placement==='array'?[value,value]:state==='missing'?{}:{a:value,b:value};
 const replacer=mode==='whitelist'?['b','key','value']:mode==='plain'?undefined:(key,value)=>{
  calls.push('R:'+key+':'+(value===undefined?'undefined':value===null?'null':'value'));
  if(key===''&&mode==='omit_root')return undefined;
  if(value===undefined&&mode==='recover')return 'recovered';
  return value;
 };
 const result=v.safeParse(v.pipe(v.unknown(),v.stringifyJson({replacer})),input);
 rows.push({payload,state,placement,mode,calls,success:result.success,output:result.success?result.output:'',issues:(result.issues??[]).map(i=>({code:i.type,message:i.message,received:i.received}))});
}
for(const input of ['"hello"','42','null','{"a":1,"b":2}','[1,null,2]','true'])for(const reviverMode of ['keep','remove_root','remove_a','increment'])for(const mode of ['plain','recover']) {
 const calls=[];
 const reviver=(key,value)=>{calls.push('V:'+key);if(reviverMode==='remove_root'&&key==='')return undefined;if(reviverMode==='remove_a'&&key==='a')return undefined;return reviverMode==='increment'&&typeof value==='number'?value+1:value;};
 const replacer=mode==='plain'?undefined:(key,value)=>{calls.push('R:'+key+':'+(value===undefined?'undefined':value===null?'null':'value'));return value===undefined?'recovered':value;};
 const result=v.safeParse(v.pipe(v.string(),v.parseJson({reviver}),v.stringifyJson({replacer})),input);
 rows.push({family:'pipeline',input,reviver_mode:reviverMode,mode,calls,success:result.success,output:result.success?result.output:'',issues:(result.issues??[]).map(i=>({code:i.type,message:i.message,received:i.received}))});
}
writeReferenceFixture('maybe_json', rows);console.log(`${rows.length} native Maybe JSON outcomes`);
