return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    branch = "main",
    lazy = false, -- nvim-treesitter 不支持懒加载
    init = function()
      -- main 分支的 queries 在插件目录的 runtime/ 下，lazy 不会自动加入 rtp
      vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "/lazy/nvim-treesitter/runtime")
    end,
    dependencies = {
      { "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" },
    },
    config = function()
      require("nvim-treesitter").setup {}

      -- 高亮：Neovim 原生，全局 FileType 启用
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("TSPHighlight", { clear = true }),
        callback = function(args)
          -- parser 比 queries 旧时 query.get 会抛错，语言没有 highlights 查询时返回 nil；
          -- 两种情况都跳过，否则报错会在每次重绘时从 decoration provider 里刷屏
          local ok_lang, lang = pcall(vim.treesitter.language.get_lang, vim.bo[args.buf].filetype)
          if not ok_lang or not lang then return end
          local ok_q, q = pcall(vim.treesitter.query.get, lang, "highlights")
          if not ok_q or not q then return end
          vim.treesitter.start(args.buf)
        end,
      })

      -- 缩进（experimental）：仅对有 parser 的 filetype 启用
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("TSPIndent", { clear = true }),
        callback = function(args)
          local ok, lang = pcall(vim.treesitter.language.get_lang, vim.bo[args.buf].filetype)
          if ok and lang then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })

      -- textobjects：跳转 function / class
      require("nvim-treesitter-textobjects").setup {
        move = { set_jumps = true },
      }
      local move = require("nvim-treesitter-textobjects.move")
      vim.keymap.set({ "n", "x", "o" }, "]f", function() move.goto_next_start("@function.outer", "textobjects") end, { desc = "Next function start" })
      vim.keymap.set({ "n", "x", "o" }, "[f", function() move.goto_previous_start("@function.outer", "textobjects") end, { desc = "Prev function start" })
      vim.keymap.set({ "n", "x", "o" }, "]c", function() move.goto_next_start("@class.outer", "textobjects") end, { desc = "Next class start" })
      vim.keymap.set({ "n", "x", "o" }, "[c", function() move.goto_previous_start("@class.outer", "textobjects") end, { desc = "Prev class start" })
    end,
  },

  {
    "nvim-treesitter/playground",
    cmd = "TSPlaygroundToggle",
  },
}
