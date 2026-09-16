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

      local function snippet_desc(snip)
        local dscr = snip.dscr
        if type(dscr) == "table" then
          return table.concat(dscr, " ")
        end
        return dscr or snip.name or ""
      end

      local function snippet_doc(snip)
        local doc = snip:get_docstring()
        if type(doc) == "table" then
          doc = table.concat(doc, "\n")
        end
        if type(doc) ~= "string" or doc == "" then
          return snip.trigger
        end
        return doc
      end

      local function snippet_picker()
        local fts = require("luasnip.util.util").get_snippet_filetypes()
        local items = {}
        local seen = {}

        for _, ft in ipairs(fts) do
          for _, snip in ipairs(ls.get_snippets(ft) or {}) do
            if not snip.hidden and not seen[snip.id] then
              seen[snip.id] = true
              local dscr = snippet_desc(snip)
              items[#items + 1] = {
                text = table.concat({ snip.trigger, dscr, ft }, " "),
                trigger = snip.trigger,
                dscr = dscr,
                ft = ft,
                snip = snip,
                preview = {
                  text = snippet_doc(snip),
                  ft = vim.bo.filetype ~= "" and vim.bo.filetype or "text",
                },
              }
            end
          end
        end

        table.sort(items, function(a, b)
          if a.trigger == b.trigger then
            return a.ft < b.ft
          end
          return a.trigger < b.trigger
        end)

        if #items == 0 then
          vim.notify("No snippets for this filetype", vim.log.levels.INFO)
          return
        end

        require("snacks").picker.pick({
          source = "snippets",
          title = "Snippets (" .. (vim.bo.filetype ~= "" and vim.bo.filetype or "all") .. ")",
          items = items,
          preview = "preview",
          format = function(item)
            return {
              { item.trigger, "Keyword" },
              { "  " },
              { item.dscr, "Comment" },
            }
          end,
          confirm = function(picker, item)
            picker:close()
            if item and item.snip then
              vim.schedule(function()
                ls.snip_expand(item.snip)
              end)
            end
          end,
        })
      end

      vim.keymap.set("n", "<leader>sn", snippet_picker, { desc = "Snippets for this file" })

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
