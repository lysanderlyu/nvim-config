return {
  {
    "tpope/vim-fugitive",
    lazy = false,  -- load immediately

    config = function()
        -- Swap <CR> and O: Enter opens in a new tab, O edits in-place
        vim.g.nremap = {
          ["<CR>"] = "O",
          ["O"] = "<CR>",
        }

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

        -- Ctrl-Enter: open the commit that last changed the current line (extends :Git blame <CR>)
        -- Never attach on fugitive buffers — keep original fugitive <CR>/O shortcuts.
        local fugitive_fts = {
          fugitive = true,
          fugitiveblame = true,
          git = true,
          gitcommit = true,
          gitrebase = true,
        }

        local function is_fugitive_buf(bufnr)
          bufnr = bufnr or 0
          if not vim.api.nvim_buf_is_valid(bufnr) then
            return true
          end
          local name = vim.api.nvim_buf_get_name(bufnr)
          if name:match("^fugitive://") or name:match("^%a+://") then
            return true
          end
          if fugitive_fts[vim.bo[bufnr].filetype] then
            return true
          end
          if vim.b[bufnr].fugitive_type ~= nil then
            return true
          end
          return false
        end

        local function open_line_commit()
          -- Fugitive views must keep native maps; this map should not be active there.
          if is_fugitive_buf(0) then
            return
          end
          local file = vim.api.nvim_buf_get_name(0)
          if file == "" or vim.fn.filereadable(file) ~= 1 then
            return
          end
          local lnum = vim.fn.line(".")
          local out = vim.fn.systemlist({
            "git", "-C", vim.fn.fnamemodify(file, ":h"),
            "blame", "-L", string.format("%d,%d", lnum, lnum),
            "--porcelain", "--", file,
          })
          if vim.v.shell_error ~= 0 or not out[1] then
            vim.notify("No blame info for this line", vim.log.levels.WARN)
            return
          end
          local hash = out[1]:match("^(%x+)")
          if not hash or hash:match("^0+$") then
            vim.notify("Line not committed yet", vim.log.levels.INFO)
            return
          end
          vim.cmd.Gtabedit(hash)
        end

        vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
          group = vim.api.nvim_create_augroup("FugitiveLineCommitCR", { clear = true }),
          callback = function(ev)
            -- Defer until fugitive finishes setting filetype / b:fugitive_type
            vim.schedule(function()
              if vim.bo[ev.buf].buftype ~= "" or is_fugitive_buf(ev.buf) then
                return
              end
              vim.keymap.set("n", "<C-CR>", open_line_commit, {
                buffer = ev.buf,
                silent = true,
                desc = "Open commit for current line",
              })
            end)
          end,
        })
        vim.keymap.set("n", "<leader>ga", ":Git add %<CR>")
        vim.keymap.set("n", "<leader>gA", ":Git add -A<CR>")
        vim.keymap.set("n", "<leader>gco", ":Git checkout %<CR>")
        vim.keymap.set("n", "<leader>gd", ":Gvdiffsplit<CR>")
        vim.keymap.set("n", "<leader>gr", ":Git reset --mixed -- %<CR>")
        vim.keymap.set("n", "<leader>gra", ":Git reset --mixed<CR>")
        vim.keymap.set("n", "<leader>grs", ":Git reset --soft HEAD~1<CR>")
        vim.keymap.set("n", "<leader>grd", ":Git reset --hard HEAD~1<CR>")
        vim.keymap.set("n", "<leader>grb", ":Git rebase -i --fork-point<CR>")   -- Rebase the current branch from where it was born
    end,
  }
}
