return {
  {
    "tpope/vim-fugitive",
    lazy = false,  -- load immediately

    config = function()
        -- fugitive
        local function current_branch()
          -- Get current branch name using git
          local handle = io.popen("git rev-parse --abbrev-ref HEAD 2>/dev/null")
          local result = handle:read("*a")
          handle:close()
          result = result:gsub("\n", "")  -- remove newline
          return result
        end
        vim.keymap.set("n", "<leader>gP", function()
          local branch = current_branch()
          if branch ~= "" then
            vim.cmd("Git push -u origin " .. branch)
          else
            print("Not in a git repository!")
          end
        end, { silent = true })
        vim.keymap.set("n", "<leader>gs", ":Git<CR>")           -- git status
        vim.keymap.set("n", "<leader>gS", ":Git stash -- %<CR>")           -- git stash 
        vim.keymap.set("n", "<leader>gSa", ":Git stash<CR>")           -- git stash 
        vim.keymap.set("n", "<leader>gSp", ":Git stash pop<CR>")           -- git stash pop
        vim.keymap.set("n", "<leader>gcm", ":Git commit<CR>")    -- commit
        vim.keymap.set("n", "<leader>gp", ":Git pull<CR>")      -- push
        vim.keymap.set("n", "<leader>gL", ":Git log --graph -1000<CR>")       -- log
        vim.keymap.set("n", "<leader>gLa", ":Git log --graph --all -1000<CR>")       -- log
        vim.keymap.set("n", "<leader>gbl", ":Git blame<CR>")     -- blame
        vim.keymap.set("n", "<leader>ga", ":Git add %<CR>")
        vim.keymap.set("n", "<leader>gA", ":Git add -A<CR>")
        vim.keymap.set("n", "<leader>gco", ":Git checkout %<CR>")
        vim.keymap.set("n", "<leader>gd", ":Gdiffsplit<CR>")
        vim.keymap.set("n", "<leader>gr", ":Git reset --mixed -- %<CR>")
        vim.keymap.set("n", "<leader>gra", ":Git reset --mixed<CR>")
        vim.keymap.set("n", "<leader>grs", ":Git reset --soft HEAD~1<CR>")
        vim.keymap.set("n", "<leader>grd", ":Git reset --hard HEAD~1<CR>")
        vim.keymap.set("n", "<leader>grb", ":Git rebase -i --fork-point<CR>")   -- Rebase the current branch from where it was born
    end,
  }
}
