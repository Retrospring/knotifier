REPORTER = spec
COMPILER = ls:LiveScript

test: node_modules
	@./node_modules/.bin/mocha --reporter $(REPORTER) --compilers $(COMPILER) ./test/*-test.ls

clean: node_modules
	@$(RM) -r node_modules

node_modules: package.json
	@npm prune
	@npm install

.PHONY: clean test
