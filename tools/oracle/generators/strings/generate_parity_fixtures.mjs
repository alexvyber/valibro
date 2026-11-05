import {loadValibot} from '../../shared/reference.mjs';
// Usage: node tools/oracle/generators/strings/generate_parity_fixtures.mjs UPSTREAM_CHECKOUT TYPESCRIPT_JS
// TypeScript is a maintainer-only parser dependency; fixtures require neither it nor Node.
// Scope: retained shared format rules and transformations. URL and native Unicode
// casing have their own V contracts; Unicode fixtures are generated separately.
import fs from "node:fs";
import path from "node:path";
import {pathToFileURL} from "node:url";
const upstream = path.resolve(process.argv[2]);
const ts = (await import(pathToFileURL(path.resolve(process.argv[3])))).default;
const v = await loadValibot();
const names = [
    "base64",     "bic",           "cuid2",
    "decimal",    "digits",        "domain",
    "email",      "hexadecimal",   "hexColor",
    "ipv4",       "ipv6",          "ip",
    "isoDate",    "isoDateTime",   "isoDateTimeSecond",
    "isoTime",    "isoTimeSecond", "isoTimestamp",
    "isoWeek",    "jwsCompact",    "isrc",
    "ksuid",      "mac",           "mac48",
    "mac64",      "nanoid",        "octal",
    "rfcEmail",   "slug",          "ulid",
    "uuid",       "imei",          "isbn",
    "creditCard",
];
const rows = [];
for (const name of names) {
    const file = path.join(upstream, `library/src/actions/${name}/${name}.test.ts`);
    const tree = ts.createSourceFile(
        file,
        fs.readFileSync(file, "utf8"),
        ts.ScriptTarget.Latest,
        true,
    );
    const samples = new Set([ "", " ", "\n", "x", "123", "é", "🙂" ]);
    const visit = (node) => {
        if (ts.isArrayLiteralExpression(node)) {
            for (const e of node.elements) {
                if (ts.isStringLiteral(e) || ts.isNoSubstitutionTemplateLiteral(e))
                    samples.add(e.text);
            }
        }
        ts.forEachChild(node, visit);
    };
    visit(tree);
    const schema = v.pipe(v.string(), v[name]());
    for (const input of samples) {
        if (!input.isWellFormed())
            continue; // Native V strings use UTF-8, not lone UTF-16 surrogates.
        const action = name.replace(/[A-Z]/g, (x) => "_" + x.toLowerCase());
        rows.push({action, input, valid : v.safeParse(schema, input).success});
    }
}
fs.mkdirSync("tests/fixtures", {recursive : true});
fs.writeFileSync("tests/fixtures/strings/string_formats.json", JSON.stringify(rows, null, 2) + "\n");
console.log(`${rows.length} upstream format cases`);
const samples = [
    "",
    "a",
    "hello world",
    "  Alex  ",
    "é",
    "e\u0301",
    "🙂",
    "👩🏽‍💻",
    "🇷🇺",
    "👨‍👩‍👧‍👦",
    "\r\n",
    "क्‍ष",
    "東京に行きます",
    "ภาษาไทย",
    "don't stop!",
    "Straße",
    "İSTANBUL",
    "ΟΣ",
    "parseURLValue",
    "HTTP2Parser",
    "item2Name",
    "XMLHttpRequest",
    "__hello--WORLD__",
    "\ufeff\u00a0a\u2028 ",
    "\u0085a\u0085",
    "\u0000x",
    "ＡＢＣ ① ﬁ",
    "각",
    "𐐀𐐨",
];
const measurementRows = [];
for (const input of samples) {
    measurementRows.push({
        input,
        length : input.length,
        bytes : Buffer.byteLength(input),
        code_points : [...input ].length,
    });
}
fs.writeFileSync(
    "tests/fixtures/strings/string_measurements.json",
    JSON.stringify(measurementRows, null, 2) + "\n",
);
const transforms = [
    "trim",
    "trimStart",
    "trimEnd",
    "toLowerCase",
    "toUpperCase",
    "toCamelCase",
    "toPascalCase",
    "toKebabCase",
    "toSnakeCase",
    "toString",
    "toMinValue",
    "toMaxValue",
    "stringifyJson",
];
const transformationRows = [];
for (const name of transforms) {
    const args = [ "toMinValue", "toMaxValue" ].includes(name) ? [ "m" ] : [];
    for (const input of samples) {
        // Retain the original ASCII casing corpus. Full Unicode mappings and
        // contextual casing are covered by generate_unicode_parity.mjs and
        // string_transformations_test.v.
        if ([
                "toLowerCase",
                "toUpperCase",
                "toCamelCase",
                "toPascalCase",
                "toKebabCase",
                "toSnakeCase",
            ].includes(name) &&
            /[^\x00-\x7f]/.test(input))
            continue;
        transformationRows.push({
            action : name.replace(/[A-Z]/g, (x) => "_" + x.toLowerCase()),
            input,
            output : v.parse(v.pipe(v.string(), v[name](...args)), input),
        });
    }
}
fs.writeFileSync(
    "tests/fixtures/strings/string_transformations.json",
    JSON.stringify(transformationRows, null, 2) + "\n",
);
console.log(
    `${measurementRows.length} measurement cases; ${
        transformationRows.length} transformation cases`,
);
