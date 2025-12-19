local c_std_prefixes = { "str", "mem", "f", "scanf", "printf", "get", "put" }

local function is_c_std_function(word)
    for _, prefix in ipairs(c_std_prefixes) do
        if word:match("^" .. prefix) then
            return true
        end
    end
    return false
end

-- 2. Show man page in floating window with syntax highlighting
local function show_man_hover(word)
    -- Capture man page output
    local handle = io.popen("man 3 " .. word .. " | col -b")
    local result = handle:read("*a")
    handle:close()

    if result == "" then
        vim.notify("No man page found for " .. word, vim.log.levels.WARN)
        return
    end

    -- Split output into lines
    local lines = vim.split(result, "\n")

    -- Create buffer and floating window
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    -- Set buffer filetype to C for syntax highlighting
    vim.api.nvim_buf_set_option(buf, "filetype", "c")
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

    vim.api.nvim_open_win(buf, true, {
        relative = "cursor",
        row = 1,
        col = 0,
        width = math.min(100, vim.o.columns - 4),
        height = math.min(40, vim.o.lines - 4),
        style = "minimal",
        border = "rounded",
    })
end

-- 3. Hybrid hover function
local function hybrid_hover()
    local word = vim.fn.expand("<cword>")
    if is_c_std_function(word) then
        show_man_hover(word)
    else
        vim.lsp.buf.hover()
    end
end

-- 4. Map K to hybrid hover for C/C++ files
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "c", "cpp", "h", "hpp" },
    callback = function()
        vim.keymap.set("n", "K", hybrid_hover, { noremap = true, silent = true, buffer = true })
    end,
})
