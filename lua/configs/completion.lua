-- =======================
-- Modules
-- =======================
local cmp = require("cmp")
local luasnip = require("luasnip")

-- =======================
-- Load Snippets
-- =======================
require("luasnip.loaders.from_lua").load({
  paths = { "../../snips" },
})

-- =======================
-- Snippet Config
-- =======================
local snippet = {
  expand = function(args)
    luasnip.lsp_expand(args.body)
  end,
}

-- =======================
-- Key Mappings
-- =======================
local mapping = cmp.mapping.preset.insert({
  ["<C-b>"] = cmp.mapping.scroll_docs(-4),
  ["<C-f>"] = cmp.mapping.scroll_docs(4),
  ["<C-Space>"] = cmp.mapping.complete(),
  ["<C-e>"] = cmp.mapping.abort(),

  ["<CR>"] = cmp.mapping.confirm({
    select = true,
  }),

  ["<Tab>"] = cmp.mapping(function(fallback)
    if cmp.visible() then
      cmp.select_next_item()
    else
      fallback()
    end
  end, { "i", "s" }),
  
  ["<S-Tab>"] = cmp.mapping(function(fallback)
    if cmp.visible() then
      cmp.select_prev_item()
    else
      fallback()
    end
  end, { "i", "s" }),
})

-- =======================
-- Sources
-- =======================
local sources = cmp.config.sources({
  { name = "nvim_lsp" },
  { name = "luasnip" },
  { name = "buffer" },
  { name = "path" },
  { name = "dictionary", keyword_length = 4, max_item_count = 15 },
  per_filetype = {
    codecompanion = { "codecompanion" },
  }
})

-- =======================
-- Setup
-- =======================
cmp.setup({
  snippet = snippet,
  mapping = mapping,
  sources = sources,
})

-- =======================
-- Filetype-specific sources
-- =======================
-- cmp.setup.filetype("codecompanion", {
--   sources = cmp.config.sources({
--     { name = "codecompanion" },
--   }),
-- })
