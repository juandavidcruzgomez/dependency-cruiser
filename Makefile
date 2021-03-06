.SUFFIXES: .js .css .html
GIT=git
NPM=npm
NODE=node
RM=rm -f
MAKEDEPEND=node_modules/.bin/js-makedepend --exclude "node_modules|fixtures|extractor-fixtures" --system cjs
GENERATED_SOURCES=src/report/csv/csv.template.js \
	src/report/dot/dot.template.js \
	src/report/html/html.template.js

.PHONY: help dev-build install check fullcheck mostlyclean clean lint cover prerequisites static-analysis test update-dependencies run-update-dependencies depend

help:
	@echo
	@echo " -------------------------------------------------------- "
	@echo "| More information and other targets: open the Makefile  |"
	@echo " -------------------------------------------------------- "
	@echo
	@echo "Useful targets:"
	@echo
	@echo "dev-build. If necessary this ..."
	@echo "- ... recompiles the handlebar templates"
	@echo "- ... recreates a proper .npmignore"
	@echo
	@echo "fullcheck"
	@echo "- runs all possible static checks (lint, depcruise, npm outdated, nsp)"
	@echo
	@echo "update-dependencies"
	@echo "- updates node dependencies and devDependencies to latest"
	@echo "- autofixes any lint regressions and runs all tests"
	@echo "- shows the diff of package.json"
	@echo
	@echo "publish-patch, publish-minor, publish-major"
	@echo "- ups the version semver compliantly"
	@echo "- commits & tags it"
	@echo "- publishes to npm"
	@echo

# production rules
src/report/%.template.js: src/report/%.template.hbs
	./node_modules/.bin/handlebars --commonjs handlebars/runtime -f $@ $<

.npmignore: .gitignore
	cp $< $@
	echo "" >> $@
	echo "# specificly ignore for npm" >> $@
	echo ".bithoundrc" >> $@
	echo ".dependency-cruiser-custom.json" >> $@
	echo ".eslintignore" >> $@
	echo ".eslintrc.json" >> $@
	echo ".github" >> $@
	echo ".gitlab-ci.yml" >> $@
	echo ".travis.yml" >> $@
	echo "appveyor.yml" >> $@
	echo "CODE_OF_CONDUCT.md" >> $@
	echo "doc/**" >> $@
	echo "docs/**" >> $@
	echo "Makefile" >> $@
	echo "test/**" >> $@
	echo "tslint.json" >> $@

# "phony" targets
prerequisites:
	$(NPM) install

dev-build: bin/dependency-cruise $(GENERATED_SOURCES) $(ALL_SRC) .npmignore

lint:
	$(NPM) run lint
	$(NPM) run lint:types

lint-fix:
	$(NPM) run lint:fix

cover: dev-build
	$(NPM) run test:cover

publish-patch:
	$(NPM) version patch

publish-minor:
	$(NPM) version minor

publish-major:
	$(NPM) version major

profile:
	$(NODE) --prof src/cli.js -f - test
	@echo "output will be in a file called 'isolate-xxxx-v8.log'"
	@echo "- translate to readable output with:"
	@echo "    node --prof-process isolate-xxxx-v8.log | more"

test: dev-build
	$(NPM) test

nsp:
	$(NPM) run nsp

outdated:
	$(NPM) outdated

update-dependencies: run-update-dependencies dev-build test lint-fix
	$(GIT) diff package.json

run-update-dependencies:
	$(NPM) run npm-check-updates
	$(NPM) install

depgraph-doc:
	./bin/dependency-cruise -x "(^node_modules|^fs$$|^path$$)" -T dot -v .dependency-cruiser-custom.json src bin/dependency-cruise | dot -T png > doc/real-world-samples/dependency-cruiser-without-node_modules.png
	optipng doc/real-world-samples/dependency-cruiser-without-node_modules.png

depgraph:
	$(NPM) run depcruise:graph

depcruise:
	$(NPM) run depcruise

check: lint test depcruise
	./bin/dependency-cruise --version # if that runs the cli script works

fullcheck: check outdated nsp

depend:
	$(MAKEDEPEND) src/main/index.js
	$(MAKEDEPEND) --append --flat-define ALL_SRC src/main/index.js
	$(MAKEDEPEND) --append test

clean:
	$(RM) $(GENERATED_SOURCES)

# DO NOT DELETE THIS LINE -- js-makedepend depends on it.

# cjs dependencies
src/main/index.js: \
	src/extract/index.js \
	src/extract/transpile/meta.js \
	src/main/options/normalize.js \
	src/main/options/validate.js \
	src/main/ruleSet/normalize.js \
	src/main/ruleSet/validate.js \
	src/report/csv/index.js \
	src/report/dot/index.js \
	src/report/err.js \
	src/report/html/index.js \
	src/report/json.js

src/extract/index.js: \
	src/extract/addValidations.js \
	src/extract/derive/circular/index.js \
	src/extract/extract.js \
	src/extract/gatherInitialSources.js \
	src/extract/summarize.js \
	src/utl/pathToPosix.js

src/extract/addValidations.js: \
	src/validate/index.js

src/extract/derive/circular/index.js: \
	src/extract/derive/circular/dependencyEndsUpAtFrom.js

src/extract/extract.js: \
	src/extract/ast-extractors/extract-AMD-deps.js \
	src/extract/ast-extractors/extract-ES6-deps.js \
	src/extract/ast-extractors/extract-commonJS-deps.js \
	src/extract/ast-extractors/extract-typescript-deps.js \
	src/extract/ignore.js \
	src/extract/parse/toJavascriptAST.js \
	src/extract/parse/toTypescriptAST.js \
	src/extract/resolve/index.js

src/extract/ast-extractors/extract-AMD-deps.js: \
	src/extract/ast-extractors/extract-commonJS-deps.js

src/extract/ast-extractors/extract-typescript-deps.js: \
	package.json

src/extract/parse/toJavascriptAST.js: \
	src/extract/transpile/index.js

src/extract/transpile/index.js: \
	src/extract/transpile/meta.js

src/extract/transpile/meta.js: \
	package.json \
	src/extract/transpile/coffeeWrap.js \
	src/extract/transpile/javaScriptWrap.js \
	src/extract/transpile/liveScriptWrap.js \
	src/extract/transpile/typeScriptWrap.js

src/extract/transpile/coffeeWrap.js: \
	package.json

src/extract/transpile/liveScriptWrap.js: \
	package.json

src/extract/transpile/typeScriptWrap.js: \
	package.json

src/extract/parse/toTypescriptAST.js: \
	package.json

src/extract/resolve/index.js: \
	src/extract/resolve/resolve-AMD.js \
	src/extract/resolve/resolve-commonJS.js \
	src/utl/pathToPosix.js

src/extract/resolve/resolve-AMD.js: \
	src/extract/resolve/determineDependencyTypes.js \
	src/extract/resolve/localNpmHelpers.js \
	src/extract/resolve/readPackageDeps.js \
	src/utl/pathToPosix.js

src/extract/resolve/determineDependencyTypes.js: \
	src/extract/resolve/localNpmHelpers.js

src/extract/resolve/resolve-commonJS.js: \
	src/extract/resolve/determineDependencyTypes.js \
	src/extract/resolve/localNpmHelpers.js \
	src/extract/resolve/readPackageDeps.js \
	src/extract/transpile/meta.js \
	src/utl/pathToPosix.js

src/extract/gatherInitialSources.js: \
	src/extract/ignore.js \
	src/extract/transpile/meta.js

src/report/csv/index.js: \
	src/report/csv/csv.template.js \
	src/report/dependencyToIncidenceTransformer.js

src/report/dot/index.js: \
	src/report/dot/dot.template.js

src/report/html/index.js: \
	src/report/dependencyToIncidenceTransformer.js \
	src/report/html/html.template.js

src/main/options/normalize.js: \
	src/main/options/defaults.json

src/main/ruleSet/validate.js: \
	src/main/options/validate.js \
	src/main/ruleSet/jsonschema.json

# cjs dependencies
ALL_SRC=src/main/index.js \
	package.json \
	src/extract/addValidations.js \
	src/extract/ast-extractors/extract-AMD-deps.js \
	src/extract/ast-extractors/extract-ES6-deps.js \
	src/extract/ast-extractors/extract-commonJS-deps.js \
	src/extract/ast-extractors/extract-typescript-deps.js \
	src/extract/derive/circular/dependencyEndsUpAtFrom.js \
	src/extract/derive/circular/index.js \
	src/extract/extract.js \
	src/extract/gatherInitialSources.js \
	src/extract/ignore.js \
	src/extract/index.js \
	src/extract/parse/toJavascriptAST.js \
	src/extract/parse/toTypescriptAST.js \
	src/extract/resolve/determineDependencyTypes.js \
	src/extract/resolve/index.js \
	src/extract/resolve/localNpmHelpers.js \
	src/extract/resolve/readPackageDeps.js \
	src/extract/resolve/resolve-AMD.js \
	src/extract/resolve/resolve-commonJS.js \
	src/extract/summarize.js \
	src/extract/transpile/coffeeWrap.js \
	src/extract/transpile/index.js \
	src/extract/transpile/javaScriptWrap.js \
	src/extract/transpile/liveScriptWrap.js \
	src/extract/transpile/meta.js \
	src/extract/transpile/typeScriptWrap.js \
	src/main/options/defaults.json \
	src/main/options/normalize.js \
	src/main/options/validate.js \
	src/main/ruleSet/jsonschema.json \
	src/main/ruleSet/normalize.js \
	src/main/ruleSet/validate.js \
	src/report/csv/csv.template.js \
	src/report/csv/index.js \
	src/report/dependencyToIncidenceTransformer.js \
	src/report/dot/dot.template.js \
	src/report/dot/index.js \
	src/report/err.js \
	src/report/html/html.template.js \
	src/report/html/index.js \
	src/report/json.js \
	src/utl/pathToPosix.js \
	src/validate/index.js
# cjs dependencies
test/cli/formatMetaInfo.spec.js: \
	src/cli/formatMetaInfo.js

src/cli/formatMetaInfo.js: \
	src/main/index.js

src/main/index.js: \
	src/extract/index.js \
	src/extract/transpile/meta.js \
	src/main/options/normalize.js \
	src/main/options/validate.js \
	src/main/ruleSet/normalize.js \
	src/main/ruleSet/validate.js \
	src/report/csv/index.js \
	src/report/dot/index.js \
	src/report/err.js \
	src/report/html/index.js \
	src/report/json.js

src/extract/index.js: \
	src/extract/addValidations.js \
	src/extract/derive/circular/index.js \
	src/extract/extract.js \
	src/extract/gatherInitialSources.js \
	src/extract/summarize.js \
	src/utl/pathToPosix.js

src/extract/addValidations.js: \
	src/validate/index.js

src/extract/derive/circular/index.js: \
	src/extract/derive/circular/dependencyEndsUpAtFrom.js

src/extract/extract.js: \
	src/extract/ast-extractors/extract-AMD-deps.js \
	src/extract/ast-extractors/extract-ES6-deps.js \
	src/extract/ast-extractors/extract-commonJS-deps.js \
	src/extract/ast-extractors/extract-typescript-deps.js \
	src/extract/ignore.js \
	src/extract/parse/toJavascriptAST.js \
	src/extract/parse/toTypescriptAST.js \
	src/extract/resolve/index.js

src/extract/ast-extractors/extract-AMD-deps.js: \
	src/extract/ast-extractors/extract-commonJS-deps.js

src/extract/ast-extractors/extract-typescript-deps.js: \
	package.json

src/extract/parse/toJavascriptAST.js: \
	src/extract/transpile/index.js

src/extract/transpile/index.js: \
	src/extract/transpile/meta.js

src/extract/transpile/meta.js: \
	package.json \
	src/extract/transpile/coffeeWrap.js \
	src/extract/transpile/javaScriptWrap.js \
	src/extract/transpile/liveScriptWrap.js \
	src/extract/transpile/typeScriptWrap.js

src/extract/transpile/coffeeWrap.js: \
	package.json

src/extract/transpile/liveScriptWrap.js: \
	package.json

src/extract/transpile/typeScriptWrap.js: \
	package.json

src/extract/parse/toTypescriptAST.js: \
	package.json

src/extract/resolve/index.js: \
	src/extract/resolve/resolve-AMD.js \
	src/extract/resolve/resolve-commonJS.js \
	src/utl/pathToPosix.js

src/extract/resolve/resolve-AMD.js: \
	src/extract/resolve/determineDependencyTypes.js \
	src/extract/resolve/localNpmHelpers.js \
	src/extract/resolve/readPackageDeps.js \
	src/utl/pathToPosix.js

src/extract/resolve/determineDependencyTypes.js: \
	src/extract/resolve/localNpmHelpers.js

src/extract/resolve/resolve-commonJS.js: \
	src/extract/resolve/determineDependencyTypes.js \
	src/extract/resolve/localNpmHelpers.js \
	src/extract/resolve/readPackageDeps.js \
	src/extract/transpile/meta.js \
	src/utl/pathToPosix.js

src/extract/gatherInitialSources.js: \
	src/extract/ignore.js \
	src/extract/transpile/meta.js

src/report/csv/index.js: \
	src/report/csv/csv.template.js \
	src/report/dependencyToIncidenceTransformer.js

src/report/dot/index.js: \
	src/report/dot/dot.template.js

src/report/html/index.js: \
	src/report/dependencyToIncidenceTransformer.js \
	src/report/html/html.template.js

src/main/options/normalize.js: \
	src/main/options/defaults.json

src/main/ruleSet/validate.js: \
	src/main/options/validate.js \
	src/main/ruleSet/jsonschema.json

test/cli/index.spec.js: \
	src/cli/index.js \
	test/cli/deleteDammit.utl.js \
	test/utl/testutensils.js

src/cli/index.js: \
	src/cli/defaults.json \
	src/cli/formatMetaInfo.js \
	src/cli/initRules.js \
	src/cli/normalizeOptions.js \
	src/cli/validateFileExistence.js \
	src/main/index.js

src/cli/initRules.js: \
	src/cli/rules.starter.json

src/cli/normalizeOptions.js: \
	src/cli/defaults.json

test/cli/initRules.spec.js: \
	src/cli/initRules.js \
	src/main/ruleSet/jsonschema.json \
	test/cli/deleteDammit.utl.js

test/cli/normalizeOptions.spec.js: \
	src/cli/normalizeOptions.js

test/cli/validateFileExistence.spec.js: \
	src/cli/validateFileExistence.js

test/extract/ast-extractors/extract-typescript-commonjs.spec.js: \
	test/extract/ast-extractors/extract-typescript.utl.js

test/extract/ast-extractors/extract-typescript.utl.js: \
	src/extract/ast-extractors/extract-typescript-deps.js \
	src/extract/parse/toTypescriptAST.js

test/extract/ast-extractors/extract-typescript-exports.spec.js: \
	test/extract/ast-extractors/extract-typescript.utl.js

test/extract/ast-extractors/extract-typescript-imports.spec.js: \
	test/extract/ast-extractors/extract-typescript.utl.js

test/extract/ast-extractors/extract-typescript-triple-slash-directives.spec.js: \
	test/extract/ast-extractors/extract-typescript.utl.js

test/extract/derivations/circular/dependencyEndsUpAtFrom.spec.js: \
	src/extract/derive/circular/dependencyEndsUpAtFrom.js

test/extract/extract.spec.js: \
	src/extract/extract.js

test/extract/gatherInitialSources.spec.js: \
	src/extract/gatherInitialSources.js \
	src/utl/pathToPosix.js

test/extract/index.spec.js: \
	src/extract/index.js \
	src/extract/jsonschema.json

test/extract/resolve/determineDependencyTypes.spec.js: \
	src/extract/resolve/determineDependencyTypes.js

test/extract/resolve/localNpmHelpers.spec.js: \
	src/extract/resolve/localNpmHelpers.js

test/extract/resolve/readPackageDeps.spec.js: \
	package.json \
	src/extract/resolve/readPackageDeps.js

test/extract/transpile/coffeeWrap.spec.js: \
	src/extract/transpile/coffeeWrap.js

test/extract/transpile/index.spec.js: \
	src/extract/transpile/index.js

test/extract/transpile/javascriptWrap.spec.js: \
	src/extract/transpile/javaScriptWrap.js

test/extract/transpile/liveScriptWrap.spec.js: \
	src/extract/transpile/liveScriptWrap.js

test/extract/transpile/meta.spec.js: \
	src/extract/transpile/javaScriptWrap.js \
	src/extract/transpile/liveScriptWrap.js \
	src/extract/transpile/meta.js

test/extract/transpile/typeScriptWrap.spec.js: \
	src/extract/transpile/typeScriptWrap.js

test/main/main.spec.js: \
	src/extract/jsonschema.json \
	src/main/index.js

test/main/options/normalize.spec.js: \
	src/main/options/normalize.js

test/main/options/validate.spec.js: \
	src/main/options/validate.js

test/main/ruleSet/normalize.spec.js: \
	src/main/ruleSet/normalize.js

test/main/ruleSet/validate.spec.js: \
	src/main/ruleSet/validate.js

test/report/dependencyToIncidenceTransformer.spec.js: \
	src/report/dependencyToIncidenceTransformer.js

test/report/dot.spec.js: \
	src/report/dot/index.js

test/report/err.spec.js: \
	src/report/err.js

test/report/html.spec.js: \
	src/report/html/index.js

test/utl/pathToPosix.spec.js: \
	src/utl/pathToPosix.js

test/validate/index.spec.js: \
	src/main/ruleSet/normalize.js \
	src/main/ruleSet/validate.js \
	src/validate/index.js

