return {
  "karb94/neoscroll.nvim",
  event = "VeryLazy", -- or remove if you want startup load
  config = function()
    -- 1️⃣ Setup neoscroll (NO auto mappings)
    require("neoscroll").setup({
      mappings = {},                -- IMPORTANT: disable built-in mappings
      hide_cursor = true,
      stop_eof = true,
      respect_scrolloff = false,
      cursor_scrolls_alone = true,
      duration_multiplier = 1.0,
      easing = "linear",
      performance_mode = false,
    })

    -- 2️⃣ Require neoscroll API
    local ns = require("neoscroll")

    -- 3️⃣ Define keymaps
    local modes = { "n", "v", "x" }

    vim.keymap.set(modes, "<C-d>", function()
      ns.ctrl_d({ duration = 250 })
    end, { desc = "Neoscroll half-page down" })

    vim.keymap.set(modes, "<C-u>", function()
      ns.ctrl_u({ duration = 250 })
    end, { desc = "Neoscroll half-page up" })

    vim.keymap.set(modes, "<C-f>", function()
      ns.ctrl_f({ duration = 450 })
    end, { desc = "Neoscroll page forward" })

    vim.keymap.set(modes, "<C-b>", function()
      ns.ctrl_b({ duration = 450 })
    end, { desc = "Neoscroll page backward" })

    vim.keymap.set(modes, "<C-y>", function()
      ns.scroll(-0.1, { move_cursor = false, duration = 100 })
    end, { desc = "Neoscroll up small" })

    vim.keymap.set(modes, "<C-e>", function()
      ns.scroll(0.1, { move_cursor = false, duration = 100 })
    end, { desc = "Neoscroll down small" })

    vim.keymap.set(modes, "zt", function()
      ns.zt({ duration = 150 })
    end, { desc = "Neoscroll zt" })

    vim.keymap.set(modes, "zz", function()
      ns.zz({ duration = 150 })
    end, { desc = "Neoscroll zz" })

    vim.keymap.set(modes, "zb", function()
      ns.zb({ duration = 150 })
    end, { desc = "Neoscroll zb" })
  end,
}
