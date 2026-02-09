local builtin = require("telescope.builtin")
local opts = { noremap = true, silent = true }

-- Custom command key
-- Quick select all the text with a delay
vim.keymap.set("n", "<leader>;a", function()
    vim.defer_fn(function()
        vim.cmd("normal! ggvG$")
    end, 50)
end, { desc = "Select All" })

-- tab keymaps
vim.keymap.set("n", "<leader>tq", ":tabclose<cr>", { desc = "Close tab" })
vim.keymap.set("n", "<leader>;0", ":tablast<cr>", { desc = "Last Tab" })
for i = 1, 9 do
  vim.keymap.set("n", ";" .. i, ":tabn " .. i .. "<CR>", { desc = "Go to tab " .. i })
end
vim.keymap.set("n", "<leader>tt", ":tabnew<cr>", { desc = "New Tab" })
vim.keymap.set("n", "<leader>lt", ":tabnext<cr>", { desc = "Next Tab" })
vim.keymap.set("n", "<leader>ht", ":tabprevious<cr>", { desc = "Previous Tab" })

-- :w and :q 
vim.keymap.set("n", "<leader>;w", ":w<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>;q", ":q<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>;W", ":wq<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>;Q", ":q!<CR>", { noremap = true, silent = true })
-- for :!./build.sh
vim.keymap.set("n", "<leader>;l", ":!./build.sh<CR>", { noremap = true, silent = true })
-- vim.keymap.set("n", "<leader>;l", ":terminal ./build.sh<CR>", { noremap = true, silent = true })
-- for remove the \r character
vim.keymap.set("n", "<leader>;r", ":%s/\\r//g<CR>", { noremap = true, silent = true })

-- for register + shortcut
-- Function: Yank N lines into system clipboard
local function yank_n_lines()
  local count = vim.v.count  -- number typed before ;
  if count == 0 then count = 1 end -- default to 1 if none
  vim.cmd('normal! ' .. count .. '"+yy')
  print(" Copied " .. count .. " line(s) to clipboard")
end
vim.keymap.set('n', ';y', yank_n_lines, { desc = "Yank N lines to clipboard", silent = true })
local function delete_n_lines()
  local count = vim.v.count  -- number typed before ;
  if count == 0 then count = 1 end -- default to 1 if none
  vim.cmd('normal! ' .. count .. '"+dd')
  print(" Deleted " .. count .. " line(s) to clipboard")
end
vim.keymap.set('n', ';d', delete_n_lines, { desc = "Delete N lines to clipboard", silent = true })
vim.keymap.set("n", "<leader>dg", ":diffget<CR>")
vim.keymap.set("n", "<leader>dp", ":diffput<CR>")
vim.keymap.set("v", "';", '"+y', { desc = "Yank to system clipboard" })
vim.keymap.set({"n", "v"}, ";'", '"+p', { desc = "Paste from system clipboard" })

-- shortcut for select the whole line (without the space on the head and tail)
vim.keymap.set("n", "vl", '^vg_', { desc = "Select whole line" })

-- Telescope file finder
vim.keymap.set("n", "<leader>sh", builtin.help_tags, opts)

-- telescope Git
vim.keymap.set("n", "<leader>go", builtin.git_status, opts)
vim.keymap.set("n", "<leader>gb", builtin.git_branches, opts)

-- Others
vim.keymap.set("n", "<leader>km", builtin.keymaps, opts)
vim.keymap.set("n", "<leader>cm", builtin.commands, opts)
vim.keymap.set("n", "<leader>/", builtin.current_buffer_fuzzy_find, opts)

-- map cn and cm to copy the file name
-- vim.keymap.set("n", "<leader>cn", ":let @+ = expand('%:p')<CR>")
vim.keymap.set("n", "<leader>cn", function()
  vim.fn.setreg('+', vim.fn.expand('%:p'))
end)

-- statuscol
require("statuscol").setup({
  segments = {
    { text = { "%s" }, click = "v:lua.ScSa" }, -- signs
    { text = { "%l" }, click = "v:lua.ScLa" }, -- line numbers
  },
})

-- Set shortkeys for plantuml compiling using plantuml and open it
vim.keymap.set("n", "<leader>cp", function()
  local file_path = vim.fn.expand("%:p")
  local extension = vim.fn.expand("%:e"):lower()
  local output_path = vim.fn.expand("%:p:r") .. ".png"

  -- 1. Validate File Format Extension
  local valid_extensions = { puml = true, plantuml = true, uml = true, iat = true }
  if not valid_extensions[extension] then
    vim.notify("Not a PlantUML file (." .. extension .. ")", vim.log.levels.WARN)
    return
  end

  -- 2. Validate File Existence
  if file_path == "" or vim.fn.filereadable(file_path) == 0 then
    vim.notify("File not found or unreadable", vim.log.levels.ERROR)
    return
  end

  -- Ensure file is saved before compiling
  vim.cmd("silent write")
  vim.notify("Compiling " .. vim.fn.expand("%:t") .. "...", vim.log.levels.INFO)

  -- 3. Execute PlantUML synchronously
  local obj = vim.system({ "plantuml", file_path, "--format=svg" }):wait()

  if obj.code ~= 0 then
    -- Clean up error message from stderr
    local err = obj.stderr ~= "" and obj.stderr or "Check PlantUML syntax"
    vim.notify("PlantUML Error: " .. err, vim.log.levels.ERROR)
    return
  end

  -- 4. Open the image using the system open program 
  vim.system({ "open", output_path })

  vim.notify("Render complete: " .. vim.fn.expand("%:t:r") .. ".png", vim.log.levels.INFO)
end)

-- Set shortkeys for plantuml compiling using plantuml and open it
vim.keymap.set("n", "<leader>cP", function()
  local file_path = vim.fn.expand("%:p")
  local extension = vim.fn.expand("%:e"):lower()
  local output_path = vim.fn.expand("%:p:r") .. ".png"

  -- 1. Validate File Format Extension
  local valid_extensions = { puml = true, plantuml = true, uml = true, iat = true }
  if not valid_extensions[extension] then
    vim.notify("Not a PlantUML file (." .. extension .. ")", vim.log.levels.WARN)
    return
  end

  -- 2. Validate File Existence
  if file_path == "" or vim.fn.filereadable(file_path) == 0 then
    vim.notify("File not found or unreadable", vim.log.levels.ERROR)
    return
  end

  -- Ensure file is saved before compiling
  vim.cmd("silent write")
  vim.notify("Compiling " .. vim.fn.expand("%:t") .. "...", vim.log.levels.INFO)

  -- 3. Execute PlantUML synchronously
  local obj = vim.system({ "plantuml", file_path, "--format=svg" }):wait()

  if obj.code ~= 0 then
    -- Clean up error message from stderr
    local err = obj.stderr ~= "" and obj.stderr or "Check PlantUML syntax"
    vim.notify("PlantUML Error: " .. err, vim.log.levels.ERROR)
    return
  end

  vim.notify("Render complete: " .. vim.fn.expand("%:t:r") .. ".png", vim.log.levels.INFO)
end)

-- For color picker
-- vim.api.nvim_set_keymap("n", "<leader>cp", "<cmd>CccPick<CR>", { noremap = true, silent = true })
-- vim.api.nvim_set_keymap("n", "<leader>cc", "<cmd>CccConvert<CR>", { noremap = true, silent = true })

-- For colorizer
-- vim.api.nvim_set_keymap("n", "<leader>cc", ":ColorizerToggle<CR>", { noremap = true, silent = true })
-- vim.api.nvim_set_keymap("n", "<leader>ca", ":ColorizerAttachToBuffer<CR>", { noremap = true, silent = true })

-- Set shortcut to switch last file
vim.keymap.set("n", "<C-f>", "<cmd>b#<CR>")

-- For diff with a specific commit
vim.keymap.set("n", "<leader>gD", function()
  -------------------------------------------------------
  -- 1. Validate buffer
  -------------------------------------------------------
  local file = vim.fn.expand("%:p")
  if file == "" or vim.fn.getftype(file) ~= "file" then
    vim.notify("Not a valid file", vim.log.levels.ERROR)
    return
  end

  -------------------------------------------------------
  -- 2. Get repo root
  -------------------------------------------------------
  local dirname = vim.fn.expand("%:h")
  local repo_path = vim.fn.systemlist(
    "git -C " .. vim.fn.shellescape(dirname) .. " rev-parse --show-toplevel"
  )[1]

  if repo_path == nil or repo_path == "" then
    vim.notify("Not inside a Git repository", vim.log.levels.ERROR)
    return
  end

  -------------------------------------------------------
  -- 3. Get repo-relative path (correct way)
  -------------------------------------------------------
  local rel_file = vim.fn.systemlist(
    "git -C " .. vim.fn.shellescape(repo_path)
    .. " ls-files --full-name "
    .. vim.fn.shellescape(file)
  )[1]

  if rel_file == nil or rel_file == "" then
    vim.notify("File is not tracked by Git", vim.log.levels.ERROR)
    return
  end

  -------------------------------------------------------
  -- 4. Show Git Log for this file
  -------------------------------------------------------
  Snacks.picker.git_log_file({
    confirm = function(picker, item)
      picker:close()
      local hash = item.oid or item.commit
      if not hash then
        vim.notify("No valid commit", vim.log.levels.ERROR)
        return
      end

      ---------------------------------------------------
      -- 5. Use Gvdiffsplit to show diff
      ---------------------------------------------------
      vim.schedule(function()
        local target = hash .. ":" .. rel_file
        vim.cmd("Gvdiffsplit " .. vim.fn.fnameescape(target))
      end)
    end,
  })
end, { desc = "Git log → Diff commit for current file" })


-- View a flattened DTS from a DTB file
local function view_dtb()
  local file = vim.fn.expand("%:p")
  if file == "" then
    print("No file under cursor")
    return
  end

  if not file:match("%.dtb$") then
    print("Not a DTB file")
    return
  end

  -- Temporary output file
  local tmp = vim.fn.tempname() .. ".dts"

  -- Decompile dtb
  local cmd = string.format("dtc -I dtb -O dts -s '%s' -o '%s'", file, tmp)
  local result = os.execute(cmd)
  if result ~= 0 then
    print("Failed to decompile DTB")
    return
  end

  -- Replace current buffer with tmp file
  vim.cmd("edit " .. tmp)

  -- When the buffer is unloaded (closed), remove the tmp file
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = 0,
    once = true,
    callback = function()
      os.remove(tmp)
    end,
  })
end
vim.keymap.set("n", "<leader>dt", view_dtb, { desc = "Decompile DTB to DTS" })

local function readelf_for_arch()
    local candidates = {
        "readelf",
        "aarch64-linux-gnu-readelf",
        "arm-none-eabi-readelf",
        "x86_64-linux-gnu-readelf",
    }

    for _, cmd in ipairs(candidates) do
        if vim.fn.executable(cmd) == 1 then
            return cmd
        end
    end

    return nil
end

local function detect_elf_arch(path)
    local readelf = readelf_for_arch()
    if not readelf then
        return nil, "no readelf found"
    end

    local out = vim.fn.system({ readelf, "-h", path })
    if vim.v.shell_error ~= 0 then
        return nil, "readelf failed"
    end

    local class = out:match("Class:%s+(ELF%d+)")
    local machine = out:match("Machine:%s+([^\n]+)")

    if not class or not machine then
        return nil, "not an ELF file"
    end

    -- Normalize
    machine = machine:lower()

    if class == "ELF32" and machine:match("arm") then
        return "arm32"
    elseif class == "ELF64" and machine:match("aarch64") then
        return "aarch64"
    elseif class == "ELF64" and machine:match("x86%-64") then
        return "x86_64"
    elseif class == "ELF32" and machine:match("intel 80386") then
        return "x86"
    end

    return "unknown"
end

local function objdump_for_arch(arch)
    local map = {
        arm32   = { "arm-none-eabi-objdump", "arm-linux-gnueabi-objdump", "rust-objdump"},
        aarch64 = { "aarch64-linux-gnu-objdump", "aarch64-none-elf-objdump" },
        x86_64  = { "objdump" },
        x86     = { "objdump" },
    }

    local candidates = map[arch]
    if not candidates then return nil end

    for _, cmd in ipairs(candidates) do
        if vim.fn.executable(cmd) == 1 then
            return cmd
        end
    end

    return nil
end

local function view_symbol()
  local file = vim.fn.expand("%:p")
  if file == "" then
    vim.notify("No file", vim.log.levels.WARN)
    return
  end

  local arch, err = detect_elf_arch(file)
  if not arch then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  local objdump = objdump_for_arch(arch)
  if not objdump then
    vim.notify("No objdump for arch: " .. arch, vim.log.levels.ERROR)
    return
  end

  local output = vim.fn.system({ objdump, "-S", file })
  if vim.v.shell_error ~= 0 then
    vim.notify("objdump failed", vim.log.levels.ERROR)
    return
  end

  vim.cmd("vnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(output, "\n"))

  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
  vim.bo.readonly = true
  vim.bo.filetype = ""

end

vim.keymap.set("n", "<leader>ds", view_symbol, { desc = "Disassemble ELF" })

local function view_assemble()
  local file = vim.fn.expand("%:p")
  if file == "" then
    vim.notify("No file", vim.log.levels.WARN)
    return
  end

  local arch, err = detect_elf_arch(file)
  if not arch then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  local objdump = objdump_for_arch(arch)
  if not objdump then
    vim.notify("No objdump for arch: " .. arch, vim.log.levels.ERROR)
    return
  end

  local output = vim.fn.system({ objdump, "-D", file })
  if vim.v.shell_error ~= 0 then
    vim.notify("objdump failed", vim.log.levels.ERROR)
    return
  end

  vim.cmd("vnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(output, "\n"))

  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
  vim.bo.readonly = true
  vim.bo.filetype = ""

end

vim.keymap.set("n", "<leader>da", view_assemble, { desc = "Disassemble ELF" })

-- For D2 compilation
vim.api.nvim_create_user_command("D2", function()
  local file = vim.fn.expand("%:p")
  local out  = vim.fn.expand("%:p:r") .. ".png"
  vim.fn.system({ "d2", file, out })

  -- preview according to different system
  if sys == "Darwin" then
    vim.fn.system({ "open", out })
  else
    vim.fn.system({ "xdg-open", png })
  end
end, {})
vim.keymap.set("n", "<leader>di", ":D2<CR>", { noremap = true, silent = true, desc = "Run D2 compile" })

-- Delete buffer quickly
vim.keymap.set("n", "<leader>bd", ":bd<CR>", { desc = "delete current buffer" })
-- reload current buffer
vim.keymap.set("n", "<leader>br", ":e!<CR>", { desc = "reload current buffer" })
vim.keymap.set("n", "<leader>bR", ":bufdo e!<CR>", { desc = "reload all buffers" })
-- Neovim: keep current buffer only
vim.keymap.set("n", "<leader>bo", function()
  -- Close all other tabs first (cleaner for the UI)
  vim.cmd("tabonly")
  
  -- Delete all other buffers
  local cur = vim.api.nvim_get_current_buf()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= cur and vim.bo[buf].buflisted then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
end)

-- Dashboard shortkey
vim.keymap.set("n", "<leader>db", function()
  if vim.bo.filetype == "dashboard" then
    -- 1. Get a list of all valid buffers
    local bufs = vim.fn.getbufinfo({ buflisted = 1 })
    
    -- 2. If only the dashboard is open, create a new file
    if #bufs <= 1 then
      vim.cmd("enew")
    else
      -- 3. Otherwise, switch to the last used buffer (the "alternate" buffer)
      -- This is the equivalent of pressing Ctrl + ^
      local success = pcall(vim.cmd, "buffer #")
      if not success then
        vim.cmd("bnext") -- Fallback if alternate buffer is invalid
      end
    end
  else
    -- If not on dashboard, open it
    vim.cmd("Dashboard")
  end
end, { desc = "Toggle Dashboard / Smart Back" })
