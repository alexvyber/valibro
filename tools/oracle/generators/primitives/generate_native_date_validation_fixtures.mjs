import {loadValibot, issueFields, writeFixture} from '../../shared/reference.mjs';
// node tools/oracle/generators/primitives/generate_native_date_validation_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from 'node:fs';import path from 'node:path';import {pathToFileURL} from 'node:url';
const v = await loadValibot();
const cases=[...[-8640000000000000,-1,0,1709164800000,8640000000000000].map(stamp=>({name:String(stamp),stamp})),
 ...[{year:-271822},{year:275761},{year:2023},{month:0},{month:13},{day:0},{day:30},{hour:-1},{hour:24},{minute:-1},{minute:60},{second:-1},{second:60},{nanosecond:-1},{nanosecond:1000000000}].map((fields,index)=>({name:'malformed_'+index,fields})),{name:'zero',fields:{}},{name:'past_max',fields:{year:275760,month:9,day:13,nanosecond:1}}];
const rows=[];
for(const spec of cases)for(const placement of ['root','array'])for(const mode of ['default','factory','config'])for(const abortEarly of [false,true])for(const abortPipeEarly of [false,true]) {
 const date=new Date(spec.stamp??NaN), message=mode==='factory'?'Factory message':undefined;
 const schema=placement==='root'?v.date(message):v.array(v.date(message));
 const input=placement==='root'?date:[date,new Date(0)];
 const d=schema['~run']({value:input},{abortEarly,abortPipeEarly,message:mode==='config'?'Config message':undefined});
 const encode=x=>Number.isNaN(x.getTime())?'invalid':String(x.getTime());
 rows.push({...spec,placement,mode,abort_early:abortEarly,abort_pipe_early:abortPipeEarly,success:!d.issues,typed:d.typed??false,output:placement==='root'?encode(d.value):d.value.map(encode),issues:(d.issues??[]).map(i=>issueFields(i,v.getDotPath,false))});
}
writeFixture('tests/fixtures/primitives/native_date_validation_differential.json',rows);console.log(`${rows.length} native Date validation outcomes`);
