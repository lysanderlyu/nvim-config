-- Parsers inherited from the old master-branch setup. The main branch installs
-- nothing by itself, so list them explicitly: `install` fills in missing parsers
-- on startup (a cheap no-op once installed), and `build` installs/updates them
-- when :Lazy updates the plugin.
local parsers = {
  "arduino", "asm", "awk", "bash", "bitbake", "bp", "c", "c_sharp", "cmake",
  "cpp", "css", "csv", "cuda", "desktop", "devicetree", "diff", "disassembly",
  "dockerfile", "dot", "git_config", "git_rebase", "gitattributes", "gitcommit",
  "gitignore", "go", "html", "http", "java", "javadoc", "javascript", "json",
  "kconfig", "kotlin", "llvm", "lua", "luadoc", "make", "markdown",
  "markdown_inline", "matlab", "nasm", "ninja", "passwd", "perl", "php",
  "proto", "python", "qmljs", "rst", "ruby", "rust", "smali", "sql",
  "ssh_config", "strace", "toml", "udev", "vue", "xml", "yaml",
}

-- Wait for an nvim-treesitter async task and surface failures to :Lazy.
local function wait(task, what)
  local ok, res = task:pwait(1800000)
  if not ok or res == false then
    error(("treesitter: %s failed: %s"):format(what, tostring(res)))
  end
end

-- The main branch builds parsers with the external `tree-sitter` CLI. A Neovim
-- started outside a login shell (Finder, some GUI terminals) can get a PATH
-- without Homebrew, and vim.system then reports a confusing ENOENT for
-- 'tree-sitter'. Prepend the usual locations when the CLI is not resolvable.
local function ensure_ts_cli()
  if vim.fn.exepath("tree-sitter") ~= "" then
    return true
  end
  local path = vim.env.PATH or ""
  for _, dir in ipairs({ "/opt/homebrew/bin", "/usr/local/bin", "/opt/local/bin" }) do
    if vim.fn.executable(dir .. "/tree-sitter") == 1 then
      vim.env.PATH = dir .. ":" .. path
      return vim.fn.exepath("tree-sitter") ~= ""
    end
  end
  return false
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = function()
      if not ensure_ts_cli() then
        error("treesitter: `tree-sitter` CLI not found in PATH; install it or add its directory to PATH")
      end
      local ts = require("nvim-treesitter")
      wait(ts.install(parsers), "install")
      wait(ts.update(), "update")
    end,
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
      -- Install anything missing from `parsers` asynchronously; no-op when all
      -- are already present.
      if ensure_ts_cli() then
        require("nvim-treesitter").install(parsers)
      else
        vim.notify(
          "nvim-treesitter: `tree-sitter` CLI not found in PATH; cannot install parsers",
          vim.log.levels.ERROR
        )
      end

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
