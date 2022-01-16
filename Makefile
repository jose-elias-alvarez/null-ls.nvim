generate_metadata:
	bash scripts/autogen_metadata.sh
	
test:
	nvim --headless --noplugin -u test/minimal.vim -c "lua require(\"plenary.test_harness\").test_directory_command('test/spec {minimal_init = \"test/minimal.vim\"}')"

test-file:
	nvim --headless --noplugin -u test/minimal.vim -c "lua require(\"plenary.busted\").run(\"$(FILE)\")"

# Installs pre-commit hooks
.PHONY: install-hooks
install-hooks:
	pre-commit install --install-hooks

# Runs pre-commit checks on files
.PHONY: check
check:
	pre-commit run --all-files

.PHONY: test test-file autogen_metadata
