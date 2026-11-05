# Publishing Valibro on VPM

Release candidate: **0.2.0**. Registry name: **alexvyber.valibro**.
Repository: **https://github.com/alexvyber/valibro**.

VPM publishes Git repositories, not a separately uploaded package archive. The
[official publishing instructions](https://docs.vlang.io/package-management.html#publish-package)
require a top-level `v.mod`, a public GitHub repository, pushed sources, and a
GitHub-authenticated registration at [vpm.vlang.io/new](https://vpm.vlang.io/new).
The registry combines publisher and package names. Confirm the repository/name
before submission; the official guide warns that entries cannot be self-edited.

## Verify the release candidate

Use the V compiler in `.v-version` and install the system prerequisites from
[installation](install.md). From the checkout:

```sh
v test .
v fmt -verify .
v run scripts/check_architecture.vsh
v run examples/username
v run examples/strings
v run examples/primitives
v run examples/composition
v run scripts/check_package.vsh
git diff --check
```

The package CI workflow checks clean consumer installation on Linux/macOS and
runs a core regression subset with V 0.5.2. It does not replace the full release
suite above. Word segmentation uses bundled Unicode 17 default boundaries;
reference comparisons exclude dictionary tailoring and other documented native
profiles. Native tests cover those differences; fixture generation must finish
with the differential manifest command to record fixture/report hashes.
Generators apply only reviewed case-ID tags; the manifest command never rewrites
fixtures. Maintainer oracle checks use
`VALIBRO_UPSTREAM=/path/to/valibot node --test tools/oracle/native_cases_test.mjs`.
Normal package builds and V tests require neither Node nor an upstream checkout.

Review `v.mod` (name/version/license/repository/author), `CHANGELOG.md`, README,
licenses, third-party notices, and compatibility claims. Keep the version in
`CHANGELOG.md` aligned with `v.mod`. Date the changelog entry when publishing.

`check_package.vsh` includes tracked and non-ignored untracked working-tree files
so it can validate a candidate before staging. That is not proof those files
have been committed. Review both lists before committing:

```sh
git status --short
git diff --stat
git ls-files --others --exclude-standard
```

Include all implementation modules, scripts, vendored sources/licenses, Unicode
data, checked-in fixtures, docs, and CI files. Exclude `.build/`, native object
files/static archives, executables, and local installed modules. There are no generated parser archives to distribute or rebuild.

## Publish the Git revision

Commit the reviewed candidate, then verify that committed revision in a fresh
clone before pushing. The package should build directly from sources without a bootstrap:

```sh
git clone --no-local /absolute/path/to/valibro /tmp/valibro-release-check
cd /tmp/valibro-release-check
v run scripts/check_package.vsh
v test .
```

Push the reviewed commit to `main`. After all release checks and CI pass, create
and push an annotated `v0.2.0` tag. Check that an existing tag is not being replaced.
The tag records the source release; VPM registration itself is repository-based.
No workflow in this repository automatically pushes commits, tags, or releases.

## Register and verify VPM

Sign in to [VPM registration](https://vpm.vlang.io/new) with the publishing GitHub
account. Submit the public repository URL and package name `valibro`, producing
`alexvyber.valibro` under that account. No registry credentials belong in this
repository or CI.

After registration, follow the VPM install/bootstrap instructions in
[installation](install.md) in a separate consumer project. Verify the registry
entry and the publisher-qualified imports. Once registry installation has been
verified, remove the pre-publication notice in the installation guide and set the
release date in the changelog. Subsequent source updates still require committing,
pushing, reviewing compatibility changes, and rerunning the package checks.
