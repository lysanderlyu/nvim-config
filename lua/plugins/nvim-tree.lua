return {
  -- File Explorer with Git integration
  {
    "kyazdani42/nvim-tree.lua",
    config = function()
      local nvim_tree_api = require("nvim-tree.api")
      -- gd: git log (file/dir) for node under cursor — mirrors <leader>gd
      local function git_log_node()
        local api = require("nvim-tree.api")
        local node = api.tree.get_node_under_cursor()
        local path = node and node.absolute_path
        if not path then
          return
        end

        local is_dir = node.type == "directory" or vim.fn.isdirectory(path) == 1
        local base = is_dir and path or vim.fn.fnamemodify(path, ":h")

        -- Let git report the repo-relative location: --show-toplevel is
        -- symlink-resolved, so comparing it against the tree path fails
        -- whenever any component is a symlink.
        local info = vim.fn.systemlist({
          "git", "-C", base, "rev-parse",
          "--show-toplevel", "--absolute-git-dir", "--show-prefix",
        })
        if vim.v.shell_error ~= 0 or #info < 2 then
          vim.notify("Not in git repo", vim.log.levels.ERROR)
          return
        end
        local root, gitdir, prefix = info[1], info[2], info[3] or ""

        local rel
        if is_dir then
          rel = prefix ~= "" and (prefix:gsub("/$", "")) or "."
        else
          rel = vim.fn.systemlist({
            "git", "-c", "core.quotepath=false", "-C", base,
            "ls-files", "--full-name", "--", vim.fn.fnamemodify(path, ":t"),
          })[1]
          if vim.v.shell_error ~= 0 or not rel or rel == "" then
            vim.notify("File is not tracked by Git", vim.log.levels.ERROR)
            return
          end
        end

        local cmd_args = { "--", rel }
        if not is_dir then
          table.insert(cmd_args, 1, "--follow")
        end

        Snacks.picker.git_log({
          cwd = root,
          cmd_args = cmd_args,
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

      -- Also bind via FileType so <leader>ge (re-setup without on_attach) still gets gd
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "NvimTree",
        callback = function(args)
          vim.keymap.set("n", "gd", git_log_node, {
            buffer = args.buf,
            desc = "nvim-tree: Git Log: File/Dir",
            noremap = true,
            silent = true,
            nowait = true,
          })
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
          -- vim.keymap.set('n', 'C', api.tree.collapse_all, opts('Collapse All'))
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
          -- Copy the file using cb copy
          vim.keymap.set(
            "n",
            "C",
            require("utils.clipboard").copy_fs_object_from_nvim_tree,
            { noremap = true, silent = true, desc = "Copy filesystem object" }
          )
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
      vim.keymap.set( "n", "<leader>ge", toggle_tree_git_only, { desc = "Toggle Nvim-tree (git changes only, list-like view)" })

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
            -- vim.keymap.set('n', 'C', api.tree.collapse_all, opts('Collapse All'))
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
            -- Copy the file using cb copy
            vim.keymap.set(
              "n",
              "C",
              require("utils.clipboard").copy_fs_object_from_nvim_tree,
              { noremap = true, silent = true, desc = "Copy filesystem object" }
            )
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
