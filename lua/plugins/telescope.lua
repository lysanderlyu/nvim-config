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

      local telescope_multi = require("utils.telescope_multi")
      telescope_multi.patch_open_actions()

      -- Candidate list with Ctrl-j/k; preview half-page with Ctrl-d/u.
      -- Tab toggles multi-select (git status go / <leader>go); Ctrl-t/s/v/x open all selected.
      local two_pane_keys = {
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,
        ["<C-d>"] = actions.preview_scrolling_down,
        ["<C-u>"] = actions.preview_scrolling_up,
        ["<Tab>"] = actions.toggle_selection + actions.move_selection_next,
        ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_previous,
        ["<C-s>"] = actions.select_horizontal,
      }

      telescope.setup({
        defaults = {
          -- Replaces last char of caret/prefix when multi-selected (Telescope convention).
          multi_icon = "•",
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
            -- Runs after Telescope's git_status attach (which binds <Tab> to staging).
            attach_mappings = function(prompt_bufnr, _map)
              local tab_mark_next = actions.toggle_selection + actions.move_selection_next
              local tab_mark_prev = actions.toggle_selection + actions.move_selection_previous
              vim.keymap.set({ "i", "n" }, "<Tab>", function()
                tab_mark_next(prompt_bufnr)
              end, {
                buffer = prompt_bufnr,
                nowait = true,
                desc = "telescope|toggle_selection + move_selection_next",
              })
              vim.keymap.set({ "i", "n" }, "<S-Tab>", function()
                tab_mark_prev(prompt_bufnr)
              end, {
                buffer = prompt_bufnr,
                nowait = true,
                desc = "telescope|toggle_selection + move_selection_previous",
              })
              -- Stage/unstage moved off Tab (was git_staging_toggle).
              vim.keymap.set({ "i", "n" }, "<C-g>s", function()
                actions.git_staging_toggle(prompt_bufnr)
              end, {
                buffer = prompt_bufnr,
                desc = "telescope|git_staging_toggle",
              })
              -- Re-bind open keys after Telescope defaults (multi-open via action_set.edit hook).
              vim.schedule(function()
                telescope_multi.bind_open_keys(prompt_bufnr)
              end)
              return true
            end,
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
