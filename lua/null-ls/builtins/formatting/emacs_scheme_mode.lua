local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

return h.make_builtin({
    name = "emacs/scheme-mode",
    meta = {
        url = "https://www.gnu.org/savannah-checkouts/gnu/emacs/emacs.html",
        description = [[An extensible, customizable, free/libre text editor — and more. Basically, using emacs in batch mode to format scheme files.]],
        notes = {
            [[Adjust the expression evaluated with the `--eval` flag to change settings within emacs.]],
        },
    },
    method = FORMATTING,
    filetypes = { "scheme", "scheme.guile" },
    generator_opts = {
        command = "emacs",
        args = function(params)
            return {
                "--batch",
                "--eval",
                string.format(
                    '(let (scheme-file-content next-line) (while (setq next-line (ignore-errors (read-from-minibuffer ""))) (setq scheme-file-content (concat scheme-file-content next-line "\n"))) (with-temp-buffer (scheme-mode) (setq indent-tabs-mode nil) (setq standard-indent %d) (insert scheme-file-content) (indent-region (point-min) (point-max)) (princ (buffer-string))))',
                    vim.bo[params.bufnr].shiftwidth
                ),
            }
        end,
        to_stdin = true,
    },
    factory = h.formatter_factory,
})
