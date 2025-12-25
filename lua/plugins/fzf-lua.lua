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
    end,
  },
}

