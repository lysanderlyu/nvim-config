-- Only the PlantUML keyword list is still handled by cmp-dictionary.
-- The big English word list moved to the built-in spell dictionary (see
-- configs/options.lua + configs/completion.lua): cmp-dictionary builds a
-- per-character Lua trie, which turned the 237k-word list into ~200 million
-- Lua tables (~540 MB RSS). This tiny keyword list costs nothing, and the
-- "dictionary" source is only wired up for the plantuml filetype.
return {
  {
    "uga-rosa/cmp-dictionary",
    dependencies = { "hrsh7th/nvim-cmp" },

    config = function()
      require("cmp_dictionary").setup({
        paths = { vim.fn.stdpath("config") .. "/dicts/puml_keywords.txt" },
        exact_length = 2,
        first_case_insensitive = true,
      })
    end,
  },
}
