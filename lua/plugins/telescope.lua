return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.6",
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- "nvim-telescope/telescope-fzf-native.nvim",
    },

    config = function()
      local telescope = require("telescope")
      local previewers = require("telescope.previewers")

      telescope.setup({
        pickers = {
          git_branches = {
            previewer = previewers.new_termopen_previewer({
              get_command = function(entry)
                return {
                  "git",
                  "-c", "core.pager=cat",
                  "log",
                  "-n", "1000", -- limit to 1000 lines
                  "--decorate",
                  "--graph",
                  "--oneline",
                  entry.value,
                }
              end,
            }),
          },
        },
      })

      -- telescope.load_extension("fzf")

      local opts = { noremap = true, silent = true }

      -- Function Outline with Treesitter
      -- vim.keymap.set("n", "<leader>cf", ":ShowFunctionsTelescope<CR>", opts)

    end,
  },
}
