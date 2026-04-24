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
        rules = {
          default = {
            description = "Collection of common files for all projects",
            files = {
              ".clinerules",
              ".cursorrules",
              ".goosehints",
              ".rules",
              ".windsurfrules",
              ".github/copilot-instructions.md",
              "AGENT.md",
              "AGENT.puml",
              "AGENTS.md",
              "CLAUDE.puml",
              "arch.puml",
              { path = "CLAUDE.md", parser = "claude" },
              { path = "CLAUDE.local.md", parser = "claude" },
              { path = "~/.claude/CLAUDE.md", parser = "claude" },
            },
          },
        },
        groups = {
          ["agent"] = {
            description = "My custom agent",
            system_prompt = function(group, ctx)
              return string.format(
                "You are a coding agent. The date is %s. The user is on %s.",
                ctx.date,
                ctx.os
              )
            end,
            tools = { "read_file", "insert_edit_into_file", "run_command" },
            opts = {
              collapse_tools = true,
              ignore_system_prompt = true, -- Remove the chat's default system prompt
              ignore_tool_system_prompt = true, -- Remove the default tool system prompt
            },
          },
        },
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
              system_prompt = "My personal AI, As my Second brain",
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
            deepseek = function()
              return require("codecompanion.adapters").extend("deepseek", {
                name = "Agent (DeepSeek)",
                formatted_name = "Personal AI Station (DeepSeek)",
                roles = {
                  llm = "assistant",
                  user = "user",
                },
                env = {
                  api_key = "MY_DEEPSEEK_KEY",
                  url = "https://api.deepseek.com",
                },
                schema = {
                  model = {
                    -- default = "deepseek-v4-flash",
                  },
                },
              })
            end,
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
                    -- default = "qwen/qwen3-coder-30b",
                    -- default = "qwen/qwen3.6-35b-a3b",
                    default = "qwen/qwen3.6-27b",
                    -- default = "qwen/qwen3.5-35b-a3b",
                    -- default = "google/gemma-4-31b",
                    -- default = "google/gemma-4-26b-a4b",
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
      vim.keymap.set({ "n", "v" }, "<leader>ca", "<cmd>CodeCompanionActions<cr>", { desc = "AI Action" })
      vim.keymap.set({ "n", "v" }, "<leader>cg", "<cmd>CodeCompanionChat Toggle<cr>", { desc = "AI Chat" })
      vim.keymap.set({ "n", "v" }, "<leader>cG", "<cmd>CodeCompanionChat adapter=deepseek<cr>", { desc = "AI Chat (DeepSeek)" })
      vim.keymap.set({ "n", "v" }, "<leader>ai", "<cmd>CodeCompanion<cr>", { desc = "AI Inline" })
    end,
  },
}

