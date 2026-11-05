// Exact, reviewed case tags select cross-language comparisons during generation.
// New observations are included by default; there are no input-content heuristics.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const root = path.resolve(import.meta.dirname, '../../..');
const catalog = JSON.parse(fs.readFileSync(path.join(root, 'tools/oracle/corpora.json')));
export const registry = JSON.parse(fs.readFileSync(path.join(root, 'tools/oracle/native_cases.json')));

function ordered(value) {
  if (Array.isArray(value)) return value.map(ordered);
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.keys(value).sort().map(key => [key, ordered(value[key])]));
  }
  return value;
}

export function caseIdentity(row) {
  return crypto.createHash('sha256').update(JSON.stringify(ordered(row))).digest('hex');
}

const outcomes = row => Array.isArray(row.steps) ? row.steps.length : 1;

export function projectReferenceData(corpus, source, entries = registry.corpora[corpus] ?? []) {
  const tags = new Map();
  for (const entry of entries) {
    if (!registry.tags[entry.tag]) throw new Error(`Unknown native case tag: ${entry.tag}`);
    if (tags.has(entry.id) && tags.get(entry.id) !== entry.tag) throw new Error(`Conflicting tags: ${entry.id}`);
    tags.set(entry.id, entry.tag);
  }
  const seen = new Set();
  const report = {corpus, upstream_revision: registry.revision, input_rows: 0, input_outcomes: 0,
    retained_rows: 0, retained_outcomes: 0, excluded_rows: 0, excluded_outcomes: 0,
    counts_by_tag: {}, exclusions: []};
  const select = rows => rows.filter(row => {
    const id = caseIdentity(row), count = outcomes(row);
    report.input_rows++; report.input_outcomes += count;
    const tag = tags.get(id);
    if (tag) {
      seen.add(id);
      report.excluded_rows++; report.excluded_outcomes += count;
      report.counts_by_tag[tag] = (report.counts_by_tag[tag] ?? 0) + count;
      report.exclusions.push({id, tag, outcomes: count});
      return false;
    }
    report.retained_rows++; report.retained_outcomes += count;
    return true;
  });
  let data;
  if (Array.isArray(source)) data = select(source);
  else if (Array.isArray(source.rows)) data = {...source, rows: select(source.rows)};
  else if (Array.isArray(source.parse) && Array.isArray(source.stringify)) {
    data = {...source, parse: select(source.parse), stringify: select(source.stringify)};
  } else throw new Error(`Unsupported fixture shape: ${corpus}`);
  for (const id of tags.keys()) {
    if (!seen.has(id)) throw new Error(`Stale native case tag in ${corpus}: ${id}; review it before regenerating.`);
  }
  return {data, report};
}

export function writeReferenceFixture(corpus, source) {
  const entry = catalog[corpus];
  if (!entry) throw new Error(`Unknown corpus: ${corpus}`);
  const {data, report} = projectReferenceData(corpus, source);
  fs.writeFileSync(path.join(root, entry.fixture), JSON.stringify(data) + '\n');
  fs.writeFileSync(path.join(root, entry.fixture.replace(/\.json$/, '.native.json')), JSON.stringify(report, null, 2) + '\n');
  console.log(`${corpus}: ${report.retained_outcomes} shared outcomes; ${report.excluded_outcomes} explicitly tagged native-only outcomes`);
}

export function corpusForFixture(relative) {
  return Object.entries(catalog).find(([, entry]) => entry.fixture === relative)?.[0];
}
