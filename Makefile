.PHONY: test
test:
	nvim --headless --noplugin -u test/minimal_init.lua -c "lua require(\"plenary.test_harness\").test_directory_command('test/spec {minimal_init = \"test/minimal_init.lua\"}')"
.PHONY: test-file
test-file:
	nvim --headless --noplugin -u test/minimal_init.lua -c "lua require(\"plenary.busted\").run(\"$(FILE)\")"

.PHONY: install-hooks
install-hooks:
	pre-commit install --install-hooks
.PHONY: check
check:
	pre-commit run --all-files

clean:
	rm -rf .tests/

# do not run manually! (runs via CI)
.PHONY: autogen
autogen:
	bash scripts/autogen.sh
