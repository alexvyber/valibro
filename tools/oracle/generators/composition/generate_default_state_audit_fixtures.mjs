import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/composition/generate_default_state_audit_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from 'node:fs';import path from 'node:path';import {pathToFileURL} from 'node:url';
const v = await loadValibot();const rows=[];
const state=value=>value===undefined?'undefined':value===null?'null':'value';
for(const kind of ['optional','nullable','nullish','undefinedable','exactOptional'])for(const defaultKind of ['valid','invalid','null','undefined'])for(const input of [...(kind==='exactOptional'?[undefined]:[undefined,null,'  xx  '])])for(const abortEarly of [false,true]) {
 const defaultValue=defaultKind==='valid'?'  xx  ':defaultKind==='invalid'?'x':defaultKind==='null'?null:undefined;let calls=0;
 const schema=v[kind](v.pipe(v.string(),v.trim(),v.minLength(2)),()=>{calls++;return defaultValue;});
 const introspection=v.getDefault(schema);const object=kind==='exactOptional';
 // A native Missing input includes the object's default-resolution step, then runs the entry itself.
 const selected=object?v.getDefault(schema,{value:undefined},{abortEarly}):input;
 const result=schema['~run']({value:selected},{abortEarly});
 const value=result.value;
 rows.push({kind,default_kind:defaultKind,input_state:object?'missing':state(input),input:input??'',abort_early:abortEarly,introspection_state:state(introspection),introspection:introspection??'',calls,typed:!!result.typed,output_state:state(value),output:value??'',issues:(result.issues??[]).map(i=>({code:i.type,expected:i.expected??'',received:i.received,message:i.message}))});
}
writeReferenceFixture('default_state_audit', rows);console.log(rows.length+' computed default state observations');
