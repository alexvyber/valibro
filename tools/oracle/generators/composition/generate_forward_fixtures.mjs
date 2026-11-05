import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/composition/generate_forward_fixtures.mjs PINNED_VALIBOT_CHECKOUT
import fs from "node:fs";
import path from "node:path";
import {pathToFileURL} from "node:url";
const v = await loadValibot();
const rows = [];
for (const input of [null,
                     0,
                     false,
                     "",
                     "abc",
                     [],
                     [ {}, false ],
                     {a : {b : {c : 1}}},
                     {a : 0},
                     {user : [ {name : "x"} ]},
                     {user : []},
                     {user : {name : ""}},
                     {"" : {next : 1}},
])
    for (const path of [[],
                        [ "user", 0, "name" ],
                        [ "user", "name", "x" ],
                        [ "a", "b", "c" ],
                        [ "", "next" ],
                        [ "length", "x" ],
                        [ "0", "x" ],
                        [ "01", "x" ],
    ])
        for (const prior of [false, true]) {
            const before = v.rawCheck((ctx) => {
                if (prior)
                    ctx.addIssue({message : "Before"});
            });
            const forwarded = v.forward(
                v.rawCheck(
                    (ctx) => ctx.addIssue({
                        message : "Forwarded",
                        path : [ {
                            type : "unknown",
                            origin : "value",
                            input : null,
                            key : "initial",
                            value : null
                        } ],
                    }),
                    ),
                path,
            );
            let result;
            try {
                result = v.safeParse(v.pipe(v.unknown(), before, forwarded), input);
            } catch (error) {
                rows.push({input, path, prior, exception : error.message});
                continue;
            }
            rows.push({
                input,
                path,
                prior,
                exception : "",
                paths : result.issues.map((i) => i.path?.map((p) => p.key) ?? []),
 path_types: result.issues.map(i=>i.path?.map(p=>p.type)??[]),
                messages : result.issues.map((i) => i.message),
            });
        }
writeReferenceFixture('forward', rows);
console.log(rows.length + " forwarding outcomes");
