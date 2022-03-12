.PHONY: test
test:
	nvim --headless --noplugin -u test/minimal.vim -c "lua require(\"plenary.test_harness\").test_directory_command('test/spec {minimal_init = \"test/minimal.vim\"}')"
.PHONY: test-file
test-file:
	nvim --headless --noplugin -u test/minimal.vim -c "lua require(\"plenary.busted\").run(\"$(FILE)\")"

.PHONY: install-hooks
install-hooks:
	pre-commit install --install-hooks
.PHONY: check
check:
	pre-commit run --all-files

# do not run manually! (runs via CI)
.PHONY: autogen
autogen:
	bash scripts/autogen.sh
