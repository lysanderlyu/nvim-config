return {
  -- File Explorer with Git integration
  {
    "kyazdani42/nvim-tree.lua",
    config = function()
      local nvim_tree_api = require("nvim-tree.api")
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
          vim.keymap.set('n', 'p', api.fs.paste, opts('Paste'))
          vim.keymap.set('n', 'D', api.fs.trash, opts('Trash'))
          vim.keymap.set('n', 'r', api.fs.rename, opts('Rename'))
          vim.keymap.set('n', 'R', api.tree.reload, opts('Refresh'))
          vim.keymap.set('n', 'y', api.fs.copy.filename, opts('Copy Name'))
          vim.keymap.set('n', 'Y', api.fs.copy.relative_path, opts('Copy Relative Path'))
          vim.keymap.set('n', 'gy', api.fs.copy.absolute_path, opts('Copy Abosulute Path'))
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

      -- Optional: auto-refresh after writing a file
      vim.cmd([[
        autocmd BufWritePost * lua require('nvim-tree.api').tree.reload()
      ]])
      -- ======================================
      -- Git-only toggle/open function
      -- ======================================
      local function toggle_tree_git_only()
        local tree_view = require("nvim-tree.view")
        local api = require("nvim-tree.api")

        if tree_view.is_visible() then
          tree_view.close()
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
        local tree_view = require("nvim-tree.view")
        local api = require("nvim-tree.api")
      
        if tree_view.is_visible() then
          tree_view.close()
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
            vim.keymap.set('n', 'p', api.fs.paste, opts('Paste'))
            vim.keymap.set('n', 'D', api.fs.trash, opts('Trash'))
            vim.keymap.set('n', 'r', api.fs.rename, opts('Rename'))
            vim.keymap.set('n', 'R', api.tree.reload, opts('Refresh'))
            vim.keymap.set('n', 'y', api.fs.copy.filename, opts('Copy Name'))
            vim.keymap.set('n', 'Y', api.fs.copy.relative_path, opts('Copy Relative Path'))
            vim.keymap.set('n', 'gy', api.fs.copy.absolute_path, opts('Copy Abosulute Path'))
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
            enable = false,      -- show git status icons
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
