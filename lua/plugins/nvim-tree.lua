return {
  -- File Explorer with Git integration
  {
    "kyazdani42/nvim-tree.lua",
    config = function()
      local nvim_tree_api = require("nvim-tree.api")
      -- gd: git log (file/dir) for node under cursor — mirrors <leader>gD for files
      local function git_log_node()
        local api = require("nvim-tree.api")
        local node = api.tree.get_node_under_cursor()
        local path = node and node.absolute_path
        if not path then
          return
        end

        local git_util = require("utils.git")
        -- Follow soft links so a linked file/dir uses the target's git repo.
        local real = git_util.realpath(path) or path
        local is_dir = node.type == "directory" or vim.fn.isdirectory(real) == 1
        local base = is_dir and real or vim.fn.fnamemodify(real, ":h")

        -- Walk up from this node, then search down for a nested .git
        -- (cwd may not be a repo; a child folder might be).
        local repo = git_util.nearest({ start = real })
        if not repo then
          return
        end
        local root = repo.root
        -- fugitive_dir, not repo.gitdir: an external git dir (--separate-git-dir)
        -- has no core.worktree, so a URL built from it makes fugitive bail.
        local gitdir = git_util.fugitive_dir(repo)

        -- Let git report the repo-relative location: --show-toplevel is
        -- symlink-resolved, so comparing it against the tree path fails
        -- whenever any component is a symlink. Empty when `base` is a
        -- parent of the repo (we just found a nested .git below it).
        local prefix_out = vim.fn.systemlist({
          "git", "-C", base, "rev-parse", "--show-prefix",
        })
        local prefix = (vim.v.shell_error == 0 and prefix_out[1]) or ""

        local rel
        if is_dir then
          rel = prefix ~= "" and (prefix:gsub("/$", "")) or "."
        else
          rel = git_util.relpath(repo, real)
          if not rel or rel == "" then
            vim.notify("File is not tracked by Git", vim.log.levels.ERROR)
            return
          end
        end

        -- Historical names so the log lists — and the preview diffs — this file
        -- across renames, without `--follow` (see utils.git.history_pathspec).
        -- Dirs have no single name to follow.
        local pathspec = is_dir and { rel } or git_util.history_pathspec(repo, rel)
        local cmd_args = vim.list_extend({ "--" }, pathspec)

        Snacks.picker.git_log({
          cwd = root,
          cmd_args = cmd_args,
          -- Preview scopes to this file/dir (not the whole commit), like <leader>gD
          pathspec = pathspec,
          title = "Git Log: " .. (rel == "." and vim.fn.fnamemodify(root, ":t") or rel),
          confirm = function(picker, item)
            picker:close()
            local hash = item.oid or item.commit
            if not hash then
              return
            end
            vim.schedule(function()
              -- New tab keeps the original tab (and nvim-tree) untouched.
              -- FugitiveFind pins the object to this repo; :Gtabedit would
              -- resolve against whatever repo the current buffer belongs to.
              local object = is_dir and hash or (hash .. ":" .. rel)
              vim.cmd("tabedit " .. vim.fn.fnameescape(vim.fn.FugitiveFind(object, gitdir)))
              if not is_dir then
                -- file@commit vs parent(s) — same as picker `git show`
                -- (Gvdiffsplit <hash> would diff worktree vs commit instead)
                vim.cmd("Gvdiffsplit!")
              end
            end)
          end,
          -- Ctrl-Enter: open the whole commit (not just this file's diff)
          actions = {
            open_commit = function(picker, item)
              picker:close()
              local hash = item and (item.oid or item.commit)
              if not hash then
                return
              end
              vim.schedule(function()
                vim.cmd("tabedit " .. vim.fn.fnameescape(vim.fn.FugitiveFind(hash, gitdir)))
              end)
            end,
          },
          win = {
            input = {
              keys = {
                ["<C-CR>"] = { "open_commit", mode = { "n", "i" } },
              },
            },
            list = {
              keys = {
                ["<C-CR>"] = "open_commit",
              },
            },
          },
        })
      end

      -- Directory of the node under cursor (folder itself, or the file's parent).
      local function node_dir()
        local api = require("nvim-tree.api")
        local node = api.tree.get_node_under_cursor()
        local path = node and node.absolute_path
        if not path or path == "" then
          return nil
        end
        local is_dir = node.type == "directory" or vim.fn.isdirectory(path) == 1
        return is_dir and path or vim.fn.fnamemodify(path, ":h")
      end

      -- go: git status for dir under cursor — mirrors <leader>go
      local function git_status_node()
        local path = node_dir()
        if not path then
          return
        end

        local git_util = require("utils.git")
        local real = git_util.realpath(path) or path
        local repo = git_util.nearest({ start = real })
        if not repo then
          return
        end

        -- Same prefix trick as gd: --show-toplevel is symlink-resolved, so
        -- comparing it against the tree path fails when any component is a link.
        local prefix_out = vim.fn.systemlist({
          "git", "-C", real, "rev-parse", "--show-prefix",
        })
        local prefix = (vim.v.shell_error == 0 and prefix_out[1]) or ""
        local rel = prefix ~= "" and prefix:gsub("/$", "") or "."

        -- Telescope git_status always pathspecs `.` from the repo root, so
        -- filter entries to this dir. Porcelain paths are repo-relative.
        local make_entry = require("telescope.make_entry")
        local base_maker = make_entry.gen_from_git_status({ cwd = repo.root })
        local function entry_maker(entry)
          local result = base_maker(entry)
          if not result or rel == "." then
            return result
          end
          local file = result.value
          if file ~= rel and not vim.startswith(file, rel .. "/") then
            return nil
          end
          return result
        end

        local check = vim.fn.systemlist({
          "git", "-c", "core.quotepath=false", "-C", repo.root,
          "status", "--porcelain", "--", rel,
        })
        if vim.v.shell_error ~= 0 or #check == 0 then
          vim.notify("No changes found", vim.log.levels.WARN)
          return
        end

        require("telescope.builtin").git_status({
          cwd = repo.root,
          prompt_title = "Git Status: " .. (rel == "." and vim.fn.fnamemodify(repo.root, ":t") or rel),
          entry_maker = entry_maker,
        })
      end

      -- sd: directory picker scoped to the node under cursor
      local function find_dir_node()
        local cwd = node_dir()
        if not cwd then
          return
        end
        require("utils.directory_picker").open(cwd)
      end

      -- ff: file picker scoped to the node under cursor
      local function find_files_node()
        local cwd = node_dir()
        if not cwd then
          return
        end
        require("fzf-lua").files({
          cwd = cwd,
          prompt = "Files (" .. vim.fn.fnamemodify(cwd, ":t") .. ")> ",
          winopts = {
            width = 0.95,
            height = 0.95,
            layout = "horizontal",
            preview = { layout = "vertical", vertical = "right:55%", scrollbar = "float" },
          },
        })
      end

      -- fF: same picker, pre-filled from the unnamed register
      local function find_files_node_from_yank()
        local yank = vim.fn.getreg('"')
        if yank == "" then
          vim.notify("Clipboard is empty", vim.log.levels.INFO)
          return
        end
        yank = yank:gsub("[\r\n]+$", "")
        yank = yank:gsub("^%s*(.-)%s*$", "%1")

        local cwd = node_dir()
        if not cwd then
          return
        end
        require("fzf-lua").files({
          cwd = cwd,
          prompt = "Files (" .. vim.fn.fnamemodify(cwd, ":t") .. ")> ",
          no_ignore = false,
          fzf_opts = {
            ["--query"] = yank,
            ["--ansi"] = "",
            ["--layout"] = "reverse",
            ["--info"] = "default",
          },
          winopts = {
            width = 0.9,
            height = 0.9,
            layout = "horizontal",
            preview = {
              layout = "vertical",
              vertical = "right:55%",
              scrollbar = "float",
            },
          },
        })
      end

      -- ss / sS / sg: grep scoped to the node under cursor (mirrors <leader>ss / sS / sg)
      local grep_winopts = {
        width = 0.95,
        height = 0.95,
        layout = "horizontal",
        preview = { layout = "vertical", vertical = "right:55%" },
      }

      local function grep_in_node(search, extra)
        local cwd = node_dir()
        if not cwd then
          return
        end
        local opts = {
          cwd = cwd,
          search = search,
          prompt = "Search (" .. vim.fn.fnamemodify(cwd, ":t") .. ")> ",
          fzf_opts = {
            ["--ansi"] = "",
            ["--layout"] = "reverse",
            ["--info"] = "default",
          },
          winopts = grep_winopts,
        }
        if extra then
          for k, v in pairs(extra) do
            opts[k] = v
          end
        end
        require("fzf-lua").grep(opts)
      end

      local function yank_for_grep(reg)
        local yank = vim.fn.getreg(reg)
        if yank == "" then
          vim.notify("No yanked text", vim.log.levels.INFO)
          return nil
        end
        yank = yank:gsub("[\r\n]+$", "")
        yank = yank:gsub([[\]], [[\\]]):gsub([["]], [[\"]])
        return yank
      end

      local function search_unnamed_node()
        local yank = yank_for_grep('"')
        if yank then
          grep_in_node(yank)
        end
      end

      local function search_clipboard_node()
        local yank = yank_for_grep("+")
        if yank then
          grep_in_node(yank)
        end
      end

      local function search_grep_node()
        local actions = require("fzf-lua").actions
        grep_in_node("", {
          actions = {
            ["ctrl-g"] = { actions.grep_lgrep },
            ["ctrl-r"] = { actions.toggle_ignore },
          },
        })
      end

      -- Also bind via FileType so <leader>ge (re-setup without on_attach) still gets these
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "NvimTree",
        callback = function(args)
          local function tree_map(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, {
              buffer = args.buf,
              desc = "nvim-tree: " .. desc,
              noremap = true,
              silent = true,
              nowait = true,
            })
          end
          tree_map("gd", git_log_node, "Git Log: File/Dir")
          tree_map("go", git_status_node, "Git Status: Dir")
          tree_map("sd", find_dir_node, "Find Directory")
          tree_map("ss", search_unnamed_node, "Search yank")
          tree_map("sS", search_clipboard_node, "Search clipboard")
          tree_map("sg", search_grep_node, "Search")
          tree_map("ff", find_files_node, "Find Files")
          tree_map("fF", find_files_node_from_yank, "Find Files (yank)")
        end,
      })

      require("nvim-tree").setup {
        disable_netrw = true,
        hijack_netrw = true,
        open_on_tab = false,

        -- Keymaps
        on_attach = function(bufnr)
          local api = nvim_tree_api
          local function opts(desc)
            return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
          end

          vim.keymap.set('n', '<C-e>', '<C-e>', opts('Scroll down'))
          vim.keymap.set('n', '<C-]>', api.tree.change_root_to_node, opts('CD'))
          vim.keymap.set('n', '<C-k>', api.node.show_info_popup, opts('Info'))
          vim.keymap.set('n', '<C-r>', api.fs.rename_sub, opts('Rename: Omit Filename'))
          vim.keymap.set('n', '<C-t>', api.node.open.tab, opts('Open: New Tab'))
          vim.keymap.set('n', '<C-v>', api.node.open.vertical, opts('Open: Vertical Split'))
          vim.keymap.set('n', '<C-x>', api.node.open.horizontal, opts('Open: Horizontal Split'))
          vim.keymap.set('n', '<BS>', api.node.navigate.parent_close, opts('Close Directory'))
          vim.keymap.set('n', '<CR>', api.node.open.edit, opts('Open'))
          vim.keymap.set('n', '<Tab>', api.node.open.preview, opts('Open Preview'))
          vim.keymap.set('n', '>', api.node.navigate.sibling.next, opts('Next Sibling'))
          vim.keymap.set('n', '<', api.node.navigate.sibling.prev, opts('Previous Sibling'))
          vim.keymap.set('n', '.', api.node.run.cmd, opts('Run Command'))
          vim.keymap.set('n', '-', api.tree.change_root_to_parent, opts('Up'))
          vim.keymap.set('n', 'E', api.tree.expand_all, opts('Expand All'))
          vim.keymap.set('n', 'c', api.fs.copy.node, opts('Copy'))
          vim.keymap.set('n', 'C', api.tree.collapse_all, opts('Collapse All'))
          vim.keymap.set('n', 'a', api.fs.create, opts('Create'))
          vim.keymap.set('n', 'd', api.fs.remove, opts('Delete'))
          vim.keymap.set('n', 'x', api.fs.cut, opts('Cut'))
          vim.keymap.set('n', 'p', api.fs.paste, opts('Paste'))
          vim.keymap.set('n', 'D', api.fs.trash, opts('Trash'))
          vim.keymap.set('n', 'r', api.fs.rename, opts('Rename'))
          vim.keymap.set('n', 'R', api.tree.reload, opts('Refresh'))
          vim.keymap.set('n', 'y', api.fs.copy.filename, opts('Copy Name'))
          vim.keymap.set('n', 'Y', api.fs.copy.relative_path, opts('Copy Relative Path'))
          vim.keymap.set('n', 'gy', api.fs.copy.absolute_path, opts('Copy Abosulute Path'))
          vim.keymap.set('n', 'gd', git_log_node, opts('Git Log: File/Dir'))
          vim.keymap.set('n', 'go', git_status_node, opts('Git Status: Dir'))
          vim.keymap.set('n', 'sd', find_dir_node, opts('Find Directory'))
          vim.keymap.set('n', 'ss', search_unnamed_node, opts('Search yank'))
          vim.keymap.set('n', 'sS', search_clipboard_node, opts('Search clipboard'))
          vim.keymap.set('n', 'sg', search_grep_node, opts('Search'))
          vim.keymap.set('n', 'ff', find_files_node, opts('Find Files'))
          vim.keymap.set('n', 'fF', find_files_node_from_yank, opts('Find Files (yank)'))
          -- Copy the file using cb copy
        end,

        view = {
          width = 50,
          side = "left",
          preserve_window_proportions = true,
          float = { enable = false },
          number = true,
          relativenumber = true,
        },

        update_focused_file = {
          enable = true,
          update_root = true,
        },

        hijack_cursor = true,
        renderer = {
          indent_markers = { enable = true },
          highlight_opened_files = "icon",
          icons = {
            show = { file = true, folder = true, git = true },
            glyphs = {
              git = {
                unstaged  = "✗",
                staged    = "✓",
                unmerged  = "",
                renamed   = "➜",
                untracked = "★",
                deleted   = "",
                ignored   = "◌",
              },
            },
          },
          highlight_git = true,  -- <<< enable git highlight
        },

        git = {
          enable = true,      -- show git status icons
          ignore = false,     -- show ignored files
          timeout = 500,
        },
        modified = {
          enable = true,
          show_on_dirs = true,
          show_on_open_dirs = true,
        },
        sync_root_with_cwd = true,
        respect_buf_cwd = true,
      }

      -- Optional: auto-refresh after writing a file
      vim.cmd([[
        autocmd BufWritePost * lua require('nvim-tree.api').tree.reload()
      ]])
      -- ======================================
      -- Git-only toggle/open function
      -- ======================================
      local function toggle_tree_git_only()
        local api = require("nvim-tree.api")
        local tree_view = api.tree

        if tree_view.is_visible() then
          tree_view.close_in_this_tab()()
        else
          require("nvim-tree").setup({
            filters = {
              git_ignored = true,
              git_clean   = true,
            },
            git = {
              enable  = true,      -- must be true for git filters to work
              timeout = 4000,      -- git timeout in milliseconds
            },
            renderer = {
              group_empty = true,
              root_folder_label = false,
              indent_width = 1,
              indent_markers = { enable = false },
              highlight_git = true,
            },
            update_focused_file = {
              enable = true,      -- highlight the current file in the tree
              update_root = true, -- optionally change the root to the file's directory
            },
            view = {
              width = 40,
              side = "left",
              preserve_window_proportions = true,
              float = { enable = false },
              number = true,
              relativenumber = true,
            },
            actions = {
              expand_all = { max_folder_discovery = 300 },
            },
            -- on_attach = function(bufnr)
            --   vim.defer_fn(function()
            --     api.tree.expand_all()
            --   end, 10)
            -- end,
          })

          api.tree.open()
          api.tree.reload()
        end
      end

      -- Keymap for git-only toggle
      vim.keymap.set(
        "n",
        "<leader>ge",
        toggle_tree_git_only,
        { desc = "Toggle Nvim-tree (git changes only, list-like view)" }
      )

      local function open_normal_tree()
        local api = require("nvim-tree.api")
        local tree_view = api.tree
      
        if tree_view.is_visible() then
          tree_view.close_in_this_tab()
        else
        require("nvim-tree").setup {
          disable_netrw = true,
          hijack_netrw = true,
          open_on_tab = false,

          -- Keymaps
          on_attach = function(bufnr)
            local api = nvim_tree_api
            local function opts(desc)
              return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
            end

            vim.keymap.set('n', '<C-e>', '<C-e>', opts('Scroll down'))
            vim.keymap.set('n', '<C-]>', api.tree.change_root_to_node, opts('CD'))
            vim.keymap.set('n', '<C-k>', api.node.show_info_popup, opts('Info'))
            vim.keymap.set('n', '<C-r>', api.fs.rename_sub, opts('Rename: Omit Filename'))
            vim.keymap.set('n', '<C-t>', api.node.open.tab, opts('Open: New Tab'))
            vim.keymap.set('n', '<C-v>', api.node.open.vertical, opts('Open: Vertical Split'))
            vim.keymap.set('n', '<C-x>', api.node.open.horizontal, opts('Open: Horizontal Split'))
            vim.keymap.set('n', '<BS>', api.node.navigate.parent_close, opts('Close Directory'))
            vim.keymap.set('n', '<CR>', api.node.open.edit, opts('Open'))
            vim.keymap.set('n', '<Tab>', api.node.open.preview, opts('Open Preview'))
            vim.keymap.set('n', '>', api.node.navigate.sibling.next, opts('Next Sibling'))
            vim.keymap.set('n', '<', api.node.navigate.sibling.prev, opts('Previous Sibling'))
            vim.keymap.set('n', '.', api.node.run.cmd, opts('Run Command'))
            vim.keymap.set('n', '-', api.tree.change_root_to_parent, opts('Up'))
            vim.keymap.set('n', 'E', api.tree.expand_all, opts('Expand All'))
            vim.keymap.set('n', 'C', api.tree.collapse_all, opts('Collapse All'))
            vim.keymap.set('n', 'a', api.fs.create, opts('Create'))
            vim.keymap.set('n', 'd', api.fs.remove, opts('Delete'))
            vim.keymap.set('n', 'x', api.fs.cut, opts('Cut'))
            vim.keymap.set('n', 'c', api.fs.copy.node, opts('Copy'))
            vim.keymap.set('n', 'p', api.fs.paste, opts('Paste'))
            vim.keymap.set('n', 'D', api.fs.trash, opts('Trash'))
            vim.keymap.set('n', 'r', api.fs.rename, opts('Rename'))
            vim.keymap.set('n', 'R', api.tree.reload, opts('Refresh'))
            vim.keymap.set('n', 'y', api.fs.copy.filename, opts('Copy Name'))
            vim.keymap.set('n', 'Y', api.fs.copy.relative_path, opts('Copy Relative Path'))
            vim.keymap.set('n', 'gy', api.fs.copy.absolute_path, opts('Copy Abosulute Path'))
            vim.keymap.set('n', 'gd', git_log_node, opts('Git Log: File/Dir'))
            vim.keymap.set('n', 'go', git_status_node, opts('Git Status: Dir'))
            vim.keymap.set('n', 'sd', find_dir_node, opts('Find Directory'))
            vim.keymap.set('n', 'ss', search_unnamed_node, opts('Search yank'))
            vim.keymap.set('n', 'sS', search_clipboard_node, opts('Search clipboard'))
            vim.keymap.set('n', 'sg', search_grep_node, opts('Search'))
            vim.keymap.set('n', 'ff', find_files_node, opts('Find Files'))
            vim.keymap.set('n', 'fF', find_files_node_from_yank, opts('Find Files (yank)'))
            -- Copy the file using cb copy
          end,

          view = {
            width = 50,
            side = "left",
            preserve_window_proportions = true,
            float = { enable = false },
            number = true,
            relativenumber = true,
          },

          update_focused_file = {
            enable = true,
            update_root = true,
          },

          hijack_cursor = true,

          renderer = {
            indent_markers = { enable = true },
            highlight_opened_files = "icon",
            icons = {
              show = { file = true, folder = true, git = true },
              glyphs = {
                git = {
                  unstaged  = "✗",
                  staged    = "✓",
                  unmerged  = "",
                  renamed   = "➜",
                  untracked = "★",
                  deleted   = "",
                  ignored   = "◌",
                },
              },
            },
            highlight_git = true,  -- <<< enable git highlight
          },

          git = {
            enable = true,      -- show git status icons
            ignore = false,     -- show ignored files
            timeout = 500,
          },

          sync_root_with_cwd = true,
          respect_buf_cwd = true,
        }
      
        -- Open and reload the tree
        api.tree.open()
        api.tree.reload()
        end
      end
      
      -- Keymap for normal tree
      vim.keymap.set( "n", "<leader>e", open_normal_tree, { desc = "Toggle normal Nvim-tree" })
    end,
  },


  -- Change workspace and Nvim-Tree root
  vim.keymap.set("n", "<leader>cd", function()
    local cwd = vim.loop.cwd()
    if not cwd:match("/$") then cwd = cwd .. "/" end
    local input = vim.fn.input("Enter new workspace path: ", cwd, "dir")
    if input ~= "" and vim.fn.isdirectory(input) == 1 then
      vim.api.nvim_set_current_dir(input)
      local api = require("nvim-tree.api")
      api.tree.change_root(input)
      api.tree.reload()
      print("Workspace changed to: " .. input)
    else
      print("Invalid directory: " .. input)
    end
  end, { desc = "Change workspace directory" }),
}
