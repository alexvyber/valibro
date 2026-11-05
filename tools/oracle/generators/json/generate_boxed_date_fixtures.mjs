import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {filterNativeDateRows} from '../../shared/native_scope.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/json/generate_boxed_date_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from 'node:fs';import path from 'node:path';import {pathToFileURL} from 'node:url';
const v = await loadValibot();const rows=[];
const stamps=[-8640000000000000,-1,0,1,8640000000000000,null];
for(const timezone of ['UTC','America/New_York'])for(const stamp of stamps)for(const placement of ['root','array'])for(const action of ['toNumber','toBigint','toBoolean','toDate','toString','stringifyJson'])for(const mode of ['default','factory']) {
 process.env.TZ=timezone;const date=new Date(stamp===null?NaN:stamp),input=placement==='array'?[date]:date,message=mode==='factory'?'Factory message':undefined;
 const result=v.safeParse(v.pipe(v.unknown(),action==='stringifyJson'?v.stringifyJson(undefined,message):v[action](message)),input);
 rows.push({family:'conversion',timezone,stamp,placement,action,mode,success:result.success,typed:result.typed,output:result.success?(result.output instanceof Date?String(result.output.getTime()):String(result.output)):'',issues:(result.issues??[]).map(i=>({code:i.type,expected:i.expected??'',received:i.received,message:i.message}))});
}
process.env.TZ='UTC';
for(const family of ['serialization','provider_date'])for(const stamp of [0,-1,8640000000000000,null])for(const placement of ['root','array','map'])for(const mode of ['plain','trace','replace_with_date','replace_with_null','omit_dates','recover_null']) {
 const calls=[];const date=new Date(stamp===null?NaN:stamp);const item=family==='provider_date'?{toJSON(key){calls.push('H:'+key);return date;}}:date,input=placement==='root'?item:placement==='array'?[item]:{a:item};
 const replacer=mode==='plain'?undefined:(key,value)=>{
  calls.push(key+':'+(value===null?'null':typeof value));
  const target=placement==='root'?key==='':key==='a'||key==='0';
  if(target&&mode==='replace_with_date')return new Date(0);
  if(target&&mode==='replace_with_null')return null;
  if(target&&mode==='omit_dates')return undefined;
  if(value===null&&mode==='recover_null')return 'recovered';
  return value;
 };
 const result=v.safeParse(v.pipe(v.unknown(),v.stringifyJson({replacer})),input);
 rows.push({family,stamp,placement,mode,calls,success:result.success,output:result.success?result.output:'',issues:(result.issues??[]).map(i=>({code:i.type,received:i.received,message:i.message}))});
}
for(const stamp of [0,null])for(const action of ['toNumber','toBigint','toBoolean','toDate','toString']) {
 const calls=[];const input={[Symbol.toPrimitive](hint){calls.push(hint);return new Date(stamp===null?NaN:stamp);}};
 const result=v.safeParse(v.pipe(v.unknown(),v[action]()),input);
 rows.push({family:'primitive',stamp,action,calls,success:result.success,output:result.success?String(result.output):'',issues:(result.issues??[]).map(i=>({code:i.type,received:i.received,message:i.message}))});
}
rows.splice(0,rows.length,...filterNativeDateRows('boxed_date',rows));
writeReferenceFixture('boxed_date', rows);console.log(`${rows.length} boxed Date outcomes`);
