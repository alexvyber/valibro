import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/composition/generate_presence_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const v = await loadValibot();
const rows = [];
for (const name of ['optional', 'exactOptional', 'nullable', 'nullish', 'undefinedable',
                    'nonOptional', 'nonNullable', 'nonNullish'])
    for (const useDefault of [false, true])
        for (const input of [undefined, null, ' x ', 'xxx', 'abcde'])
            for (const abortEarly of [false, true])
                for (const abortPipeEarly of [false, true]) {
                    const base = v.pipe(v.string(), v.trim(), v.minLength(3));
                    let schema;
                    if (name.startsWith('non')) {
                        const wrapped = v.nullish(base, ...(useDefault ? [ ' xx ' ] : []));
                        schema = v[name](wrapped);
                    } else
                        schema = v[name](base, ...(useDefault ? [ ' xx ' ] : []));
                    const r = schema['~run']({value : input}, {abortEarly, abortPipeEarly});
                    const state = value => value === undefined ? 'undefined'
                                           : value === null    ? 'null'
                                                               : 'value';
                    rows.push({
                        name,
                        use_default : useDefault,
                        input_state : state(input),
                        input : input ?? '',
                        abort_early : abortEarly,
                        abort_pipe_early : abortPipeEarly,
                        typed : !!r.typed,
                        output_state : state(r.value),
                        output : r.value ?? '',
                        expects : schema.expects,
                        issues : (r.issues ?? []).map(i => ({
                                                          code : i.type,
                                                          expected : i.expected ?? '',
                                                          received : i.received,
                                                          message : i.message
                                                      }))
                    });
                }
writeReferenceFixture('presence', rows);
console.log(rows.length + ' native presence outcomes');
