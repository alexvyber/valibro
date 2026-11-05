import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/json/generate_json_presence_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from 'node:fs';import path from 'node:path';import {pathToFileURL} from 'node:url';
const v = await loadValibot();const rows=[];
for(const kind of ['undefined','hook_undefined','hook_null','hook_value','hook_error','null'])for(const placement of ['root','array','map'])for(const mode of ['keep','recover','null','omit','object','error']) {
 const calls=[];
 const item=kind==='undefined'?undefined:kind==='function'?function(){}:kind==='null'?null:{toJSON(key){calls.push('H:'+key);if(kind==='hook_error')throw Error('Hook failed');return kind==='hook_undefined'?undefined:kind==='hook_null'?null:42;}};
 const input=placement==='root'?item:placement==='array'?[item,item]:{a:item,b:item};
 const replacer=(key,value)=>{
  const state=value===undefined?'undefined':value===null?'null':'value';
  calls.push('R:'+key+':'+state);
  if(value===undefined||value===null) {
   if(mode==='recover')return 'recovered';if(mode==='null')return null;if(mode==='omit')return undefined;if(mode==='object')return {recovered:true};if(mode==='error')throw Error('Replacer failed');
  }
  return value;
 };
 const result=v.safeParse(v.pipe(v.unknown(),v.stringifyJson({replacer})),input);
 rows.push({kind,placement,mode,calls,success:result.success,output:result.success?result.output:'',issues:(result.issues??[]).map(i=>({code:i.type,message:i.message,received:i.received}))});
}
writeReferenceFixture('json_presence', rows);console.log(`${rows.length} presence-aware JSON outcomes`);
