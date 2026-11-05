import {writeReferenceFixture, corpusForFixture} from './native_cases.mjs';
import fs from 'node:fs';
import path from 'node:path';
import {execFileSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';

export const repoRoot = path.resolve(import.meta.dirname, '../../..');
export const referenceRevision = 'd72f76fcf70ccfa0a5ca341b80da1d440ac60b11';

export async function loadValibot(checkout = process.argv[2]) {
  if (!checkout) throw new Error('Pass the pinned Valibot checkout as the first argument');
  const root = path.resolve(checkout);
  const manifest = JSON.parse(fs.readFileSync(path.join(root, 'library/package.json')));
  const revision = execFileSync('git', ['-C', root, 'rev-parse', 'HEAD'], {encoding:'utf8'}).trim();
  if (manifest.version !== '1.5.0' || revision !== referenceRevision) {
    throw new Error(`Expected Valibot 1.5.0 at ${referenceRevision}; got ${manifest.version} at ${revision}`);
  }
  return import(pathToFileURL(path.join(root, 'library/src/index.ts')));
}

// Keep fixture serialization stable; paths are relative to the package root.
export function writeFixture(relative, value) {
  const corpus = corpusForFixture(relative);
  if (corpus) return writeReferenceFixture(corpus, value);
  fs.writeFileSync(path.join(repoRoot, relative), JSON.stringify(value) + '\n');
}

export function issueFields(issue, getDotPath, nested = true) {
  const result = {
    code: issue.type,
    kind: issue.kind,
    expected: issue.expected ?? '',
    received: issue.received,
    message: issue.message,
    dot: getDotPath(issue) ?? '',
  };
  if (nested) result.issues = (issue.issues ?? []).map(child=>issueFields(child, getDotPath));
  return result;
}
