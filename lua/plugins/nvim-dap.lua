return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      -- 1. Virtual Text Setup
      require("nvim-dap-virtual-text").setup({
        commented = true, -- Prefix virtual text with a comment string
      })

      -- 2. DAP UI Setup (Custom Layout for Registers)
      dapui.setup({
        controls = {
          element = "repl",
          enabled = true,
          icons = {
            disconnect = "",
            pause = "",
            play = "",
            run_last = "",
            step_back = "",
            step_into = "",
            step_out = "",
            step_over = "",
            terminate = ""
          }
        },
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.75 }, -- Increased size for registers/variables
              { id = "stacks", size = 0.20 },
              { id = "watches", size = 0.05 },
            },
            position = "left",
            size = 60, -- Width of the sidebar in columns
          },
          {
            elements = {
              { id = "breakpoints", size = 0.15 },
              { id = "repl", size = 0.85 },
              -- { id = "console", size = 0.3 },
            },
            position = "bottom",
            size = 15, -- Height of the bottom tray
          },
        },
      })

      -- 3. Adapter: ARM Embedded GDB
      dap.adapters.gdb = {
        type = "executable",
        command = "gdb",
        args = { "--interpreter=dap" }
      }

      -- -- Rust CodeLLDB (installed via Mason)
      -- dap.adapters.codelldb = {
      --   type = 'server',
      --   port = 16237,
      --   executable = {
      --     command = 'codelldb', -- Ensure this is in your PATH or provide absolute path
      --     args = { '--port', '16237' },
      --   }
      -- }

      -- Helper function to determine the default search path
      local function get_default_elf_path()
        local cwd = vim.fn.getcwd()
        
        -- 1. Check if 'target/' directory exists first
        if vim.fn.isdirectory(cwd .. '/target') == 1 then
          return cwd .. '/target/'
        end
        
        -- 2. Otherwise, default to 'build/'
        return cwd .. '/build/'
      end

      -- 4. Configuration: Manual Attach Workflow
      -- Shared Configuration for both C and Assembly
      local attach_config = {
      {
          name = "Attach to ARM GDB Server",
          type = "gdb",
          request = "attach",
          target = function()
            local port = vim.fn.input('GDB Server Port: ', '3333')
            return "localhost:" .. port
          end,
          program = function()
            -- Call the helper to decide whether target/ or build/ should be the default prompt
            local default_dir = get_default_elf_path()
            return vim.fn.input('Path to .elf: ', default_dir, 'file')
          end,
        },
      }
      dap.configurations.c = attach_config
      dap.configurations.asm = attach_config
      dap.configurations.rust = attach_config

      -- 5. Automation: Open/Close UI
      dap.listeners.before.attach.dapui_config = function() dapui.open() end
      dap.listeners.before.launch.dapui_config = function() dapui.open() end
      dap.listeners.after.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.after.event_exited.dapui_config = function() dapui.close() end

      -- 6. Keybindings
      vim.keymap.set('n', '<Leader>5', function() dap.continue() end, { desc = "Debug: Start/Continue" })
      vim.keymap.set('n', '<F10>', function() dap.step_over() end, { desc = "Debug: Step Over" })
      vim.keymap.set('n', '<F11>', function() dap.step_into() end, { desc = "Debug: Step Into" })
      vim.keymap.set('n', '<F12>', function() dap.step_out() end, { desc = "Debug: Step Out" })
      vim.keymap.set('n', '<Leader>b', function() dap.toggle_breakpoint() end, { desc = "Debug: Toggle Breakpoint" })
      vim.keymap.set('n', '<Leader>B', function() require('dap').set_breakpoint() end)
      vim.keymap.set('n', '<Leader>dap', function() dap.repl.open() end, { desc = "Debug: Open REPL" })
      vim.keymap.set('n', '<Leader>du', function() dapui.toggle() end, { desc = "Debug: Toggle UI" })
      vim.keymap.set('n', '<Leader>dr', function()
        local dap = require("dap")
        -- 1. Check if a session is already active
        if dap.session() then
          dap.repl.execute("load")
          dap.repl.execute("monitor reset")
          dap.repl.execute("monitor halt")
          dap.repl.execute("flushregs")
          dap.continue()
        end
      end, { desc = "Debug: Reset & Start/Continue" })
      vim.keymap.set('n', '<Leader>dc', function() require("dap").terminate() require("dapui").close() end, { desc = "Debug: Stop/Terminate Session" })

    end,
  },
}
