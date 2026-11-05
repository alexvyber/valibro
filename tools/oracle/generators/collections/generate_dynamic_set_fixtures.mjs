import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/collections/generate_dynamic_set_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const v = await loadValibot();
const number=x=>({$float:x});const materialize=x=>x&&typeof x==='object'&&'$float'in x?Number(x.$float):x;
const encode=x=>typeof x==='number'&&!Number.isFinite(x)?number(String(x)):x;
const pool=[null,false,true,0,1,'0','1','',number('NaN'),number('Infinity'),number('-Infinity'),number('-0'),number(1)];
const inputs=[[],[1,number(1),1],[number('NaN'),number('NaN')],[-0,number('-0'),0],[false,0,'0',true,1,'1']];
let state=0x93f2a81;const random=n=>{state^=state<<13;state^=state>>>17;state^=state<<5;return(state>>>0)%n;};
for(let i=0;i<64;i++)inputs.push(Array.from({length:random(32)},()=>pool[random(pool.length)]));
const rows=inputs.map(input=>({input,output:[...v.parse(v.set(v.unknown()),new Set(input.map(materialize)))].map(encode)}));
writeReferenceFixture('dynamic_set', rows);
console.log(rows.length+' dynamic scalar set outcomes');
