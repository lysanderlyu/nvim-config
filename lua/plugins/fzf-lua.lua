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

        fzf.grep({
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
        })
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

        fzf.grep({
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
        })
      end, { desc = "Search last yank (\" register) with native preview" })

      vim.keymap.set("n", "<leader>sg", function()
        fzf.grep({
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
        })
      end, { desc = "Search native preview" })

      -- Map <leader>ff to find files
      vim.keymap.set("n", "<leader>ff", function()
        fzf.files({
          prompt = "Files> ",
          winopts = {
            width = 0.9,
            height = 0.9,
            layout = "horizontal",
            preview = { layout = "vertical", vertical = "right:55%", scrollbar = "float" },
          },
        })
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
      
        require("fzf-lua").files({
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
        })
      end, { desc = "Find files filtered by clipboard content" })

      vim.keymap.set("n", "<leader>lS", function()
        local yank = vim.fn.getreg('"')
      
        yank = yank:gsub("[\r\n]+$", "")
        yank = yank:gsub("^%s*(.-)%s*$", "%1")
        yank = yank:gsub("[^%w_]+", "")
      
        require("fzf-lua").lsp_live_workspace_symbols({
          -- symbols = { "Struct", "TypeAlias", "Enum", "Class" },
          previewer = "builtin",
          query = yank,
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
    vim.keymap.set("n", "<leader>sb", "<cmd>FzfLua lines<CR>", { desc = "Fzf lines" })
    vim.keymap.set("n", '<leader>s"', "<cmd>FzfLua registers<CR>", { desc = "Fzf registers" })
    vim.keymap.set("n", "<leader>gf", "<cmd>FzfLua git_files<CR>", { desc = "Fzf git_files" })
    vim.keymap.set("n", "<leader>gf", "<cmd>FzfLua git_files<CR>", { desc = "Fzf git_files" })
    vim.keymap.set("n", "<leader>sw", "<cmd>FzfLua grep_cword<CR>", { desc = "Fzf grep_cword" })
    end,
  },
}

