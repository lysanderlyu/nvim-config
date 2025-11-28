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
      vim.cmd("Git stash -- " .. vim.fn.expand("<cfile>"))
    end, { buffer = true, desc = "Stage file under cursor" })

    -- gSp stash pop up file under cursor
    vim.keymap.set("n", "<leader>gSp", function()
      vim.cmd("Git stash pop " .. vim.fn.expand("<cfile>"))
    end, { buffer = true, desc = "Stage file under cursor" })

    -- ga = stage file under cursor
    vim.keymap.set("n", "<leader>ga", function()
      vim.cmd("Git add " .. vim.fn.expand("<cfile>"))
    end, { buffer = true, desc = "Stage file under cursor" })

    -- gr = reset file from staged under cursor
    vim.keymap.set("n", "<leader>gr", function()
      vim.cmd("Git reset --mixed -- " .. vim.fn.expand("<cfile>"))
    end, { buffer = true, desc = "UnStage file under cursor" })

    -- gra = reset all the staged files under cursor
    vim.keymap.set("n", "<leader>gra", function()
      vim.cmd("Git reset --mixed")
    end, { buffer = true, desc = "UnStage all files" })

    -- gco = checkout file under cursor
    vim.keymap.set("n", "<leader>gco", function()
      vim.cmd("Git checkout -- " .. vim.fn.expand("<cfile>"))
    end, { buffer = true, desc = "Checkout file under the cursor" })

    -- Ctrl-x = open file under cursor in horizontal split
    vim.keymap.set("n", "<C-x>", function()
      local file = vim.fn.expand("<cfile>")
      if file ~= "" then
        vim.cmd("split " .. file)
      end
    end, { buffer = true, desc = "Open file in split" })

    -- Ctrl-v = open file under cursor in vertical split
    vim.keymap.set("n", "<C-v>", function()
      local file = vim.fn.expand("<cfile>")
      if file ~= "" then
        vim.cmd("vsplit " .. file)
      end
    end, { buffer = true, desc = "Open file in vsplit" })
  end,
})
