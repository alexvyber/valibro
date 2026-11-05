import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/primitives/generate_native_value_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const v = await loadValibot();
const rows=[];
for(const domain of ['date','bigint']) {
 const inputs=domain==='date'?[-8640000000000000,-62167219200000,-1,0,1,1000,1700000000123,8640000000000000]:['-99999999999999999999999999999999999','-2','-1','0','1','2','99999999999999999999999999999999999'];
 const requirements=domain==='date'?[-62167219200000,0,8640000000000000]:['-1','0','99999999999999999999999999999999999'];
 const value=x=>domain==='date'?new Date(x):BigInt(x);
 for(const action of ['minValue','maxValue','gtValue','ltValue','value','notValue','values','notValues'])for(const requirement of requirements)for(const input of inputs)for(const mode of ['default','factory','config']) {
  const r=value(requirement),message=mode==='factory'?'Factory message':undefined;
  const check=v[action](action==='values'||action==='notValues'?[r,value(0),r]:r,message);
  const result=v.safeParse(v.pipe(domain==='date'?v.date():v.bigint(),check),value(input),mode==='config'?{message:'Config message'}:{});
  rows.push({domain,action,requirement,input,mode,success:result.success,issues:(result.issues??[]).map(i=>({code:i.type,expected:i.expected??'',received:i.received,message:i.message}))});
 }
}
writeReferenceFixture('native_value', rows);
console.log(rows.length+' native date/bigint value outcomes');
