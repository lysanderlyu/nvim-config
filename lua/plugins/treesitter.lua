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
          "sql", "go", "bp", "php", "vue",
          "zathurarc", "rst", "qmljs", "javascript",
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
