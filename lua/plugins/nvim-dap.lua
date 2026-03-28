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
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.50 }, -- Increased size for registers/variables
              { id = "breakpoints", size = 0.15 },
              { id = "stacks", size = 0.20 },
              { id = "watches", size = 0.15 },
            },
            position = "left",
            size = 45, -- Width of the sidebar in columns
          },
          {
            elements = {
              { id = "repl", size = 0.6 },
              { id = "console", size = 0.4 },
            },
            position = "bottom",
            size = 10, -- Height of the bottom tray
          },
        },
      })

      -- 3. Adapter: ARM Embedded GDB
      dap.adapters.gdb = {
        type = "executable",
        command = "arm-none-eabi-gdb",
        args = { "--interpreter=dap" }
      }

      -- 4. Configuration: Manual Attach Workflow
      dap.configurations.c = {
        {
          name = "Attach to ARM GDB Server",
          type = "gdb",
          request = "attach",
          -- Dynamic Port Selection
          target = function()
            local port = vim.fn.input('GDB Server Port: ', '3333')
            return "localhost:" .. port
          end,
          -- Binary Selection
          program = function()
            return vim.fn.input('Path to .elf: ', vim.fn.getcwd() .. '/', 'file')
          end,
          cwd = '${workspaceFolder}',
        },
      }
      -- 5. Automation: Open/Close UI
      dap.listeners.before.attach.dapui_config = function() dapui.open() end
      dap.listeners.before.launch.dapui_config = function() dapui.open() end
      dap.listeners.after.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.after.event_exited.dapui_config = function() dapui.close() end

      -- 6. Keybindings
      vim.keymap.set('n', '<Leader>5', function() dap.continue() end, { desc = "Debug: Start/Continue" })
      vim.keymap.set('n', '<Leader>0', function() dap.step_over() end, { desc = "Debug: Step Over" })
      vim.keymap.set('n', '<Leader>-', function() dap.step_into() end, { desc = "Debug: Step Into" })
      vim.keymap.set('n', '<Leader>=', function() dap.step_out() end, { desc = "Debug: Step Out" })
      vim.keymap.set('n', '<Leader>b', function() dap.toggle_breakpoint() end, { desc = "Debug: Toggle Breakpoint" })
      vim.keymap.set('n', '<Leader>dr', function() dap.repl.open() end, { desc = "Debug: Open REPL" })
      vim.keymap.set('n', '<Leader>du', function() dapui.toggle() end, { desc = "Debug: Toggle UI" })
    end,
  },
}
