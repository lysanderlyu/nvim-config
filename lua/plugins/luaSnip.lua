return {
  {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
    build = "make install_jsregexp",
    config = function()

      local ls = require("luasnip")
      local types = require("luasnip.util.types") -- Required for ext_opts


      ls.config.set_config({
        history = true,
        -- This updates the snippet as you type (great for mirrored text)
        update_events = "TextChanged,TextChangedI",
        -- Automatically leave snippet session if you move the cursor outside the region
        region_check_events = "CursorMoved",
        delete_check_events = "TextChanged",
        enable_autosnippets = false,
        
        -- VISUAL FEEDBACK: The "Highlight" part

        ext_opts = {
          [types.insertNode] = {
            active = {
              -- This adds a small virtual dot at the next jump location
              virt_text = { { "●", "NonText" } },
            },
          },
          [types.choiceNode] = {
            active = {
              -- Different icon/color for choice nodes to distinguish them
              virt_text = { { "󰻵", "WarningMsg" } },
            },

          },

        },
      })

      require("luasnip.loaders.from_vscode").lazy_load({ paths = "~/.config/nvim/snips" })

      -- Your existing Keymaps
      vim.keymap.set({"i", "s"}, "<C-j>", function() ls.jump(1) end, {silent = true})
      vim.keymap.set({"i", "s"}, "<C-k>", function() ls.jump(-1) end, {silent = true})
      vim.keymap.set({"i", "s"}, "<C-l>", function() ls.expand_or_jump() end, {silent = true})
      -- exit snippet
      vim.keymap.set({ "i", "s" }, "<C-e>", function()
        ls.unlink_current()
      end, { silent = true })
    end,
  },
}
