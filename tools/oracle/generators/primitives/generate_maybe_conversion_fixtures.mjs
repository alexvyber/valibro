import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {filterNativeDateRows} from '../../shared/native_scope.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/primitives/generate_maybe_conversion_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from 'node:fs';import path from 'node:path';import {pathToFileURL} from 'node:url';
const v = await loadValibot();const rows=[];
process.env.TZ='UTC';
const payloads={text:'42',true_text:'TRUE',empty_text:'',bad_text:'bad',zero:0,one:1,number:42,nan:NaN,yes:true,no:false,date:new Date(0),invalid_date:new Date(NaN),bigint:42n,array:[],object:{n:1},symbol:Symbol('x')};
for(const [kind,payload] of Object.entries(payloads))for(const state of ['missing','undefined','null','value'])for(const action of ['toNumber','toBigint','toBoolean','toDate','toString','parseBoolean'])for(const mode of ['default','factory']) {
 const input=state==='value'?payload:state==='null'?null:undefined;
 const message=mode==='factory'?'Factory message':undefined;
 const operation=action==='parseBoolean'?v.parseBoolean(undefined,message):v[action](message);
 const result=v.safeParse(v.pipe(v.unknown(),operation),input);
 rows.push({kind,state,action,mode,success:result.success,typed:result.typed,output:result.success?(result.output instanceof Date?String(result.output.getTime()):String(result.output)):'',issues:(result.issues??[]).map(i=>({code:i.type,expected:i.expected??'',received:i.received,message:i.message}))});
}
rows.splice(0,rows.length,...filterNativeDateRows('maybe_conversion',rows));
writeReferenceFixture('maybe_conversion', rows);console.log(`${rows.length} native Maybe conversion outcomes`);
