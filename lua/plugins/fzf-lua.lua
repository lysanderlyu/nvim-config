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
      },
    },
    ---@diagnostics enable: missing-fields
    config = function(_, opts)
      local fzf = require("fzf-lua")
      fzf.setup(opts)

      -- 🔹 Search clipboard (+ register)
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

      -- 🔹 Search unnamed register (" register)
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

    end,
  },
}

