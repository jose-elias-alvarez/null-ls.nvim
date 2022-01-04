generate_metadata:
	bash scripts/autogen_metadata.sh
	
test:
	nvim --headless --noplugin -u test/minimal.vim -c "lua require(\"plenary.test_harness\").test_directory_command('test/spec {minimal_init = \"test/minimal.vim\"}')"

test-file:
	nvim --headless --noplugin -u test/minimal.vim -c "lua require(\"plenary.busted\").run(\"$(FILE)\")"

.PHONY: test test-file autogen_metadata
