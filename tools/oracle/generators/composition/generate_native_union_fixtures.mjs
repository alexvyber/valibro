import {loadValibot, issueFields, writeFixture} from '../../shared/reference.mjs';
// node tools/oracle/generators/composition/generate_native_union_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const v = await loadValibot();
const rows=[];
function scalar(x){return (typeof x==='string'?'s:':'n:')+String(x);}
const issue = i => issueFields(i, v.getDotPath);
const choices=[[],['positive'],['positive','negative'],['positive','positive'],['gate','positive'],['gate','gate'],['positive','accept'],['gate','accept']];
for(const branches of choices)for(const input of ['bad','','0','1','-1','42'])for(const abortEarly of [false,true])for(const abortPipeEarly of [false,true])for(const mode of ['default','factory','config'])for(const placement of ['root','array','map','set','struct','nested_struct'])for(const after of ['plain','transform','fallback']) {
 const calls=[];const message=mode==='factory'?'Factory message':undefined;
 const options=branches.map((kind,index)=>{
  const base=kind==='gate'?v.pipe(v.string(),v.check(x=>{calls.push(index+':gate:'+x);return false;},message)):v.string();
  const converted=v.pipe(base,v.toNumber(message));
  return ['gate','accept'].includes(kind)?converted:v.pipe(converted,v.check(x=>{calls.push(index+':'+kind+':'+x);return kind==='positive'?x>0:x<0;},message));
 });
 const union=v.union(options,message);
 const item=after==='transform'?v.pipe(union,v.transform(x=>{calls.push('after:'+x);return x+100;})):after==='fallback'?v.fallback(union,-99):union;
 const schema=placement==='root'?item:placement==='array'?v.array(item):placement==='map'?v.map(v.string(),item):placement==='struct'?v.object({a:item,b:item}):placement==='nested_struct'?v.object({details:v.object({a:item,b:item})}):v.set(item);
 const data=placement==='root'?input:placement==='array'?[input,'2']:placement==='map'?new Map([['a',input],['b','2']]):placement==='struct'?{a:input,b:'2'}:placement==='nested_struct'?{details:{a:input,b:'2'}}:new Set([input,'2']);
 const d=schema['~run']({value:data},{abortEarly,abortPipeEarly,message:mode==='config'?'Config message':undefined});
 const output=placement==='root'?scalar(d.value):placement==='struct'?Object.entries(d.value).map(([k,x])=>[k,scalar(x)]):placement==='nested_struct'?Object.entries(d.value).map(([k,x])=>[k,Object.entries(x).map(([n,y])=>[n,scalar(y)])]):placement==='map'?[...d.value].map(([k,x])=>[k,scalar(x)]):[...d.value].map(scalar);
 rows.push({branches,input,after,abort_early:abortEarly,abort_pipe_early:abortPipeEarly,mode,placement,typed:d.typed??false,success:!d.issues,output,calls,issues:(d.issues??[]).map(issue)});
}
writeFixture('tests/fixtures/composition/native_union_differential.json',rows);
console.log(`${rows.length} native union outcomes`);
