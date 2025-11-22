return {
  -- nvim-completion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "saadparwaiz1/cmp_luasnip",
      "L3MON4D3/LuaSnip",
    },
    config = function()
     local cmp = require('cmp')
     local luasnip = require('luasnip')
    
     cmp.setup({
       snippet = {
         expand = function(args)
           luasnip.lsp_expand(args.body)
         end,
       },
       mapping = {
         ['<Tab>'] = cmp.mapping(function(fallback)
           if cmp.visible() then
             cmp.select_next_item()
           elseif luasnip.expand_or_jumpable() then
             luasnip.expand_or_jump()
           else
             fallback()  -- insert a literal tab
           end
         end, { "i", "s" }),
    
         ['<S-Tab>'] = cmp.mapping(function(fallback)
           if cmp.visible() then
             cmp.select_prev_item()
           elseif luasnip.jumpable(-1) then
             luasnip.jump(-1)
           else
             fallback()
           end
         end, { "i", "s" }),
       },
       sources = cmp.config.sources({
         { name = 'nvim_lsp' },
         { name = 'luasnip' },
         { name = 'buffer' },
         { name = 'path' },
       }),
     })
     end,
  },
}
