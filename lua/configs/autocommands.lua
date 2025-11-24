-- -- lua/autocommand.lua
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "fugitive",
--   callback = function()
--     -- Only apply mapping if this is a Git status buffer
--     if vim.b.git_status then
--       vim.keymap.set("n", "<CR>", function()
--         local file = vim.fn.expand("<cfile>")
--         vim.cmd("rightbelow vsplit " .. file)
--       end, { buffer = true, silent = true })
--     end
--   end,
-- })

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
    -- ga = stage file under cursor
    vim.keymap.set("n", "<leader>ga", function()
      vim.cmd("Git add " .. vim.fn.expand("<cfile>"))
    end, { buffer = true, desc = "Stage file under cursor" })
  end,
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = "fugitive",
  callback = function()
    -- ga = stage file under cursor
    vim.keymap.set("n", "<leader>gr", function()
      vim.cmd("Git reset --mixed -- " .. vim.fn.expand("<cfile>"))
    end, { buffer = true, desc = "UnStage file under cursor" })
  end,
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = "fugitive",
  callback = function()
    -- ga = stage file under cursor
    vim.keymap.set("n", "<leader>gra", function()
      vim.cmd("Git reset --mixed")
    end, { buffer = true, desc = "UnStage all files" })
  end,
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = "fugitive",
  callback = function()
    -- ga = stage file under cursor
    vim.keymap.set("n", "<leader>gco", function()
      vim.cmd("Git checkout -- " .. vim.fn.expand("<cfile>"))
    end, { buffer = true, desc = "Checkout file under the cursor" })
  end,
})

-- For gitsigns update after fugitive commit
vim.api.nvim_create_autocmd("User", {
  pattern = "FugitiveGitPostCommit",
  callback = function()
    vim.cmd("silent! e!")           -- reload buffer from HEAD
    require('gitsigns').refresh(true)
  end,
})
