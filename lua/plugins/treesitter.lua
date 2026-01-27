return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    branch = "master",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      require("nvim-treesitter.configs").setup {
        ensure_installed = {
          "c", "cpp", "java", "kotlin", "python", "bash",
          "make", "cmake", "json", "yaml", "toml",
          "rust", "xml", "html", "css", "proto",
          "asm", "nasm", "markdown", "gitcommit",
          "lua", "c_sharp", "diff", "passwd",
          "ninja", "smali", "ssh_config", "ruby",
          "sql", "go", "bp", "php", "vue", "awk",
          "zathurarc", "rst", "qmljs", "javascript",
          "arduino", "csv", "cuda", "desktop", "devicetree",
          "disassembly", "dockerfile", "dot", "git_config",
          "git_rebase", "gitattributes", "gitignore", "http",
          "javadoc", "kconfig", "llvm", "luadoc",
          "matlab","perl", "strace", "udev",
        },

        highlight = {
          enable = true,
        },

        indent = {
          enable = true,
        },

        textobjects = {
          move = {
            enable = true,
            set_jumps = true,
            goto_next_start = {
              ["]f"] = "@function.outer",
              ["]c"] = "@class.outer",
            },
            goto_previous_start = {
              ["[f"] = "@function.outer",
              ["[c"] = "@class.outer",
            },
          },
        },
      }
    end,
  },

  {
    "nvim-treesitter/playground",
    cmd = "TSPlaygroundToggle",
  },
}
