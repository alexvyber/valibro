import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/execution/generate_error_path_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const v = await loadValibot();
const paths=[undefined,[],[''],['',''],['','x'],['x',''],['','',0,'x'],[0,'',2],['a.b','x'],['__proto__'],['constructor'],[null],[true],['x',false],['x',{}],[1.5,-2]];
const rows=[];
for(let i=0;i<paths.length;i++) {
 const selected=[paths[i],undefined,['',i],paths[(i+1)%paths.length]];
 const issues=selected.map((keys,index)=>({message:'Error '+index,...(keys?{path:keys.map(key=>({key}))}:{})}));
 const flat=v.flatten(issues);
 // Native maps retain the message accessible through __proto__ as an own entry.
 // JS prototype mutation itself is outside the native object model.
 const nested=Object.entries(flat.nested??{});
 if(flat.nested && Array.isArray(Object.getPrototypeOf(flat.nested)))nested.push(['__proto__',flat.nested.__proto__]);
 rows.push({paths:selected.map(keys=>({present:!!keys,keys:keys??[]})),dots:issues.map(issue=>v.getDotPath(issue)??''),flat:{root:flat.root??[],nested:Object.fromEntries(nested),other:flat.other??[]},summary:v.summarize(issues)});
}
writeReferenceFixture('error_path', rows);
console.log(rows.length+' error path outcomes');
