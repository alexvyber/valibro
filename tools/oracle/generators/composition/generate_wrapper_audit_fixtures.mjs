import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/composition/generate_wrapper_audit_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from 'node:fs';import path from 'node:path';import {pathToFileURL} from 'node:url';
const v = await loadValibot();
const rows=[];
const detail=issues=>(issues??[]).map(i=>({code:i.type,expected:i.expected??'',received:i.received,message:i.message,path:i.path?.map(p=>p.key)??[]}));
for(const wrapper of ['optional','nullable','nullish','exactOptional','undefinedable','nonOptional','nonNullable','nonNullish'])for(const outer of ['bare','pipe','fallback'])for(const input of ['', ' x ',' aa ','abcdef',...(wrapper.startsWith('non')?[undefined]:[])]) {
 const base=v.pipe(v.string(),v.trim(),v.minLength(2),v.title('inner'));
 let schema=wrapper.startsWith('non')?v[wrapper](v.optional(base)):v[wrapper](base,'default');
 if(outer==='pipe')schema=v.pipe(schema,v.check(()=>false,'Outer'),v.title('outer'));
 if(outer==='fallback')schema=v.fallback(schema,'fallback');
 const unwrapped=v.unwrap(schema);const r=unwrapped['~run']({value:input},{});
 rows.push({family:'unwrap',wrapper,outer,input_state:input===undefined?'undefined':'value',input:input??'',type:unwrapped.type,expects:unwrapped.expects,title:v.getTitle(unwrapped)??'',typed:!!r.typed,output_state:r.value===undefined?'undefined':'value',output:r.value??'',issues:detail(r.issues)});
}
for(const mode of ['object','strictObject','looseObject','objectWithRest'])for(const outer of ['bare','fallback','pipe'])for(const operation of ['pick','omit','partial','required','requiredMessage'])for(const keys of [[],['a'],['a','b']])for(const input of [null,{}, {a:'a'},{b:'b'},{a:1,b:'b'},{a:'a',b:'b',extra:1}])for(const abortEarly of [false,true]) {
 const entries={a:v.string(),b:v.optional(v.string(),'b')};
 let schema=mode==='objectWithRest'?v.objectWithRest(entries,v.number(),'Object factory'):v[mode](entries,'Object factory');
 if(outer==='fallback')schema=v.fallback(schema,{a:'recovery'});
 if(outer==='pipe')schema=v.pipe(schema,v.check(()=>false,'Outer'));
 const shaped=operation==='requiredMessage'?v.required(schema,keys,'Required factory'):v[operation](schema,keys);
 const r=shaped['~run']({value:input},{abortEarly});
 rows.push({family:'shape',mode,outer,operation,keys,input,abort_early:abortEarly,typed:!!r.typed,output:r.value,entries:Object.keys(shaped.entries),issues:detail(r.issues)});
}
writeReferenceFixture('wrapper_audit', rows);console.log(rows.length+' wrapper audit outcomes');
