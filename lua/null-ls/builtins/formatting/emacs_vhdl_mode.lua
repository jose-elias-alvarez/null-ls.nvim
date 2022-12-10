local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "emacs/vhdl-mode",
    meta = {
        url = "https://guest.iis.ee.ethz.ch/~zimmi/emacs/vhdl-mode.html",
        description = [[VHDL Mode is an Emacs major mode for editing VHDL code. Basically, using emacs in batch mode to format VHDL files.]],
        notes = {
            [[Adjust the expression evaluated with the `--eval` flag to change settings within emacs.]],
        },
    },
    method = FORMATTING,
    filetypes = { "vhdl" },
    generator_opts = {
        command = "emacs",
        args = function(params)
            return {
                "--batch",
                "--eval",
                string.format(
                    '(let (vhdl-file-content next-line) (while (setq next-line (ignore-errors (read-from-minibuffer ""))) (setq vhdl-file-content (concat vhdl-file-content next-line "\n"))) (with-temp-buffer (vhdl-mode) (vhdl-set-style "IEEE") (setq vhdl-basic-offset %d) (insert vhdl-file-content) (vhdl-beautify-region (point-min) (point-max)) (princ (buffer-string))))',
                    vim.bo[params.bufnr].shiftwidth
                ),
            }
        end,
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
