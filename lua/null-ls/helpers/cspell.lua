local CSPELL_CONFIG_FILES = {
    "cspell.json",
    ".cspell.json",
    "cSpell.json",
    ".Sspell.json",
    ".cspell.config.json",
}

-- find the first cspell.json file in the directory tree
local find_cspell_config = function(cwd)
    local cspell_json_file = nil
    for _, file in ipairs(CSPELL_CONFIG_FILES) do
        local path = vim.fn.findfile(file, (cwd or vim.loop.cwd()) .. ";")
        if path ~= "" then
            cspell_json_file = path
            break
        end
    end
    return cspell_json_file
end

return {
    CSPELL_CONFIG_FILES = CSPELL_CONFIG_FILES,
    find_cspell_config = find_cspell_config,
}
