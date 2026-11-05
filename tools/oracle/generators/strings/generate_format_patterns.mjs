import {loadValibot} from '../../shared/reference.mjs';
// Generate native format tables from the pinned upstream RegExp objects.
// node tools/oracle/generators/strings/generate_format_patterns.mjs VALIBOT_CHECKOUT
import fs from "node:fs";
import path from "node:path";
import {pathToFileURL} from "node:url";
const upstream = path.resolve(process.argv[2]);
const v = await loadValibot();
const snake = (s) => s.replace(/[A-Z]/g, (c) => "_" + c.toLowerCase());
const aliases = {
    NANO_ID_REGEX : "nanoid"
};
const raw = (s) => (s.includes("'") ? 'r"' + s + '"' : "r'" + s + "'");
// Built-in format classes use explicit ASCII ranges supported by V's parser.
const nativePattern = source => source.replace(/\[(?:\\.|[^\\\]])*\]/g,
    cls => cls.replace(/\\d/g, '0-9').replace(/\\w/g, 'A-Za-z0-9_').replace(/\\\//g, '/'));
let source =
    "// Generated from pinned Valibot 1.5.0; MIT. See THIRD_PARTY_NOTICES.md.\nmodule actions\n\nimport valibro.types\n\nfn upstream_format(code string, messages []types.ErrorMessage) types.Action[string] {\n pattern, flags := match code {\n";
const labels = [];
for (const [name, regexp] of Object.entries(v)) {
    if (!(regexp instanceof RegExp))
        continue;
    const code = aliases[name] ?? name.replace(/_REGEX$/, "").toLowerCase();
    const method = Object.keys(v).find((n) => snake(n) === code && typeof v[n] === "function");
    if (!method)
        throw new Error(name);
    const text = fs.readFileSync(
        path.join(upstream, "library/src/actions", method, method + ".ts"),
        "utf8",
    );
    const label = text.match(/_addIssue\(this, '([^']+)'/)?.[1];
    if (!label)
        throw new Error(method);
    labels.push([ code, label ]);
    if (["imei", "bic", "domain", "emoji"].includes(code))
        continue;
    source += `  '${code}' { ${raw(nativePattern(regexp.source))}, '${regexp.flags.replace('u', '')}' }\n`;

}
source +=
    "  else { panic('Unknown format: ' + code) }\n }\n return string_validation_with_flags(code, pattern, flags, messages)\n}\n\nfn format_label(code string) string {\n return match code {\n";
for (const [code, label] of [...labels,
                             [ "isbn", "ISBN" ],
                             [ "credit_card", "credit card" ],
                             [ "hash", "hash" ],
])
    source += `  '${code}' { '${label}' }\n`;
source += "  else { code }\n }\n}\n";
fs.writeFileSync("actions/upstream_patterns_generated.v", source);
