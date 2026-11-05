#!/usr/bin/env -S v run

// Maintainer check: source-only snapshot, isolated VPM namespace, direct consumer build.
import os
import v.vmod

fn run_package_command(command string) {
	result := os.execute(command)
	if result.output != '' { println(result.output.trim_space()) }
	if result.exit_code != 0 {
		eprintln('Package check failed: ${command}')
		exit(1)
	}
}

root := @VMODROOT
manifest := vmod.from_file(os.join_path(root, 'v.mod')) or { panic(err) }
assert manifest.name == 'valibro'
assert manifest.version != '' && manifest.description != '' && manifest.author != ''
assert manifest.license == 'MIT'
assert manifest.repo_url == 'https://github.com/alexvyber/valibro'
assert (os.read_file(os.join_path(root, 'CHANGELOG.md')) or { panic(err) }).contains('## [${manifest.version}]')

files :=
	os.execute('git -C ${os.quoted_path(root)} ls-files --cached --others --exclude-standard -z')
assert files.exit_code == 0, files.output
staging := os.join_path(os.temp_dir(), 'valibro package ${os.getpid()}')
os.mkdir(staging) or { panic(err) }
defer { os.rmdir_all(staging) or {} }
modules := os.join_path(staging, 'modules')
package := os.join_path(modules, 'alexvyber', 'valibro')
os.mkdir_all(package) or { panic(err) }
mut count := 0
for relative in files.output.split('\x00') {
	if relative == '' { continue
	 }
	source := os.join_path(root, relative)
	if !os.is_file(source) { continue
	 }
	assert !relative.starts_with('.build/')
		&& os.file_ext(relative) !in ['.o', '.a', '.exe', '.dylib', '.so'], 'Build artifact in package: ${relative}'
	assert os.file_ext(relative) !in ['.c', '.h', '.cc', '.cpp', '.cxx', '.hpp'], 'Foreign-language source in package: ${relative}'
	target := os.join_path(package, relative)
	os.mkdir_all(os.dir(target)) or { panic(err) }
	os.cp(source, target) or { panic(err) }
	count++
}
for required in ['v.mod', 'README.md', 'LICENSE', 'THIRD_PARTY_NOTICES.md', 'CHANGELOG.md',
	'docs/install.md', 'docs/releasing.md', 'unicode/LICENSE',
	'tests/fixtures/package/package_consumer.vv'] {
	assert os.is_file(os.join_path(package, required)), 'Package is missing ${required}'
}
assert !os.exists(os.join_path(package, '.build'))
consumer := os.join_path(staging, 'consumer')
os.mkdir(consumer) or { panic(err) }
os.write_file(os.join_path(consumer, 'v.mod'),
	"Module { name: 'package_consumer' version: '0.0.0' dependencies: ['alexvyber.valibro'] }\n") or {
	panic(err)
}
os.cp(os.join_path(package, 'tests', 'fixtures', 'package/package_consumer.vv'), os.join_path(consumer,
	'main.v')) or { panic(err) }
os.setenv('VMODULES', modules, true)
os.chdir(consumer) or { panic(err) }
defer { os.chdir(root) or {} }
compiler := os.quoted_path(@VEXE)
run_package_command('${compiler} -path ${os.quoted_path('@vlib|@vmodules')} run ${os.quoted_path(os.join_path(consumer,
	'main.v'))}')
println('Package check passed: ${count} source files, isolated alexvyber.valibro import, no bootstrap or prebuilt archives')
