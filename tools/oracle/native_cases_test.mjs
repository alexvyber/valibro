import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import crypto from 'node:crypto';
import {execFileSync} from 'node:child_process';
import {caseIdentity, projectReferenceData} from './shared/native_cases.mjs';

const entry = row => ({id: caseIdentity(row), tag: 'native_path_presence'});

test('untagged Unicode, empty strings and ordinary prototype keys are retained', () => {
  const rows = [{input:''},{input:'🙂'},{input:JSON.parse('{"constructor":1,"__proto__":2}')}];
  const {data, report} = projectReferenceData('unit', rows, []);
  assert.deepEqual(data, rows);
  assert.equal(report.excluded_rows, 0);
  assert.equal(report.retained_outcomes, 3);
});

test('only an exact reviewed observation is excluded; expected values are unchanged', () => {
  const tagged = {input:0, path:['a'], success:false};
  const other = {...tagged, input:1};
  const source = [tagged, other];
  const before = JSON.stringify(source);
  const {data, report} = projectReferenceData('unit', source, [entry(tagged)]);
  assert.deepEqual(data, [other]);
  assert.equal(JSON.stringify(source), before);
  assert.equal(report.excluded_outcomes, 1);
  assert.equal(report.counts_by_tag.native_path_presence, 1);
  assert.equal(report.exclusions[0].id, caseIdentity(tagged));
});

test('identity is independent of object key order and detects changed expectations', () => {
  assert.equal(caseIdentity({a:1,b:{x:2,y:3}}), caseIdentity({b:{y:3,x:2},a:1}));
  assert.notEqual(caseIdentity({output:1}), caseIdentity({output:2}));
});

test('object-boundary tags retain unrelated arrays and changed observations', () => {
  const tagged = {schema:{kind:'object'},input:[],success:true,output:{}};
  const array = {schema:{kind:'array',item:{kind:'string'}},input:[],success:true,output:[]};
  const changed = {...tagged,success:false,output:[]};
  const {data, report} = projectReferenceData('unit',[tagged,array,changed],[{id:caseIdentity(tagged),tag:'json_object_boundary'}]);
  assert.deepEqual(data,[array,changed]);
  assert.equal(report.counts_by_tag.json_object_boundary,1);
});

test('stale IDs, unknown tags and conflicting tags fail explicitly', () => {
  const row={input:0};
  assert.throws(()=>projectReferenceData('unit',[],[entry(row)]), /Stale native case tag/);
  assert.throws(()=>projectReferenceData('unit',[row],[{id:caseIdentity(row),tag:'unknown'}]), /Unknown native case tag/);
  assert.throws(()=>projectReferenceData('unit',[row],[entry(row),{id:caseIdentity(row),tag:'native_float_spelling'}]), /Conflicting tags/);
});

test('all fixture shapes report rows and step outcomes separately', () => {
  const row={input:0,steps:[1,2,3]}, kept={input:1};
  for(const source of [[row,kept],{rows:[row,kept],descriptors:[]},{parse:[row],stringify:[kept]}]) {
    const {report}=projectReferenceData('unit',source,[entry(row)]);
    assert.equal(report.input_rows,2);
    assert.equal(report.input_outcomes,4);
    assert.equal(report.excluded_outcomes,3);
    assert.equal(report.retained_outcomes,1);
  }
});

test('manifest generation never rewrites fixtures, reports, registry or generators', {skip:!process.env.VALIBRO_UPSTREAM}, () => {
  const catalog=JSON.parse(fs.readFileSync('tools/oracle/corpora.json'));
  const paths=new Set(['tools/oracle/native_cases.json']);
  for(const value of Object.values(catalog)) {
    paths.add(value.fixture);paths.add(value.generator);
    paths.add(value.fixture.replace(/\.json$/,'.native.json'));
    const sources=value.fixture.replace(/\.json$/,'.sources.json');
    if(fs.existsSync(sources))paths.add(sources);
  }
  const hashes=()=>Object.fromEntries([...paths].map(file=>[file,crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex')]));
  const before=hashes();
  execFileSync(process.execPath,['tools/oracle/generate_differential_manifest.mjs',process.env.VALIBRO_UPSTREAM],{stdio:'pipe'});
  assert.deepEqual(hashes(),before);
});
