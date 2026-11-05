import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {filterNativeDateRows} from '../../shared/native_scope.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/json/generate_native_hook_audit_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from 'node:fs';import path from 'node:path';import {pathToFileURL} from 'node:url';
const v = await loadValibot();
const rows=[];
const primitives={text:'42',invalid:'bad',date:'2020-01-02',number:42,fraction:1.5,nan:NaN,big:12345678901234567890n,null:null,undefined:undefined,symbol:Symbol('x'),object:{},error:null};
const describe=value=>value instanceof Date?(Number.isNaN(value.getTime())?'invalid-date':String(value.getTime())):typeof value==='bigint'?String(value):typeof value==='symbol'?'symbol':value===undefined?'undefined':typeof value==='object'?'object':String(value);
for(const action of ['toNumber','toBigint','toString','toDate','toBoolean'])for(const kind of Object.keys(primitives))for(const mode of ['default','factory','config']) {
 const calls=[];const input={[Symbol.toPrimitive](hint){calls.push(hint);if(kind==='error')throw Error('Hook failed');return primitives[kind];}};
 const result=v.safeParse(v.pipe(v.unknown(),v[action](mode==='factory'?'Factory message':undefined)),input,mode==='config'?{message:'Config message'}:{});
 rows.push({family:'primitive',action,kind,mode,calls,success:result.success,output:result.success?describe(result.output):'',issues:(result.issues??[]).map(i=>({code:i.type,expected:i.expected??'',received:i.received,message:i.message}))});
}
for(const kind of ['value','omit','null','error'])for(const placement of ['root','array','map'])for(const mode of ['default','factory','config']) {
 const calls=[];const item={toJSON(key){calls.push(key);if(kind==='error')throw Error('JSON hook failed');return kind==='omit'?undefined:kind==='null'?null:{key,value:42};}};
 const input=placement==='root'?item:placement==='array'?[item,item]:{a:item,b:item};
 const result=v.safeParse(v.pipe(v.unknown(),v.stringifyJson(undefined,mode==='factory'?'Factory message':undefined)),input,mode==='config'?{message:'Config message'}:{});
 rows.push({family:'json',kind,placement,mode,calls,success:result.success,output:result.success?result.output:'',issues:(result.issues??[]).map(i=>({code:i.type,expected:i.expected??'',received:i.received,message:i.message}))});
}
for(const input of [-8640000000000000,-1,0,1,8640000000000000,'invalid']) {
 const result=v.parse(v.pipe(v.unknown(),v.stringifyJson()),new Date(input==='invalid'?NaN:input));
 rows.push({family:'date_json',input,output:result});
}
for(const kind of ['set','map','blob','file','promise','function','fallible_function'])for(const placement of ['root','array','map']) {
 const item=kind==='set'?new Set([1,2]):kind==='map'?new Map([[{},1]]):kind==='blob'?new Blob(['x']):kind==='file'?new File(['x'],'x'):kind==='promise'?Promise.resolve(1):function(value){return value;};
 const input=placement==='root'?item:placement==='array'?[item,item]:{a:item,b:item};
 const result=v.safeParse(v.pipe(v.unknown(),v.stringifyJson()),input);
 rows.push({family:'class_json',kind,placement,success:result.success,output:result.success?result.output:'',received:result.issues?.[0].received??''});
}
for(const placement of ['map','array'])for(const mode of ['pass','omit_root','replace_root','omit_first','error_first','whitelist','reverse_whitelist']) {
 if(placement==='array'&&mode.includes('whitelist'))continue;
 const calls=[];const item={toJSON(key){calls.push('H:'+key);return 42;}};
 const input=placement==='array'?[item,item]:{a:item,b:item};
 const replacer=mode==='whitelist'?['b']:mode==='reverse_whitelist'?['b','a']:(key,value)=>{
  calls.push('R:'+key);
  if(key===''&&mode==='omit_root')return undefined;
  if(key===''&&mode==='replace_root')return {done:true};
  if((key==='a'||key==='0')&&mode==='omit_first')return undefined;
  if((key==='a'||key==='0')&&mode==='error_first')throw Error('Replacer stopped');
  return value;
 };
 const result=v.safeParse(v.pipe(v.unknown(),v.stringifyJson({replacer})),input);
 rows.push({family:'json_order',placement,mode,calls,success:result.success,output:result.success?result.output:''});
}
rows.splice(0,rows.length,...filterNativeDateRows('native_hook_audit',rows));
writeReferenceFixture('native_hook_audit', rows);console.log(rows.length+' native hook audit outcomes');
