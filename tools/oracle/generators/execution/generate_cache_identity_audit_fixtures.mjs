import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/execution/generate_cache_identity_audit_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from 'node:fs';import path from 'node:path';import {pathToFileURL} from 'node:url';
const v = await loadValibot();
const rows=[];
for(const capacity of [0,1,2,4]) {
 let validations=0;const calls=[0,0];
 const callbacks=[0,1].map(id=>issue=>{calls[id]++;return `${id}:${issue.received}`;});
 const schema=v.cache(v.pipe(v.string(),v.check(()=>{validations++;return false;})),{maxSize:capacity});
 const steps=[];
 for(const [input,id,lang] of [['a',0,'en'],['a',0,'en'],['a',1,'en'],['a',0,'en'],['b',0,'en'],['a',1,'en'],['a',1,'ru'],['a',1,'ru'],['a',0,'en'],['a',0,'en']]) {
  const result=v.safeParse(schema,input,{message:callbacks[id],lang});
  steps.push({input,id,lang,validations,calls:[...calls],messages:result.issues.map(i=>i.message)});
 }
 rows.push({capacity,steps});
}
writeReferenceFixture('cache_identity_audit', rows);console.log(rows.reduce((n,row)=>n+row.steps.length,0)+' cache identity observations');
