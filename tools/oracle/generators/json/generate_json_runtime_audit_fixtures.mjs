import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/json/generate_json_runtime_audit_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from 'node:fs';import path from 'node:path';import {pathToFileURL} from 'node:url';
const v = await loadValibot();
const rows=[];const units=text=>Array.from({length:text.length},(_,i)=>text.charCodeAt(i));
for(const depth of [0,1,10,511,512,513,1024,2048,4096])for(const container of ['array','object','mixed']) {
 let value=0;for(let i=0;i<depth;i++)value=container==='array'||(container==='mixed'&&i%2===0)?[value]:{x:value};
 const result=v.safeParse(v.pipe(v.unknown(),v.stringifyJson()),value);
 if(!result.success)throw Error('Reference depth exceeded: '+depth);
 rows.push({family:'depth',depth,container,output_units:units(result.output)});
}
for(const input of [{a:[1,2],b:{x:'🙂'}},[1,{x:'\u2028\u0000'}],{'🙂':'x'},{}])for(const space of ['',2,'🙂'.repeat(6),'123456789🙂','12345678🙂x','éé']) {
 const result=v.parse(v.pipe(v.unknown(),v.stringifyJson({space})),input);
 rows.push({family:'indent',input,space,output_units:units(result)});
}
writeReferenceFixture('json_runtime_audit', rows);console.log(rows.length+' JSON depth/UTF-16 outcomes');
