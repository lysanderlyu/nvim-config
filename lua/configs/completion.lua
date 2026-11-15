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
  -- Show this filetype's snippets even with no typed prefix
  ["<C-Space>"] = cmp.mapping.complete({
    config = {
      sources = {
        { name = "luasnip" },
      },
    },
  }),
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
  { name = "spell", keyword_length = 4, max_item_count = 15 },
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
-- PlantUML keywords (dicts/puml_keywords.txt, 779 entries) matter both in .puml
-- files and inside ```plantuml fenced blocks in markdown, where the buffer
-- filetype stays markdown. cmp-dictionary holds only that small list now, so
-- wiring it up for these two filetypes costs nothing.
local prose_sources = cmp.config.sources({
  { name = "nvim_lsp" },
  { name = "luasnip" },
  { name = "buffer" },
  { name = "path" },
  { name = "dictionary", keyword_length = 2, max_item_count = 15 },
  { name = "spell", keyword_length = 4, max_item_count = 15 },
})

cmp.setup.filetype({ "plantuml", "markdown" }, {
  sources = prose_sources,
})
