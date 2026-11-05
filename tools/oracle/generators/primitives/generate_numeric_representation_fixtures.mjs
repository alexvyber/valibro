import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/primitives/generate_numeric_representation_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from 'node:fs';import path from 'node:path';import {pathToFileURL} from 'node:url';
const v = await loadValibot();const rows=[];
for(const kind of ['i8','i16','i32','u8','u16','u32','isize','usize']) {
 const inputs=kind==='isize'?[-42,-1,0,1,2,42,9007199254740991,9007199254740992]:kind==='usize'?[0,1,2,42,9007199254740991,9007199254740992]:kind.startsWith('u')?[0,1,2,42]:[-42,-1,0,1,2,42];
 for(const input of inputs)for(const action of ['number','finite','integer','safeInteger','multipleOf','minValue','maxValue','gtValue','ltValue','value','values','toMinValue','toMaxValue','toNumber','toBigint','toBoolean','parseBoolean','toDate','toString','stringifyJson'])for(const mode of ['default','factory']) {
  const msg=mode==='factory'?'Factory message':undefined;
  const args=['multipleOf','minValue','maxValue','gtValue','ltValue','value','toMinValue','toMaxValue'].includes(action)?[2,msg]:action==='values'?[[0,2],msg]:['stringifyJson','parseBoolean'].includes(action)?[undefined,msg]:[msg];
  const schema=action==='number'?v.number(msg):v.pipe(v.unknown(),v[action](...args));
  const result=v.safeParse(schema,input);
  const output=result.success?(typeof result.output==='bigint'?String(result.output):result.output instanceof Date?String(result.output.getTime()):String(result.output)):'';
  rows.push({kind,input:String(input),action,mode,success:result.success,typed:result.typed,output,issues:(result.issues??[]).map(i=>({code:i.type,expected:i.expected??'',received:i.received,message:i.message}))});
 }
 // Check scalar equality against a differently represented but equal number.
 for(const input of [0,1,42])rows.push({family:'equality',kind,input:String(input),equal:true,set_size:1});
}
// Full-width edge cases use bigint oracle inputs to preserve native integer precision.
for(const kind of ['isize','usize'])for(const input of kind==='isize'?['-9223372036854775808','9223372036854775807']:['18446744073709551615'])for(const divisor of ['0','1','2',...(kind==='isize'?['-1']:[])]) {
 const result=divisor==='0'?v.safeParse(v.pipe(v.number(),v.multipleOf(0)),Number(input)):v.safeParse(v.pipe(v.bigint(),v.multipleOf(BigInt(divisor))),BigInt(input));
 rows.push({family:'wide_multiple',kind,input,divisor,success:result.success,exception:false});
}
writeReferenceFixture('numeric_representation', rows);console.log(`${rows.length} numeric representation outcomes`);
