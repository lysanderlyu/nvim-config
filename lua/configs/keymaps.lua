local builtin = require("telescope.builtin")
local opts = { noremap = true, silent = true }

-- Custom command key
-- Quick select all the text
vim.keymap.set("n", "<leader>;a", "ggVG", { desc = "Select All" })

-- tab keymaps
vim.keymap.set("n", "<leader>tq", ":tabclose<cr>", { desc = "Close tab" })
vim.keymap.set("n", "<leader>;0", ":tablast<cr>", { desc = "Last Tab" })
for i = 1, 9 do
  vim.keymap.set("n", ";" .. i, ":tabn " .. i .. "<CR>", { desc = "Go to tab " .. i })
end
vim.keymap.set("n", "<leader>tt", ":tabnew<cr>", { desc = "New Tab" })
vim.keymap.set("n", "<leader>lt", ":tabnext<cr>", { desc = "Next Tab" })
vim.keymap.set("n", "<leader>ht", ":tabprevious<cr>", { desc = "Previous Tab" })

-- Soil 
vim.keymap.set("n", "<leader>si", ":Soil<CR>", { noremap = true, silent = true })
-- :w and :q 
vim.keymap.set("n", "<leader>;w", ":w<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>;q", ":q<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>;W", ":wq<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>;Q", ":q!<CR>", { noremap = true, silent = true })
-- for :!./build.sh
vim.keymap.set("n", "<leader>;l", ":!./build.sh<CR>", { noremap = true, silent = true })
-- vim.keymap.set("n", "<leader>;l", ":terminal ./build.sh<CR>", { noremap = true, silent = true })
-- for remove the \r character
vim.keymap.set("n", "<leader>;r", ":%s/\\r//g<CR>", { noremap = true, silent = true })

-- for register + shortcut
-- Function: Yank N lines into system clipboard
local function yank_n_lines()
  local count = vim.v.count  -- number typed before ;
  if count == 0 then count = 1 end -- default to 1 if none
  vim.cmd('normal! ' .. count .. '"+yy')
  print(" Copied " .. count .. " line(s) to clipboard")
end
vim.keymap.set('n', ';y', yank_n_lines, { desc = "Yank N lines to clipboard", silent = true })
local function delete_n_lines()
  local count = vim.v.count  -- number typed before ;
  if count == 0 then count = 1 end -- default to 1 if none
  vim.cmd('normal! ' .. count .. '"+dd')
  print(" Deleted " .. count .. " line(s) to clipboard")
end
vim.keymap.set('n', ';d', delete_n_lines, { desc = "Delete N lines to clipboard", silent = true })
vim.keymap.set("v", "';", '"+y', { desc = "Yank to system clipboard" })
vim.keymap.set({"n", "v"}, ";'", '"+p', { desc = "Paste from system clipboard" })

-- shortcut for select the whole line (without the space on the head and tail)
vim.keymap.set("n", "vl", '^vg_', { desc = "Select whole line" })

-- Telescope file finder
vim.keymap.set("n", "<leader>sh", builtin.help_tags, opts)

-- Fzf finder
-- vim.api.nvim_set_keymap('n', '<leader>ff', ':Files<CR>', { noremap = true, silent = true })

-- telescope Git
vim.keymap.set("n", "<leader>go", builtin.git_status, opts)
vim.keymap.set("n", "<leader>gb", builtin.git_branches, opts)

-- fugitive
vim.keymap.set("n", "<leader>gs", ":Git<CR>")           -- git status
vim.keymap.set("n", "<leader>gS", ":Git stash -- %<CR>")           -- git stash 
vim.keymap.set("n", "<leader>gSa", ":Git stash<CR>")           -- git stash 
vim.keymap.set("n", "<leader>gSp", ":Git stash pop<CR>")           -- git stash pop
vim.keymap.set("n", "<leader>gcm", ":Git commit<CR>")    -- commit
vim.keymap.set("n", "<leader>gp", ":Git pull<CR>")      -- push
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

-- LSP
vim.keymap.set("n", "gi", builtin.lsp_implementations, opts)
vim.keymap.set("n", "gr", builtin.lsp_references, opts)
vim.keymap.set("n", "<leader>ds", builtin.lsp_document_symbols, opts)
vim.keymap.set("n", "<leader>ws", builtin.lsp_workspace_symbols, opts)
vim.keymap.set("n", "<leader>qf", function() vim.diagnostic.setqflist() vim.cmd("copen") end, { desc = "Quickfix: show LSP errors" })

-- Others
vim.keymap.set("n", "<leader>km", builtin.keymaps, opts)
vim.keymap.set("n", "<leader>cm", builtin.commands, opts)
vim.keymap.set("n", "<leader>/", builtin.current_buffer_fuzzy_find, opts)

-- map cn and cm to copy the file name
-- vim.keymap.set("n", "<leader>cn", ":let @+ = expand('%:p')<CR>")
vim.keymap.set("n", "<leader>cn", function()
  vim.fn.setreg('+', vim.fn.expand('%:p'))
end)

-- which-key usage
--local wk = require("which-key")
--wk.register({
--   p = { "<cmd>PasteImage<cr>", "Paste image from clipboard" },
--}, { prefix = "<leader>" })

-- Open a terminal and run a command
local Terminal  = require('toggleterm.terminal').Terminal
local htop = Terminal:new({ cmd = "htop", hidden = true })
function _HTOP_TOGGLE()
  htop:toggle()
end
-- Map key to toggle htop
-- vim.api.nvim_set_keymap("n", "<leader>th", "<cmd>lua _HTOP_TOGGLE()<CR>", {noremap = true, silent = true})

-- statuscol
require("statuscol").setup({
  segments = {
    { text = { "%s" }, click = "v:lua.ScSa" }, -- signs
    { text = { "%l" }, click = "v:lua.ScLa" }, -- line numbers
  },
})

--local cmp = require("cmp")
--local tabout = require("tabout")
--
--cmp.setup({
--  mapping = {
--    ["<Tab>"] = cmp.mapping(function(fallback)
--      if tabout.jumpable() then
--        tabout.jump_forward()
--      elseif cmp.visible() then
--        cmp.select_next_item()
--      else
--        fallback()
--      end
--    end, { "i", "s" }),
--    
--    ["<S-Tab>"] = cmp.mapping(function(fallback)
--      if tabout.jumpable(true) then
--        tabout.jump_backward()
--      else
--        fallback()
--      end
--    end, { "i", "s" }),
--  },
--})
--
-- For color picker
-- vim.api.nvim_set_keymap("n", "<leader>cp", "<cmd>CccPick<CR>", { noremap = true, silent = true })
-- vim.api.nvim_set_keymap("n", "<leader>cc", "<cmd>CccConvert<CR>", { noremap = true, silent = true })

-- For colorizer
-- vim.api.nvim_set_keymap("n", "<leader>cc", ":ColorizerToggle<CR>", { noremap = true, silent = true })
-- vim.api.nvim_set_keymap("n", "<leader>ca", ":ColorizerAttachToBuffer<CR>", { noremap = true, silent = true })

-- Set shortcut to switch last file
vim.keymap.set("n", "<C-f>", "<cmd>b#<CR>")

-- Scroll through popup messages
-- vim.keymap.set("n", "<C-f>", function()
--   if require("noice.lsp").scroll(4) then return end
--   return "<C-f>"
-- end, { expr = true, silent = true })
--
-- vim.keymap.set("n", "<C-b>", function()
--   if require("noice.lsp").scroll(-4) then return end
--   return "<C-b>"
-- end, { expr = true, silent = true })

-- For nvim-dap
local dap = require("dap")
vim.keymap.set("n", "<F5>", dap.continue)
vim.keymap.set("n", "<F10>", dap.step_over)
vim.keymap.set("n", "<F11>", dap.step_into)
vim.keymap.set("n", "<F12>", dap.step_out)
vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint)
vim.keymap.set("n", "<leader>B", function() dap.set_breakpoint(vim.fn.input("Breakpoint condition: ")) end)
vim.keymap.set("n", "<leader>dr", dap.repl.open)
vim.keymap.set("n", "<leader>dl", dap.run_last)

-- For diff with a specific commit
vim.keymap.set("n", "<leader>gD", function()
  -------------------------------------------------------
  -- 1. Validate buffer
  -------------------------------------------------------
  local file = vim.fn.expand("%:p")
  if file == "" or vim.fn.getftype(file) ~= "file" then
    vim.notify("Not a valid file", vim.log.levels.ERROR)
    return
  end

  -------------------------------------------------------
  -- 2. Get repo root
  -------------------------------------------------------
  local dirname = vim.fn.expand("%:h")
  local repo_path = vim.fn.systemlist(
    "git -C " .. vim.fn.shellescape(dirname) .. " rev-parse --show-toplevel"
  )[1]

  if repo_path == nil or repo_path == "" then
    vim.notify("Not inside a Git repository", vim.log.levels.ERROR)
    return
  end

  -------------------------------------------------------
  -- 3. Get repo-relative path (correct way)
  -------------------------------------------------------
  local rel_file = vim.fn.systemlist(
    "git -C " .. vim.fn.shellescape(repo_path)
    .. " ls-files --full-name "
    .. vim.fn.shellescape(file)
  )[1]

  if rel_file == nil or rel_file == "" then
    vim.notify("File is not tracked by Git", vim.log.levels.ERROR)
    return
  end

  -------------------------------------------------------
  -- 4. Show Git Log for this file
  -------------------------------------------------------
  Snacks.picker.git_log_file({
    confirm = function(picker, item)
      picker:close()
      local hash = item.oid or item.commit
      if not hash then
        vim.notify("No valid commit", vim.log.levels.ERROR)
        return
      end

      ---------------------------------------------------
      -- 5. Use Gvdiffsplit to show diff
      ---------------------------------------------------
      vim.schedule(function()
        local target = hash .. ":" .. rel_file
        vim.cmd("Gvdiffsplit " .. vim.fn.fnameescape(target))
      end)
    end,
  })
end, { desc = "Git log → Diff commit for current file" })


-- View a flattened DTS from a DTB file
local function view_dtb()
  local file = vim.fn.expand("%:p")
  if file == "" then
    print("No file under cursor")
    return
  end

  if not file:match("%.dtb$") then
    print("Not a DTB file")
    return
  end

  -- Temporary output file
  local tmp = vim.fn.tempname() .. ".dts"

  -- Decompile dtb
  local cmd = string.format("dtc -I dtb -O dts -s '%s' -o '%s'", file, tmp)
  local result = os.execute(cmd)
  if result ~= 0 then
    print("Failed to decompile DTB")
    return
  end

  -- Replace current buffer with tmp file
  vim.cmd("edit " .. tmp)

  -- When the buffer is unloaded (closed), remove the tmp file
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = 0,
    once = true,
    callback = function()
      os.remove(tmp)
    end,
  })
end
vim.keymap.set("n", "<leader>dt", view_dtb, { desc = "Decompile DTB to DTS" })

-- Align N lines by a given pattern
local function align_by(pattern)
  local count = vim.v.count
  if count == 0 then count = 10 end  -- default 10 lines

  local start_line = vim.fn.line(".")
  local end_line = start_line + count - 1
  local last_line = vim.fn.line("$")
  if end_line > last_line then end_line = last_line end

  vim.api.nvim_command(string.format("%d,%dTabularize /%s/", start_line, end_line, pattern))
end

-- Align // comments
vim.keymap.set("n", "<leader>ac", function() align_by("//") end,
  { desc = "Align N lines of // comments" })

-- Align by = 
vim.keymap.set("n", "<leader>ae", function() align_by("=") end,
  { desc = "Align N lines by =" })

-- Align by { 
vim.keymap.set("n", "<leader>a{", function() align_by("{") end,
  { desc = "Align N lines by {" })


-- For D2 compilation
vim.api.nvim_create_user_command("D2", function()
  local file = vim.fn.expand("%:p")
  local out  = vim.fn.expand("%:p:r") .. ".png"
  vim.fn.system({ "d2", file, out })
  vim.fn.system({ "open", out })
end, {})
vim.keymap.set("n", "<leader>dg", ":D2<CR>", { noremap = true, silent = true, desc = "Run D2 compile" })
