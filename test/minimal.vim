set hidden
set noswapfile

set rtp=$VIMRUNTIME
set rtp+=../plenary.nvim
set rtp+=../nvim-lspconfig
set rtp+=../null-ls.nvim
runtime! plugin/plenary.vim
runtime! plugin/lspconfig.vim
