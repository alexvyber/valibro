import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/collections/generate_partial_equality_fixtures.mjs PINNED_VALIBOT_CHECKOUT
// Objects are interned to model the explicitly selected native value equality.
import fs from 'node:fs';import path from 'node:path';import {pathToFileURL} from 'node:url';
const v = await loadValibot();
const rows=[];
const kinds=['f32','f64','i8','i16','int','i64','isize','u8','u16','u32','u64','usize','bool','struct','array','map','json'];
for(const kind of kinds)for(const family of ['set','map'])for(const input of [['one','uno','bad','two','dos'],['bad','one','uno'],['one','uno','bad'],['negative_zero','zero','bad'],['nan_a','nan_b','bad']])for(const abortEarly of [false,true])for(const abortPipeEarly of [false,true]) {
 const pool=new Map();const make=key=>{
  let number=key==='two'||key==='dos'?2:key.startsWith('nan')?NaN:key==='negative_zero'?-0:key==='zero'?0:1;
  if(kind!=='f32'&&kind!=='f64'&&kind!=='json'&&Number.isNaN(number))number=3;
  const id=String(number);
  if(!pool.has(id))pool.set(id,kind==='struct'?{value:number}:kind==='array'?[number]:kind==='map'?{value:number}:kind==='bool'?number!==0:number);
  return pool.get(id);
 };
 const item=v.pipe(v.custom(value=>value!=='bad'),v.transform(make));
 const schema=family==='set'?v.set(item):v.map(item,v.string());
 const value=family==='set'?new Set(input):new Map(input.map((key,index)=>[key,String(index)]));
 const result=schema['~run']({value},{abortEarly,abortPipeEarly});
 const encode=value=>typeof value==='number'&&Number.isNaN(value)?'NaN':value;
 const output=family==='set'?[...result.value].map(encode):[...result.value].map(([key,value])=>[encode(key),value]);
 rows.push({kind,family,input,abort_early:abortEarly,abort_pipe_early:abortPipeEarly,typed:!!result.typed,output,issues:(result.issues??[]).map(i=>({code:i.type,message:i.message}))});
}
writeReferenceFixture('partial_equality', rows);console.log(`${rows.length} partial-output equality outcomes`);
