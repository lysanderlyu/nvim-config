return {
  -- File Explorer with Git integration
  {
    "kyazdani42/nvim-tree.lua",
    config = function()
      local nvim_tree_api = require("nvim-tree.api")
      -- gl: git log (file/dir) for node under cursor — mirrors <leader>gl / <leader>gD for files
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

      -- Directory of a tree node (folder itself, or the file's parent).
      local function dir_of_node(node)
        local path = node and node.absolute_path
        if not path or path == "" then
          return nil
        end
        local is_dir = node.type == "directory" or vim.fn.isdirectory(path) == 1
        return is_dir and path or vim.fn.fnamemodify(path, ":h")
      end

      -- Directory of the node under cursor (folder itself, or the file's parent).
      local function node_dir()
        local api = require("nvim-tree.api")
        return dir_of_node(api.tree.get_node_under_cursor())
      end

      -- Directory at hierarchy depth `level` from the tree/project root, along the
      -- path to the cursor node. level 1 = first folder under the project, 2 = next, …
      -- level 0 (plain ss) → current node.
      local function node_dir_at_hierarchy_level(level)
        level = level or 0
        if level == 0 then
          return node_dir()
        end

        local api = require("nvim-tree.api")
        local node = api.tree.get_node_under_cursor()
        if not node then
          return nil
        end

        -- Walk parents → [root, …, cursor]
        local chain = {}
        local n = node
        while n do
          table.insert(chain, 1, n)
          n = n.parent
        end

        -- chain[1] is the project/tree root; level 1 → chain[2], level 2 → chain[3], …
        local target = chain[level + 1]
        if not target then
          vim.notify(
            string.format("No directory at hierarchy level %d (path depth is %d)", level, math.max(#chain - 1, 0)),
            vim.log.levels.WARN
          )
          return nil
        end
        return dir_of_node(target)
      end

      -- Reverse of hierarchy level: N directories up from the current file/dir
      -- toward the project root. -1 = parent of current scope, -2 = grandparent, …
      -- (For a file, current scope is its parent — same baseline as plain ss.)
      local function node_dir_n_levels_up(n)
        n = n or 0
        if n == 0 then
          return node_dir()
        end

        local api = require("nvim-tree.api")
        local node = api.tree.get_node_under_cursor()
        if not node then
          return nil
        end

        local is_dir = node.type == "directory" or vim.fn.isdirectory(node.absolute_path) == 1
        local cur = is_dir and node or node.parent
        if not cur then
          return nil
        end

        for _ = 1, n do
          if not cur.parent then
            vim.notify(
              string.format("Cannot go %d level(s) up (reached project root)", n),
              vim.log.levels.WARN
            )
            return nil
          end
          cur = cur.parent
        end
        return dir_of_node(cur)
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
      -- [count]sd: same, but at hierarchy depth `count` from the project root
      local function find_dir_node(cwd)
        cwd = cwd or node_dir_at_hierarchy_level(vim.v.count)
        if not cwd then
          return
        end
        require("utils.directory_picker").open(cwd)
      end

      -- ff: file picker scoped to the node under cursor
      -- [count]ff: same, but at hierarchy depth `count` from the project root
      local function find_files_node(cwd)
        cwd = cwd or node_dir_at_hierarchy_level(vim.v.count)
        if not cwd then
          return
        end
        -- <C-c>: copy the realpath, <C-S-c>: the relative path
        require("fzf-lua").files(require("utils.clipboard").picker_opts({
          cwd = cwd,
          prompt = "Files (" .. vim.fn.fnamemodify(cwd, ":t") .. ")> ",
          winopts = {
            width = 0.95,
            height = 0.95,
            layout = "horizontal",
            preview = { layout = "vertical", vertical = "right:55%", scrollbar = "float" },
          },
        }))
      end

      -- fF: same picker, pre-filled from the unnamed register
      local function find_files_node_from_yank(cwd)
        local yank = vim.fn.getreg('"')
        if yank == "" then
          vim.notify("Clipboard is empty", vim.log.levels.INFO)
          return
        end
        yank = yank:gsub("[\r\n]+$", "")
        yank = yank:gsub("^%s*(.-)%s*$", "%1")

        cwd = cwd or node_dir_at_hierarchy_level(vim.v.count)
        if not cwd then
          return
        end
        -- <C-c>: copy the realpath, <C-S-c>: the relative path
        require("fzf-lua").files(require("utils.clipboard").picker_opts({
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
        }))
      end

      -- ss / sS / sg: grep scoped to the node under cursor (mirrors <leader>ss / sS / sg)
      local grep_winopts = {
        width = 0.95,
        height = 0.95,
        layout = "horizontal",
        preview = { layout = "vertical", vertical = "right:55%" },
      }

      local function grep_in_node(search, extra, cwd)
        cwd = cwd or node_dir()
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

      -- [count]ss: search yank under the directory at hierarchy depth `count`
      -- from the project/tree root (along the path to the cursor).
      -- Plain ss still searches the node under the cursor.
      local function search_unnamed_node()
        local yank = yank_for_grep('"')
        if yank then
          grep_in_node(yank, nil, node_dir_at_hierarchy_level(vim.v.count))
        end
      end

      local function search_clipboard_node()
        local yank = yank_for_grep("+")
        if yank then
          grep_in_node(yank, nil, node_dir_at_hierarchy_level(vim.v.count))
        end
      end

      local function search_grep_node()
        local actions = require("fzf-lua").actions
        grep_in_node("", {
          actions = {
            ["ctrl-g"] = { actions.grep_lgrep },
            ["ctrl-r"] = { actions.toggle_ignore },
          },
        }, node_dir_at_hierarchy_level(vim.v.count))
      end

      -- -[1-9]{ss,sS,sg,sd,ff,fF}: N levels up from current file/dir toward project root.
      -- Literal sequences (vim has no negative count). Requires `-` without nowait.
      local function bind_hierarchy_up_maps(map_fn)
        for i = 1, 9 do
          local level = i
          map_fn("-" .. i .. "ss", function()
            local yank = yank_for_grep('"')
            if yank then
              grep_in_node(yank, nil, node_dir_n_levels_up(level))
            end
          end, string.format("Search yank (%d levels up)", i))
          map_fn("-" .. i .. "sS", function()
            local yank = yank_for_grep("+")
            if yank then
              grep_in_node(yank, nil, node_dir_n_levels_up(level))
            end
          end, string.format("Search clipboard (%d levels up)", i))
          map_fn("-" .. i .. "sg", function()
            local actions = require("fzf-lua").actions
            grep_in_node("", {
              actions = {
                ["ctrl-g"] = { actions.grep_lgrep },
                ["ctrl-r"] = { actions.toggle_ignore },
              },
            }, node_dir_n_levels_up(level))
          end, string.format("Search (%d levels up)", i))
          map_fn("-" .. i .. "sd", function()
            find_dir_node(node_dir_n_levels_up(level))
          end, string.format("Find Directory (%d levels up)", i))
          map_fn("-" .. i .. "ff", function()
            find_files_node(node_dir_n_levels_up(level))
          end, string.format("Find Files (%d levels up)", i))
          map_fn("-" .. i .. "fF", function()
            find_files_node_from_yank(node_dir_n_levels_up(level))
          end, string.format("Find Files yank (%d levels up)", i))
        end
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
          tree_map("gl", git_log_node, "Git Log: File/Dir")
          tree_map("go", git_status_node, "Git Status: Dir")
          tree_map("sd", find_dir_node, "Find Directory ([count]sd = hierarchy level)")
          tree_map("ss", search_unnamed_node, "Search yank ([count]ss = hierarchy level)")
          tree_map("sS", search_clipboard_node, "Search clipboard ([count]sS)")
          tree_map("sg", search_grep_node, "Search ([count]sg)")
          tree_map("ff", find_files_node, "Find Files ([count]ff = hierarchy level)")
          tree_map("fF", find_files_node_from_yank, "Find Files (yank) ([count]fF)")
          bind_hierarchy_up_maps(tree_map)
          -- Allow -[1-9]… sequences: plain `-` must wait (no nowait)
          vim.keymap.set("n", "-", require("nvim-tree.api").tree.change_root_to_parent, {
            buffer = args.buf,
            desc = "nvim-tree: Up",
            noremap = true,
            silent = true,
            nowait = false,
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
          -- no nowait: must wait so -[1-9]ss / -[1-9]ff / … can complete
          vim.keymap.set('n', '-', api.tree.change_root_to_parent, {
            desc = 'nvim-tree: Up', buffer = bufnr, noremap = true, silent = true, nowait = false,
          })
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
          vim.keymap.set('n', 'gl', git_log_node, opts('Git Log: File/Dir'))
          vim.keymap.set('n', 'go', git_status_node, opts('Git Status: Dir'))
          vim.keymap.set('n', 'sd', find_dir_node, opts('Find Directory ([count]sd = hierarchy level)'))
          vim.keymap.set('n', 'ss', search_unnamed_node, opts('Search yank ([count]ss = hierarchy level)'))
          vim.keymap.set('n', 'sS', search_clipboard_node, opts('Search clipboard ([count]sS)'))
          vim.keymap.set('n', 'sg', search_grep_node, opts('Search ([count]sg)'))
          vim.keymap.set('n', 'ff', find_files_node, opts('Find Files ([count]ff = hierarchy level)'))
          vim.keymap.set('n', 'fF', find_files_node_from_yank, opts('Find Files (yank) ([count]fF)'))
          bind_hierarchy_up_maps(function(lhs, rhs, desc)
            vim.keymap.set('n', lhs, rhs, opts(desc))
          end)
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
            -- no nowait: must wait so -[1-9]ss / -[1-9]ff / … can complete
            vim.keymap.set('n', '-', api.tree.change_root_to_parent, {
              desc = 'nvim-tree: Up', buffer = bufnr, noremap = true, silent = true, nowait = false,
            })
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
            vim.keymap.set('n', 'gl', git_log_node, opts('Git Log: File/Dir'))
            vim.keymap.set('n', 'go', git_status_node, opts('Git Status: Dir'))
            vim.keymap.set('n', 'sd', find_dir_node, opts('Find Directory ([count]sd = hierarchy level)'))
            vim.keymap.set('n', 'ss', search_unnamed_node, opts('Search yank ([count]ss = hierarchy level)'))
            vim.keymap.set('n', 'sS', search_clipboard_node, opts('Search clipboard ([count]sS)'))
            vim.keymap.set('n', 'sg', search_grep_node, opts('Search ([count]sg)'))
            vim.keymap.set('n', 'ff', find_files_node, opts('Find Files ([count]ff = hierarchy level)'))
            vim.keymap.set('n', 'fF', find_files_node_from_yank, opts('Find Files (yank) ([count]fF)'))
            bind_hierarchy_up_maps(function(lhs, rhs, desc)
              vim.keymap.set('n', lhs, rhs, opts(desc))
            end)
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
