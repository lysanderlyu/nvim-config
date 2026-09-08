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
      local action_state = require("telescope.actions.state")
      local telescope_state = require("telescope.state")

      -- Scroll the preview a fixed number of lines instead of half a page
      local function preview_scroll_lines(lines)
        return function(prompt_bufnr)
          local previewer = action_state.get_current_picker(prompt_bufnr).previewer
          local status = telescope_state.get_status(prompt_bufnr)
          if type(previewer) ~= "table" or previewer.scroll_fn == nil or status.preview_win == nil then
            return
          end
          previewer:scroll_fn(lines)
        end
      end

      local preview_scroll_keys = {
        ["<C-j>"] = preview_scroll_lines(1),
        ["<C-k>"] = preview_scroll_lines(-1),
      }

      telescope.setup({
        defaults = {
          mappings = {
            i = preview_scroll_keys,
            n = preview_scroll_keys,
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
