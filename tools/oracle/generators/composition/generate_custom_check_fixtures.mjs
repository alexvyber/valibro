import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/composition/generate_custom_check_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const v = await loadValibot();
const rows=[];
const shape=v.object({a:v.string(),b:v.string(),arr:v.array(v.object({x:v.number(),y:v.string()}))});
const cases=[null,'x',[],{}, {a:1,b:'b',arr:[]},{a:'a',b:1,arr:[]},{a:'a',b:'b',arr:[]},{a:'a',b:'b',arr:[{x:'x',y:'y'}]},{a:'a',b:'b',arr:[{x:1,y:2}]},{a:'a',b:'b',arr:[{x:1,y:'y'},{x:2,y:2}]}];
const detail=issues=>(issues??[]).map(i=>({code:i.type,kind:i.kind,expected:i.expected??'',received:i.received,message:i.message,path:i.path?.map(p=>p.key)??[]}));
for(const mode of ['default','factory','config'])for(const abortEarly of [false,true])for(const abortPipeEarly of [false,true]) {
 const settings={abortEarly,abortPipeEarly,...(mode==='config'?{message:'Config message'}:{})};const message=mode==='factory'?'Factory message':undefined;
 for(const input of cases)for(const paths of [[],[[]],[['a']],[['b']],[['arr','$','x']],[['arr',0,'x']],[['arr','$','x'],['a']]]) {
  const calls=[];const schema=v.pipe(shape,v.partialCheck(paths,value=>{calls.push(structuredClone(value));return false;},message));
  const result=schema['~run']({value:structuredClone(input)},settings);
  rows.push({action:'partial',mode,input,paths,abort_early:abortEarly,abort_pipe_early:abortPipeEarly,typed:!!result.typed,output:result.value,issues:detail(result.issues),calls});
 }
 for(const input of [[],[1],[1,2]]) {
  const calls=[];
  // Native partial_check wraps the supplied schema, retaining its pipeline boundary.
  const schema=v.pipe(v.pipe(v.array(v.number()),v.forward(v.check(()=>false,message),[0]),v.transform(value=>value)),v.partialCheck([['$']],value=>{calls.push(structuredClone(value));return false;},message));
  const result=schema['~run']({value:input},settings);
  rows.push({action:'forward_partial',mode,input,paths:[['$']],abort_early:abortEarly,abort_pipe_early:abortPipeEarly,typed:!!result.typed,output:result.value,issues:detail(result.issues),calls});
 }
 for(const input of [null,0,'','a','ab','abc']) {
  const schema=v.pipe(v.unknown(),v.guard(value=>typeof value==='string'&&value.length>=2,message));
  const result=schema['~run']({value:input},settings);
  rows.push({action:'guard',mode,input,paths:[],abort_early:abortEarly,abort_pipe_early:abortPipeEarly,typed:!!result.typed,output:result.value,issues:detail(result.issues),calls:[]});
 }
}
writeReferenceFixture('custom_check', rows);
console.log(rows.length+' partial-check/guard outcomes');
