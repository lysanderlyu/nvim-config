-- For refresh the gitsigns after fugitive commit the changes
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*",
  callback = function()
    vim.cmd("Gitsigns refresh")
  end,
})

-- For fugitive git status to add the file to staged
vim.api.nvim_create_autocmd("FileType", {
  pattern = "fugitive",
  callback = function()
    -- gS = stash file under cursor
    vim.keymap.set("n", "<leader>gS", function()
      local file = vim.fn.expand("<cfile>")
      if file == "" then return end
      local escaped_file = vim.fn.fnameescape(file)
      vim.cmd("Git stash -- " .. escaped_file)
    end, { buffer = true, desc = "Stage file under cursor" })

    -- gSp stash pop up file under cursor
    vim.keymap.set("n", "<leader>gSp", function()
      local file = vim.fn.expand("<cfile>")
      if file == "" then return end
      local escaped_file = vim.fn.fnameescape(file)
      vim.cmd("Git stash pop " .. escaped_file)
    end, { buffer = true, desc = "Stage file under cursor" })

    -- ga = stage file under cursor
    vim.keymap.set("n", "<leader>ga", function()
      local file = vim.fn.expand("<cfile>")
      if file == "" then return end
      local escaped_file = vim.fn.fnameescape(file)
      vim.cmd("Git add " .. escaped_file)
    end, { buffer = true, desc = "Stage file under cursor" })

    -- gr = reset file from staged under cursor
    vim.keymap.set("n", "<leader>gr", function()
      local file = vim.fn.expand("<cfile>")
      if file == "" then return end
      local escaped_file = vim.fn.fnameescape(file)
      vim.cmd("Git reset --mixed -- " .. escaped_file)
    end, { buffer = true, desc = "UnStage file under cursor" })

    -- gra = reset all the staged files under cursor
    vim.keymap.set("n", "<leader>gra", function()
      local file = vim.fn.expand("<cfile>")
      if file == "" then return end
      local escaped_file = vim.fn.fnameescape(file)
      vim.cmd("Git reset --mixed")
    end, { buffer = true, desc = "UnStage all files" })

    -- gco = checkout file under cursor
    vim.keymap.set("n", "<leader>gco", function()
      local file = vim.fn.expand("<cfile>")
      if file == "" then return end
      local escaped_file = vim.fn.fnameescape(file)
      vim.cmd("Git checkout -- " .. escaped_file)
    end, { buffer = true, desc = "Checkout file under the cursor" })

    -- Ctrl-x = open file under cursor in horizontal split
    vim.keymap.set("n", "<C-x>", function()
      local file = vim.fn.expand("<cfile>")
      if file == "" then return end
      local escaped_file = vim.fn.fnameescape(file)
      vim.cmd("split " .. escaped_file)
    end, { buffer = true, desc = "Open file in split" })

    -- Ctrl-v = open file under cursor in vertical split
    vim.keymap.set("n", "<C-v>", function()
      local file = vim.fn.expand("<cfile>")
      if file == "" then return end
      local escaped_file = vim.fn.fnameescape(file)
      vim.cmd("vsplit " .. escaped_file)
    end, { buffer = true, desc = "Open file in vsplit" })
  end,
})

-- Force Linux_Arch / kernel style inside Markdown
local function detect_kernel_style()
    local filepath = vim.fn.expand("%:p")
    -- Convert to lowercase to ignore case
    local filepath_lower = string.lower(filepath)
    
    -- Check for "linux_arch" anywhere in the path
    -- 'plain = true' ensures brackets like [Chapter 1] don't break the search
    local in_linux_arch = string.find(filepath_lower, "linux_arch", 1, true) ~= nil
    
    -- Check if Kconfig exists in current directory or any parent directory
    local kconfig_found = false
    local current_dir = vim.fn.fnamemodify(filepath,":h")
    local root_dir = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null || echo \"\""):gsub("\n$", "")
    
    -- Check in current directory and parent directories
    while current_dir ~= "" and current_dir ~= "/" do
        if vim.fn.filereadable(current_dir .. "/Kconfig") == 1 then
            kconfig_found = true
            break
        end
        
        -- If we have a git repo, stop at the root
        if root_dir ~= "" and current_dir == root_dir then
            break
        end
        
        -- Move to parent directory
        local parent_dir = vim.fn.fnamemodify(current_dir,":h")
        if parent_dir == current_dir then
            break
        end
        current_dir = parent_dir
    end
    
    if in_linux_arch or kconfig_found then
        vim.opt_local.tabstop = 8
        vim.opt_local.shiftwidth = 8
        vim.opt_local.softtabstop = 8
        vim.opt_local.expandtab = false -- Uses real tabs (\t), not spaces
    end
    vim.opt_local.wrap = true
end

vim.api.nvim_create_autocmd("FileType", {
    pattern = {"markdown", "rst"},
    callback = detect_kernel_style,
})
