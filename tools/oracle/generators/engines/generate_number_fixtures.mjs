import {writeReferenceFixture} from '../../shared/native_cases.mjs';
import {loadValibot} from '../../shared/reference.mjs';
// node tools/oracle/generators/engines/generate_number_fixtures.mjs VALIBOT_CHECKOUT
import fs from "node:fs";
import cp from "node:child_process";
import path from "node:path";
import {pathToFileURL} from "node:url";
const v = await loadValibot();
const schema = v.pipe(v.string(), v.toNumber());
const inputs = new Set([
    "",
    " ",
    "-0",
    "+0",
    "0x",
    "0b",
    "0o",
    "0Xf",
    "+0x1",
    "-0x1",
    "Infinity",
    "+Infinity",
    "-Infinity",
    "inf",
    "NaN",
    "1e999",
    "-1e999",
    "1e-999",
    "-1e-999",
    "5e-324",
    "2.2250738585072014e-308",
    "1.7976931348623157e308",
    "1.7976931348623159e308",
    "9007199254740993",
    "9007199254740995",
    "123.",
    "+.1",
    "1_000",
    "1\0",
    "0o8",
    "0b2",
    "0xg",
]);
for (const radix of [2, 8, 16])
    for (const bits of [52, 53, 54, 63, 64, 100, 200, 500, 1023, 1024, 1025, 2048])
        for (const offset of [-17n, -3n, -1n, 0n, 1n, 3n, 17n]) {
            const n = (1n << BigInt(bits)) + offset;
            inputs.add({2 : "0b", 8 : "0o", 16 : "0x"}[radix] + n.toString(radix));
        }
for (const ws of ["\t",
                  "\n",
                  "\r",
                  "\u00a0",
                  "\u1680",
                  "\u2000",
                  "\u2028",
                  "\u202f",
                  "\u205f",
                  "\u3000",
                  "\ufeff",
                  "\u0085",
                  "\u200b",
])
    for (const x of ["1", "-0", "Infinity", "0xabcdef"])
        inputs.add(ws + x + ws);
let state = 0x123456789abcdef0n;
const randomView = new DataView(new ArrayBuffer(8));
for (let i = 0; i < 8192; i++) {
    state = BigInt.asUintN(64, state * 6364136223846793005n + 1442695040888963407n);
    randomView.setBigUint64(0, state);
    const value = randomView.getFloat64(0);
    if (Number.isFinite(value))
        inputs.add(String(value));
}
const view = new DataView(new ArrayBuffer(8));
for (const value of [1e-7,
                     1e-6,
                     1e-5,
                     1e20,
                     1e21,
                     1e22,
                     1e23,
                     1000000000000000100,
                     0.1,
                     1.2345678901234567,
])
    inputs.add(String(value));
const rows = Array.from(inputs, (input) => {
    const r = v.safeParse(schema, input);
    view.setFloat64(0, r.success ? r.output : 0);
    return {
        input,
        success : r.success,
        bits : view.getBigUint64(0).toString(),
        text : r.success ? String(r.output) : "",
    };
});
writeReferenceFixture('number', rows);
console.log(rows.length + " number conversion outcomes");

fs.writeFileSync(
    "tests/fixtures/engines/numbers.sources.json",
    JSON.stringify(
        {
            reference : {
                node : process.version,
                versions : process.versions,
                valibot :
                    cp.execFileSync("git",
                                    [ "-C", path.resolve(process.argv[2]), "rev-parse", "HEAD" ], {
                                        encoding : "utf8",
                                    })
                        .trim(),
            },
            outcomes : rows.length,
            scope :
                "String conversion bits and formatting, radix boundaries and 8192 seeded binary64 samples.",
        },
        null,
        2,
        ) +
        "\n",
);
