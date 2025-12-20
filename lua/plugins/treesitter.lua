return {
  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    branch = 'master',
    config = function()
      require("nvim-treesitter").setup {
        ensure_installed = {
          "c", "cpp", "java", "kotlin", "python", "bash", "make", "cmake",
          "json", "yaml", "toml", "rust", "xml", "html", "css", "proto", "asm", "nasm",
          "markdown", "gitcommit", "lua", "c_sharp", "diff", "passwd", "ninja",
          "smali", "ssh_config", "ruby", "sql", "go", "blueprint", "bp", "php",
          "vue", "zathurarc", "rst", "qmljs", "javascript"
        },
        highlight = {
          enable = true,
          indent = true,
        },
      }
    end,
  },
  {
    "nvim-treesitter/playground",
    cmd = "TSPlaygroundToggle"
  },
}
