-- English word completion via the built-in spell dictionary.
-- The source registers itself (after/plugin) and is_available() returns
-- vim.wo.spell, so it only fires in buffers where 'spell' is on
-- (<leader>us). No word list to maintain; spelllang is set in configs/options.lua.
return {
  {
    "f3fora/cmp-spell",
    dependencies = { "hrsh7th/nvim-cmp" },
  },
}
