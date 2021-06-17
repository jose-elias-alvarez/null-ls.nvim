.PHONY: test
test:
	nvim --headless -u test/minimal.vim -c "lua require(\"plenary.test_harness\").test_directory_command('test/spec {minimal_init = \"test/minimal.vim\"}')"

.PHONY: test-file
test-file:
	nvim --headless --noplugin -u test/minimal.vim -c "lua require(\"plenary.busted\").run(\"$(FILE)\")"
