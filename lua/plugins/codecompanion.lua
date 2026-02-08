return {
  {
    "olimorris/codecompanion.nvim",
    version = "^18.0.0",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("codecompanion").setup({
        display = {
          action_palette = {
            width = 95,
            height = 10,
            prompt = "Prompt ", -- Prompt used for interactive LLM calls
            provider = "fzf_lua", -- Can be "default", "telescope", "fzf_lua", "mini_pick" or "snacks". If not specified, the plugin will autodetect installed providers.
            opts = {
              show_preset_actions = true, -- Show the preset actions in the action palette?
              show_preset_prompts = true, -- Show the preset prompts in the action palette?
              title = "CodeCompanion actions", -- The title of the action palette
            },
            diff = {
              enabled = true,
              -- provider = inline.diff, -- inline|split|mini_diff
            },
          },
          chat = {
            intro_message = "Welcome to Code Assistent ✨! Press ? for options",
            separator = "─", -- The separator between the different messages in the chat buffer
            show_context = true, -- Show context (from slash commands and variables) in the chat buffer?
            show_header_separator = false, -- Show header separators in the chat buffer? Set this to false if you're using an external markdown formatting plugin
            show_settings = false, -- Show LLM settings at the top of the chat buffer?
            show_token_count = true, -- Show the token count for each response?
            show_tools_processing = true, -- Show the loading message when tools are being executed?
            start_in_insert_mode = false, -- Open the chat buffer in insert mode?
            auto_scroll = true,
            opts = {
              completion_provider = "cmp", -- blink|cmp|coc|default
            },
            icons = {
              buffer_sync_all = "󰪴 ",
              buffer_sync_diff = " ",
              chat_context = " ",
              chat_fold = " ",
              tool_pending = "  ",
              tool_in_progress = "  ",
              tool_failure = "  ",
              tool_success = "  ",
            },
            fold_context = true,
          },
        },
        interactions = {
          chat = { 
            adapter = "openai_compatible",
            roles = {
              ---The header name for the LLM's messages
              ---@type string|fun(adapter: CodeCompanion.Adapter): string
              llm = function(adapter)
                return "Assistent (" .. adapter.formatted_name .. ")"
              end,

              ---The header name for your messages
              ---@type string
              user = "Me",
            },
            variables = {
              ["buffer"] = {
                opts = {
                  -- Always sync the buffer by sharing its "diff"
                  -- Or choose "all" to share the entire buffer
                  default_params = "diff",
                },
              },
            },
            opts = {
              system_prompt = "My personal AI, as my Second brain",
            },
          },
          inline = { 
            adapter = "openai_compatible",
            layout = "vertical", -- vertical|horizontal|buffer
            keymaps = {
              accept_change = {
                modes = { n = "ga" },
                description = "Accept the suggested change",
              },
              reject_change = {
                modes = { n = "gr" },
                opts = { nowait = true },
                description = "Reject the suggested change",
              },
            },
          },
          cmd = { adapter = "openai_compatible", }
        },
        adapters = {
          http = {
            openai_compatible = function()
              return require("codecompanion.adapters").extend("openai_compatible", {
                name = "personal_ai_station",
                formatted_name = "Personal AI Station",
                roles = {
                  llm = "assistant",
                  user = "user",
                },
                env = {
                  api_key = "LMSTUDIO_API_KEY",
                  url = "http://106.55.165.251:8810",
                },
                schema = {
                  model = {
                    default = "qwen/qwen3-coder-30b",
                    -- default = "google/gemma-3-27b",
                    -- default = "openai/gpt-oss-20b",
                  },
                },
              })
            end,
          }
        }
      })

      -- Keybindings
      vim.keymap.set({ "n", "v" }, "<leader>cg", "<cmd>CodeCompanionChat Toggle<cr>", { desc = "AI Chat" })
      vim.keymap.set({ "n", "v" }, "<leader>ai", "<cmd>CodeCompanion<cr>", { desc = "AI Inline" })
      -- For markdown render
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "codecompanion",
        callback = function()
          vim.bo.filetype = "markdown"
        end,
      })
    end,
  },
}

