// node tools/oracle/generate_differential_manifest.mjs PINNED_VALIBOT_CHECKOUT
import fs from 'node:fs';
import cp from 'node:child_process';
import path from 'node:path';
import crypto from 'node:crypto';
const upstream=path.resolve(process.argv[2]);
const corpora=JSON.parse(fs.readFileSync(new URL('./corpora.json',import.meta.url)));
const fixtures=Object.entries(corpora).map(([name,{fixture,generator,scope}])=>{
 const bytes=fs.readFileSync(fixture);const data=JSON.parse(bytes);
 const profile=fixture.replace(/\.json$/,'.native.json');
 const profileBytes=fs.readFileSync(profile);const native=JSON.parse(profileBytes);
 const outcomes=Array.isArray(data)?data.reduce((sum,row)=>sum+(Array.isArray(row.steps)?row.steps.length:1),0):Array.isArray(data.rows)?data.rows.length:data.parse.length+data.stringify.length;
 if(native.retained_outcomes!==outcomes)throw new Error(`Stale native report: ${fixture}`);
 return {fixture,generator,outcomes,scope,native_profile:{file:profile,sha256:crypto.createHash('sha256').update(profileBytes).digest('hex'),candidate_outcomes:native.input_outcomes,excluded_outcomes:native.excluded_outcomes,counts_by_tag:native.counts_by_tag},sha256:crypto.createHash('sha256').update(bytes).digest('hex')};
});
const caseFile='tools/oracle/native_cases.json';
const manifest={native_cases:{file:caseFile,sha256:crypto.createHash('sha256').update(fs.readFileSync(caseFile)).digest('hex')},upstream:{package:'valibot',version:JSON.parse(fs.readFileSync(path.join(upstream,'library/package.json'))).version,revision:cp.execFileSync('git',['-C',upstream,'rev-parse','HEAD'],{encoding:'utf8'}).trim()},reference:{node:process.version,v8:process.versions.v8,icu:process.versions.icu,unicode:process.versions.unicode},outcomes:fixtures.reduce((sum,f)=>sum+f.outcomes,0),excluded_outcomes:fixtures.reduce((sum,f)=>sum+f.native_profile.excluded_outcomes,0),fixtures};
fs.writeFileSync('tests/fixtures/differential_sources.json',JSON.stringify(manifest,null,2)+'\n');
console.log(`${fixtures.length} corpora; ${manifest.outcomes} differential outcomes`);
