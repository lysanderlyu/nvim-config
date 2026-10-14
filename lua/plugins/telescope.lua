return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- "nvim-telescope/telescope-fzf-native.nvim",
    },

    config = function()
      local telescope = require("telescope")
      local previewers = require("telescope.previewers")
      local actions = require("telescope.actions")

      -- Candidate list with Ctrl-j/k; preview half-page with Ctrl-d/u.
      local two_pane_keys = {
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,
        ["<C-d>"] = actions.preview_scrolling_down,
        ["<C-u>"] = actions.preview_scrolling_up,
      }

      telescope.setup({
        defaults = {
          mappings = {
            i = two_pane_keys,
            n = two_pane_keys,
          },
        },
        pickers = {
          git_status = {
            layout_strategy = "horizontal",
            layout_config = {
              width = 0.95,
              height = 0.95,
              preview_width = 0.55,
            },
          },
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
