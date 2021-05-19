.PHONY: test
test:
	nvim --headless -u NONE -c "lua require(\"plenary.test_harness\").test_directory_command('test/spec {minimal_init = \"test/minimal.vim\"}')"
