---Open all multi-selected Telescope entries (or the current row if none selected).
local M = {}

local Path = require("plenary.path")
local action_state = require("telescope.actions.state")
local action_set = require("telescope.actions.set")
local pickers = require("telescope.pickers")

local edit_patched = false

---@param entry table
---@param picker table
---@return string?
local function entry_filename(entry, picker)
  local filename = entry.path or entry.filename
  if filename then
    return filename
  end
  local value = entry.value
  if type(value) ~= "string" or value == "" then
    return nil
  end
  if picker.cwd then
    return Path:new({ picker.cwd, value }):absolute()
  end
  return value
end

---@param picker table
---@param entry table
---@param command string vim edit command: edit, new, vnew, tabedit
local function open_entry(picker, entry, command)
  local filename = entry_filename(entry, picker)
  if not filename then
    return
  end
  filename = Path:new(filename):normalize(vim.loop.cwd())
  pcall(vim.cmd, string.format("%s %s", command, vim.fn.fnameescape(filename)))
end

---@param prompt_bufnr number
---@param select_type "default"|"horizontal"|"vertical"|"tab"
function M.select(prompt_bufnr, select_type)
  return action_set.select(prompt_bufnr, select_type)
end

---@param prompt_bufnr number
---@param select_type "default"|"horizontal"|"vertical"|"tab"
function M.edit_entries(prompt_bufnr, select_type)
  M.select(prompt_bufnr, select_type)
end

---Override open keys after Telescope applies defaults (git_status chains attach_mappings first).
---@param prompt_bufnr number
function M.bind_open_keys(prompt_bufnr)
  if not vim.api.nvim_buf_is_valid(prompt_bufnr) then
    return
  end
  local binds = {
    ["<CR>"] = "default",
    ["<C-t>"] = "tab",
    ["<C-v>"] = "vertical",
    ["<C-x>"] = "horizontal",
    ["<C-s>"] = "horizontal",
  }
  for keys, typ in pairs(binds) do
    vim.keymap.set({ "i", "n" }, keys, function()
      M.select(prompt_bufnr, typ)
    end, {
      buffer = prompt_bufnr,
      nowait = true,
    })
  end
end

function M.patch_open_actions()
  if edit_patched then
    return
  end
  edit_patched = true

  local action_set_mod = require("telescope.actions.set")
  local orig_edit = action_set_mod.edit
  action_set_mod.edit = function(prompt_bufnr, command)
    local picker = action_state.get_current_picker(prompt_bufnr)
    local entries = picker:get_multi_selection()
    if vim.tbl_isempty(entries) then
      return orig_edit(prompt_bufnr, command)
    end

    pickers.on_close_prompt(prompt_bufnr)
    pcall(vim.api.nvim_set_current_win, picker.original_win_id)

    for _, entry in ipairs(entries) do
      open_entry(picker, entry, command)
    end
  end
end

return M
