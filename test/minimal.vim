set hidden
set noswapfile

set rtp+=../plenary.nvim
set rtp+=../null-ls.nvim
runtime! plugin/plenary.vim

lua require("null-ls.config")._set({ log = { enable = false } })
