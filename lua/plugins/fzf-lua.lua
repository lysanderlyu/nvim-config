return {
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    ---@module "fzf-lua"
    ---@type fzf-lua.Config|{}
    ---@diagnostics disable: missing-fields
    opts = {
      keymap = {
        preview = {
          ["<C-d>"] = "preview-page-down",
          ["<C-u>"] = "preview-page-up",
        },
        builtin = {
          -- true,        -- uncomment to inherit all the below in your custom config
          ["<C-j>"]       = "preview-down",
          ["<C-k>"]       = "preview-up",
          ["<M-Esc>"]     = "hide",     -- hide fzf-lua, `:FzfLua resume` to continue
          ["<F1>"]        = "toggle-help",
          ["<F2>"]        = "toggle-fullscreen",
          -- Only valid with the 'builtin' previewer
          ["<F3>"]        = "toggle-preview-wrap",
          ["<F4>"]        = "toggle-preview",
          -- Rotate preview clockwise/counter-clockwise
          ["<F5>"]        = "toggle-preview-cw",
          -- Preview toggle behavior default/extend
          ["<F6>"]        = "toggle-preview-behavior",
          -- `ts-ctx` binds require `nvim-treesitter-context`
          ["<F7>"]        = "toggle-preview-ts-ctx",
          ["<F8>"]        = "preview-ts-ctx-dec",
          ["<F9>"]        = "preview-ts-ctx-inc",
          ["<S-Left>"]    = "preview-reset",
          ["<S-down>"]    = "preview-page-down",
          ["<S-up>"]      = "preview-page-up",
          ["<M-S-down>"]  = "preview-down",
          ["<M-S-up>"]    = "preview-up",
        },
        fzf = {
          true, -- inherit fzf-lua's default fzf binds
          ["ctrl-j"] = "preview-down",
          ["ctrl-k"] = "preview-up",
        },
      },
    },
    ---@diagnostics enable: missing-fields
    config = function(_, opts)
      local fzf = require("fzf-lua")
      local actions = fzf.actions
      fzf.setup(opts)

      --  Search clipboard (+ register)
      vim.keymap.set("n", "<leader>sS", function()
        local yank = vim.fn.getreg("+")
        if yank == "" then
          vim.notify("No yanked text", vim.log.levels.INFO)
          return
        end
        yank = yank:gsub("[\r\n]+$", "") -- trim newline
        -- optional: escape backslash and double quote
        yank = yank:gsub([[\]], [[\\]]):gsub([["]], [[\"]])

        -- <C-y>/<C-S-y>/<C-c>/<C-p>/<C-o>: same path/file actions as ff
        fzf.grep(require("utils.clipboard").picker_opts({
          -- search = '"' .. yank .. '"',
          search = yank,  -- just the raw string
          prompt = "Search> ",
          -- rg_opts = "--column --line-number --no-heading --smart-case",
          fzf_opts = {
              ["--ansi"] = "",
              ["--layout"] = "reverse",
              ["--info"] = "default",
          },
            
          winopts = {
            width = 0.95,
            height = 0.95,
            layout = "horizontal",
            preview = { layout = "vertical", vertical = "right:55%" },
          },
        }))
      end, { desc = "Search clipboard (+ register) with native preview" })

      --  Search unnamed register (" register)
      vim.keymap.set("n", "<leader>ss", function()
        local yank = vim.fn.getreg('"')
        if yank == "" then
          vim.notify("No yanked text", vim.log.levels.INFO)
          return
        end
        yank = yank:gsub("[\r\n]+$", "") -- trim newline
        -- optional: escape backslash and double quote
        yank = yank:gsub([[\]], [[\\]]):gsub([["]], [[\"]])

        -- <C-y>/<C-S-y>/<C-c>/<C-p>/<C-o>: same path/file actions as ff
        fzf.grep(require("utils.clipboard").picker_opts({
          -- search = '"' .. yank .. '"',
          search = yank,  -- just the raw string
          prompt = "Search> ",
          -- rg_opts = "--column --line-number --no-heading --smart-case",
          fzf_opts = {
              ["--ansi"] = "",
              ["--layout"] = "reverse",
              ["--info"] = "default",
          },
          winopts = {
            width = 0.95,
            height = 0.95,
            layout = "horizontal",
            preview = { layout = "vertical", vertical = "right:55%" },
          },
        }))
      end, { desc = "Search last yank (\" register) with native preview" })

      vim.keymap.set("n", "<leader>sg", function()
        -- <C-y>/<C-S-y>/<C-c>/<C-p>/<C-o>: same path/file actions as ff
        fzf.grep(require("utils.clipboard").picker_opts({
          search = "",  -- just the raw string
          prompt = "Search> ",
          fzf_opts = {
              ["--ansi"] = "",
              ["--layout"] = "reverse",
              ["--info"] = "default",
          },
          winopts = {
            width = 0.95,
            height = 0.95,
            layout = "horizontal",
            preview = { layout = "vertical", vertical = "right:55%" },
          },
          actions = {
            ["ctrl-g"]      = { actions.grep_lgrep },
            ["ctrl-r"]   = { actions.toggle_ignore }
          },
        }))
      end, { desc = "Search native preview" })

      -- Map <leader>ff to find files
      vim.keymap.set("n", "<leader>ff", function()
        -- <C-y>/<C-S-y>: path text; <C-c>/<C-p>: copy/paste FS object; <C-o>: system open
        fzf.files(require("utils.clipboard").picker_opts({
          prompt = "Files> ",
          winopts = {
            width = 0.95,
            height = 0.95,
            layout = "horizontal",
            preview = { layout = "vertical", vertical = "right:55%", scrollbar = "float" },
          },
        }))
      end, { desc = "Find files with fzf-lua" })

      vim.keymap.set("n", "<leader>fr", function()
        require("fzf-lua").oldfiles({
          prompt = "Recent Files> ",
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
      end, { desc = "Find recent files" })

      vim.keymap.set("n", "<leader>fF", function()
        local yank = vim.fn.getreg('"')  -- get clipboard
        if yank == "" then
          vim.notify("Clipboard is empty", vim.log.levels.INFO)
          return
        end
      
        yank = yank:gsub("[\r\n]+$", "")  -- trim newlines
        yank = yank:gsub("^%s*(.-)%s*$", "%1")  -- trim spaces
      
        -- <C-y>/<C-S-y>: path text; <C-c>/<C-p>: copy/paste FS object; <C-o>: system open
        require("fzf-lua").files(require("utils.clipboard").picker_opts({
          prompt = "Files> ",
          no_ignore = false,         -- respect ".gitignore"  by default
          fzf_opts = {
            ["--query"] = yank,  -- <-- this pre-fills the search prompt
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
      end, { desc = "Find files filtered by clipboard content" })

      -- <leader>[1-9]{ss,sS,sg,ff,fF} / <leader>-[1-9]{…}: same hierarchy as
      -- nvim-tree [1-9]/[1-9], from buffer path under workdir / tree root (not git).
      do
        local hier = require("utils.hierarchy")
        local grep_winopts = {
          width = 0.95,
          height = 0.95,
          layout = "horizontal",
          preview = { layout = "vertical", vertical = "right:55%" },
        }
        local files_winopts = {
          width = 0.95,
          height = 0.95,
          layout = "horizontal",
          preview = { layout = "vertical", vertical = "right:55%", scrollbar = "float" },
        }

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

        local function grep_in_dir(search, cwd, extra)
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
          if type(extra) == "table" then
            for k, v in pairs(extra) do
              opts[k] = v
            end
          end
          fzf.grep(require("utils.clipboard").picker_opts(opts))
        end

        local function files_in_dir(cwd, query)
          if not cwd then
            return
          end
          local opts = {
            cwd = cwd,
            prompt = "Files (" .. vim.fn.fnamemodify(cwd, ":t") .. ")> ",
            winopts = files_winopts,
          }
          if query then
            opts.no_ignore = false
            opts.fzf_opts = {
              ["--query"] = query,
              ["--ansi"] = "",
              ["--layout"] = "reverse",
              ["--info"] = "default",
            }
            opts.winopts = {
              width = 0.9,
              height = 0.9,
              layout = "horizontal",
              preview = {
                layout = "vertical",
                vertical = "right:55%",
                scrollbar = "float",
              },
            }
          end
          fzf.files(require("utils.clipboard").picker_opts(opts))
        end

        local function bind(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, { desc = desc })
        end

        for i = 1, 9 do
          local level = i

          -- From project root down: <leader>1ss …
          bind("<leader>" .. i .. "ss", function()
            local yank = yank_for_grep('"')
            if yank then
              grep_in_dir(yank, hier.dir_at_hierarchy_level(level))
            end
          end, string.format("Search yank (hierarchy level %d)", i))
          bind("<leader>" .. i .. "sS", function()
            local yank = yank_for_grep("+")
            if yank then
              grep_in_dir(yank, hier.dir_at_hierarchy_level(level))
            end
          end, string.format("Search clipboard (hierarchy level %d)", i))
          bind("<leader>" .. i .. "sg", function()
            grep_in_dir("", hier.dir_at_hierarchy_level(level), {
              actions = {
                ["ctrl-g"] = { actions.grep_lgrep },
                ["ctrl-r"] = { actions.toggle_ignore },
              },
            })
          end, string.format("Search (hierarchy level %d)", i))
          bind("<leader>" .. i .. "ff", function()
            files_in_dir(hier.dir_at_hierarchy_level(level))
          end, string.format("Find files (hierarchy level %d)", i))
          bind("<leader>" .. i .. "fF", function()
            local yank = vim.fn.getreg('"')
            if yank == "" then
              vim.notify("Clipboard is empty", vim.log.levels.INFO)
              return
            end
            yank = yank:gsub("[\r\n]+$", ""):gsub("^%s*(.-)%s*$", "%1")
            files_in_dir(hier.dir_at_hierarchy_level(level), yank)
          end, string.format("Find files yank (hierarchy level %d)", i))
          bind("<leader>" .. i .. "sd", function()
            local cwd = hier.dir_at_hierarchy_level(level)
            if cwd then
              require("utils.directory_picker").open(cwd)
            end
          end, string.format("Find directory (hierarchy level %d)", i))

          -- Up toward project root: <leader>-1ss …
          bind("<leader>-" .. i .. "ss", function()
            local yank = yank_for_grep('"')
            if yank then
              grep_in_dir(yank, hier.dir_n_levels_up(level))
            end
          end, string.format("Search yank (%d levels up)", i))
          bind("<leader>-" .. i .. "sS", function()
            local yank = yank_for_grep("+")
            if yank then
              grep_in_dir(yank, hier.dir_n_levels_up(level))
            end
          end, string.format("Search clipboard (%d levels up)", i))
          bind("<leader>-" .. i .. "sg", function()
            grep_in_dir("", hier.dir_n_levels_up(level), {
              actions = {
                ["ctrl-g"] = { actions.grep_lgrep },
                ["ctrl-r"] = { actions.toggle_ignore },
              },
            })
          end, string.format("Search (%d levels up)", i))
          bind("<leader>-" .. i .. "ff", function()
            files_in_dir(hier.dir_n_levels_up(level))
          end, string.format("Find files (%d levels up)", i))
          bind("<leader>-" .. i .. "fF", function()
            local yank = vim.fn.getreg('"')
            if yank == "" then
              vim.notify("Clipboard is empty", vim.log.levels.INFO)
              return
            end
            yank = yank:gsub("[\r\n]+$", ""):gsub("^%s*(.-)%s*$", "%1")
            files_in_dir(hier.dir_n_levels_up(level), yank)
          end, string.format("Find files yank (%d levels up)", i))
          bind("<leader>-" .. i .. "sd", function()
            local cwd = hier.dir_n_levels_up(level)
            if cwd then
              require("utils.directory_picker").open(cwd)
            end
          end, string.format("Find directory (%d levels up)", i))
        end
      end

      vim.keymap.set("n", "<leader>lS", function()
        local yank = vim.fn.getreg('"')
      
        yank = yank:gsub("[\r\n]+$", "")
        yank = yank:gsub("^%s*(.-)%s*$", "%1")
        yank = yank:gsub("[^%w_]+", "")
      
        require("fzf-lua").lsp_live_workspace_symbols({
          -- symbols = { "Struct", "TypeAlias", "Enum", "Class" },
          previewer = "builtin",
          -- query = yank,
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
      end, { desc = "Live workspace symbols (clangd, seeded)" })

    vim.keymap.set("n", "<leader>fb", "<cmd>FzfLua buffers<CR>", { desc = "Fzf Buffers" })
    vim.keymap.set("n", "<leader>fG", "<cmd>FzfLua git_files<CR>", { desc = "Fzf Git files" })
    vim.keymap.set("n", "<leader>:", "<cmd>FzfLua command_history<CR>", { desc = "Fzf command_history" })
    vim.keymap.set("n", "<leader>sB", "<cmd>FzfLua lines<CR>", { desc = "Fzf lines" })
    vim.keymap.set("n", '<leader>s"', "<cmd>FzfLua registers<CR>", { desc = "Fzf registers" })
    vim.keymap.set("n", "<leader>gf", "<cmd>FzfLua git_files<CR>", { desc = "Fzf git_files" })
    vim.keymap.set("n", "<leader>gf", "<cmd>FzfLua git_files<CR>", { desc = "Fzf git_files" })
    vim.keymap.set("n", "<leader>sw", "<cmd>FzfLua grep_cword<CR>", { desc = "Fzf grep_cword" })
    end,
  },
}

