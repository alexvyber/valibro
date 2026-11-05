import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/json/generate_struct_json_fixtures.mjs PINNED_VALIBOT_CHECKOUT
// JS objects below represent V field tags/embedding, not JS prototype behavior.
import fs from 'node:fs';import path from 'node:path';import {pathToFileURL} from 'node:url';
const v = await loadValibot();const rows=[];
for(const kind of ['value','omit','null','error'])for(const placement of ['root','array','map'])for(const mode of ['plain','whitelist','trace','omit_parent','replace_parent','error_replacer'])for(const present of [false,true]) {
 const calls=[];
 const hook=id=>({toJSON(key){calls.push('H:'+id+':'+key);if(kind==='error')throw Error('Nested hook failed');return kind==='omit'?undefined:kind==='null'?null:{id,key,answer:42};}});
 const child=id=>({renamed:hook(id),nullable:null,required:null,note:'note'});
 const native={fixed:[child('fixed')],nested:child('nested'),list:[child('list')],lookup:{entry:child('lookup')},when:new Date(0),count:7,...(present?{maybe:hook('maybe'),optional:'present'}:{})};
 const input=placement==='root'?native:placement==='array'?[native]:{root:native};
 const replacer=mode==='whitelist'?['root','nested','renamed','id','key','answer','count','nullable','required','maybe']:
 mode==='plain'?undefined:(key,value)=>{
  calls.push('R:'+key);
  if(key==='nested'&&mode==='omit_parent')return undefined;
  if(key==='nested'&&mode==='replace_parent')return {replaced:true};
  if(key==='renamed'&&mode==='error_replacer')throw Error('Nested replacer failed');
  return value;
 };
 const result=v.safeParse(v.pipe(v.unknown(),v.stringifyJson({replacer})),input);
 rows.push({family:'nested',kind,placement,mode,present,calls,success:result.success,output:result.success?result.output:'',issues:(result.issues??[]).map(i=>({code:i.type,message:i.message,received:i.received}))});
}
// Embedding follows V json2: own keys first, embedded collisions gain a type prefix.
for(const kind of ['value','omit','null','error']) {
 const calls=[];const hook=id=>({toJSON(key){calls.push('H:'+id+':'+key);if(kind==='error')throw Error('Nested hook failed');return kind==='omit'?undefined:kind==='null'?null:{id,key,answer:42};}});
 const input={same:'outer',own:hook('own'),'EmbeddedJsonFields.same':'inner',embedded:hook('embedded')};
 const result=v.safeParse(v.pipe(v.unknown(),v.stringifyJson()),input);
 rows.push({family:'embedded',kind,calls,success:result.success,output:result.success?result.output:'',issues:(result.issues??[]).map(i=>({code:i.type,message:i.message,received:i.received}))});
}
for(const mode of ['plain','whitelist']) {
 const calls=[];const input={custom:{toJSON(){calls.push('E');return {encoded:true};}},count:7};
 const result=v.safeParse(v.pipe(v.unknown(),v.stringifyJson(mode==='whitelist'?{replacer:['count']}:undefined)),input);
 rows.push({family:'encoder',kind:'value',mode,calls,success:result.success,output:result.success?result.output:'',issues:(result.issues??[]).map(i=>({code:i.type,message:i.message,received:i.received}))});
}
writeReferenceFixture('struct_json', rows);console.log(`${rows.length} nested native struct JSON outcomes`);
