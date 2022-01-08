set hidden
set noswapfile

set rtp=$VIMRUNTIME
packadd plenary.nvim
packadd null-ls.nvim

lua require("null-ls.config")._set({ log = { enable = false } })
