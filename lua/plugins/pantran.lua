return {
  {
    "potamides/pantran.nvim",
    config = function()
      require("pantran").setup({
        -- Default engine (can be "google", "deepl", "argos", "yandex", or "apertium")
        default_engine = "google",
        engines = {
          google = {
            fallback = {
              default_source = "auto",
              default_target = "zh", -- Set this to your preferred target language
            },
          },
        },
        controls = {
            mappings = {
              edit = {
                n = {
                  -- We use a function here to ensure it executes the window jump correctly
                  ["J"] = function()
                    vim.cmd("wincmd j")
                  end,
                  ["K"] = function()
                    vim.cmd("wincmd k")
                  end,
                }
              }
            }
          }
      })

      -- Keybindings
      local opts = { noremap = true, silent = true, expr = true }
      local pantran = require("pantran")

      -- Translate a motion (e.g., <leader>trip to translate a paragraph)
      vim.keymap.set("n", "<leader>tr", pantran.motion_translate, opts)

      -- Translate current line
      vim.keymap.set("n", "<leader>tl", function()
        return pantran.motion_translate() .. "_"
      end, opts)

      -- Translate selection in visual mode
      vim.keymap.set("x", "<leader>tr", pantran.motion_translate, opts)
    end,
  },
}
