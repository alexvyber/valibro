import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/json/generate_json_interaction_fixtures.mjs PINNED_VALIBOT_CHECKOUT
// Unchanged keys/indices follow native JSON value semantics. Nil pointer fields use V omission.
import fs from 'node:fs';import path from 'node:path';import {pathToFileURL} from 'node:url';
const v = await loadValibot();const rows=[];
for(const family of ['object','array','deep_object','deep_array'])for(const placement of ['root','nested'])for(const kind of ['value','omit','error'])for(const mode of ['keep','add','remove_b','replace_a','replace_all','reverse_keys','error_after_a']) {
 if(family.endsWith('array')&&mode==='reverse_keys')continue;
 const calls=[];const hook=id=>({toJSON(key){calls.push('H:'+id+':'+key);if(kind==='error')throw Error('Interaction hook failed');return kind==='omit'?undefined:{id,key};}});
 const source=family.endsWith('object')?{a:hook('A'),b:hook('B'),tag:0}:[hook('A'),hook('B')];
 const parent=family.startsWith('deep_')?{branch:source,untouched:true}:source;
 const input=placement==='root'?parent:{inside:parent};
 const replacer=(key,value)=>{
  calls.push('R:'+key);
  if(key===(placement==='root'?'':'inside')) {
   const edit=value=>{
    if(mode==='replace_all')return {done:true};
    if(mode==='add')return Array.isArray(value)?[...value,99]:{...value,tag:1};
    if(mode==='remove_b') {if(Array.isArray(value))return value.slice(0,1);const copy={...value};delete copy.b;return copy;}
    if(mode==='replace_a')return Array.isArray(value)?['changed',value[1]]:{...value,a:'changed'};
    if(mode==='reverse_keys')return {tag:value.tag,b:value.b,a:value.a};
    return value;
   };
   return family.startsWith('deep_')?{...value,branch:edit(value.branch)}:edit(value);
  }
  if((key==='a'||key==='0')&&mode==='error_after_a')throw Error('Interaction replacer failed');
  return value;
 };
 const result=v.safeParse(v.pipe(v.unknown(),v.stringifyJson({replacer})),input);
 rows.push({family,placement,kind,mode,calls,success:result.success,output:result.success?result.output:'',issues:(result.issues??[]).map(i=>({code:i.type,message:i.message,received:i.received}))});
}
for(const kind of ['hook','encoder','json'])for(const placement of ['root','array','map','field'])for(const nil of [false,true])for(const mode of ['keep','recover_null','omit_null']) {
 const calls=[];const item=nil?null:kind==='json'?{encoded:true}:{toJSON(key){calls.push(kind==='hook'?'H:P:'+key:'E');return kind==='hook'?{id:'P',key}:{encoded:true};}};
 const input=placement==='root'?item:placement==='array'?[item]:placement==='map'?{item}:nil?{}:{item};
 const replacer=(key,value)=>{calls.push('R:'+key);if(value===null&&mode==='recover_null')return 'recovered';if(value===null&&mode==='omit_null')return undefined;return value;};
 const result=v.safeParse(v.pipe(v.unknown(),v.stringifyJson({replacer})),input);
 rows.push({family:'pointer',placement,kind,nil,mode,calls,success:result.success,output:result.success?result.output:'',issues:(result.issues??[]).map(i=>({code:i.type,message:i.message,received:i.received}))});
}
writeReferenceFixture('json_interaction', rows);console.log(`${rows.length} JSON interaction outcomes`);
