local M = {}

function M.copy_current_file()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    vim.notify("No file associated with this buffer", vim.log.levels.WARN)
    return
  end

  local name = vim.fn.fnamemodify(path, ":t")

  -- macOS
  if vim.fn.has("mac") == 1 then
    vim.fn.system({
      "osascript",
      "-e",
      string.format([[
        set theFile to POSIX file "%s"
        set the clipboard to theFile
      ]], path)
    })

  -- Windows / WSL
  elseif vim.fn.has("win32") == 1 or vim.fn.has("wsl") == 1 then
    local cmd = string.format(
      'powershell.exe -NoProfile -Command "Set-Clipboard -Path \'%s\'"',
      path
    )
    vim.fn.system(cmd)

  -- Linux
  else
    if vim.fn.executable("wl-copy") == 1 then
      vim.fn.system(
        string.format("printf 'file://%s' | wl-copy -t text/uri-list", path)
      )
    elseif vim.fn.executable("xclip") == 1 then
      vim.fn.system(
        string.format("printf 'file://%s' | xclip -selection clipboard -t text/uri-list", path)
      )
    elseif vim.fn.executable("xsel") == 1 then
      vim.fn.system(
        string.format("printf 'file://%s' | xsel --clipboard --input", path)
      )
    else
      vim.notify("No clipboard tool found (wl-copy/xclip/xsel)", vim.log.levels.ERROR)
      return
    end
  end

  vim.notify("Copied file: " .. name)
end

---Put paths on the system clipboard, and on the unnamed register so `p`
---pastes them too.
---@param paths string[]
---@return string text newline-joined as copied
function M.copy_paths(paths)
  local text = table.concat(paths, "\n")
  vim.fn.setreg("+", text) -- system clipboard
  vim.fn.setreg('"', text) -- unnamed, so `p` pastes them too
  return text
end

---Path of an fzf-lua picker line, tolerating icons and `:line:col` suffixes
---the way fzf-lua's own file actions do.
---@param entry string
---@param opts table|nil picker opts, used to resolve relative entries
---@return string|nil
local function picker_entry_path(entry, opts)
  local file = require("fzf-lua.path").entry_to_file(entry, opts)
  local path = file and file.path
  if not path or path == "" then
    return nil
  end
  return path
end

---Canonical absolute path: symlinks resolved, falling back to `path` when
---they cannot be.
---@param path string
---@return string
function M.realpath(path)
  return require("utils.git").realpath(path) or path
end

---`path` relative to the nearest git repo root, or to Neovim's cwd when there
---is no repo above it.
---@param path string
---@return string
function M.relpath(path)
  local git = require("utils.git")
  local info = git.nearest({ start = path, silent = true })
  -- No repo: Neovim's cwd is the next best base.
  return (info and git.relpath(info, path)) or vim.fn.fnamemodify(path, ":.")
end

---The two ways a picker copies a path. `map` turns a path from the picker —
---as shown, not yet resolved — into the text to copy; `label` names it in the
---info message and in fzf's `?` help.
---`header` is what fzf's `?` help lists; the relpath one names <C-S-c>, which
---fzf cannot show as a bind of its own.
local MODES = {
  realpath = { label = "Realpath", header = "copy realpath", map = M.realpath },
  relpath = { label = "Relative path", header = "copy relative path (<C-S-c>)", map = M.relpath },
}

---fzf-lua action: copy the file(s) in the picker in the given `mode`.
---`{+}` expands to the entries toggled with <Tab>, or the entry under the
---cursor when nothing is toggled.
---
---Bind it with `exec_silent = true` so the picker stays open — a plain
---function action accepts-and-closes instead. <Esc> still aborts.
---@param selected string[]
---@param opts table
---@param mode "realpath"|"relpath"
local function fzf_copy_paths(selected, opts, mode)
  local paths = {}
  for _, entry in ipairs(selected or {}) do
    local path = picker_entry_path(entry, opts)
    if path then
      paths[#paths + 1] = MODES[mode].map(path)
    end
  end

  local utils = require("fzf-lua.utils")
  if #paths == 0 then
    utils.warn("No file under the cursor")
    return
  end

  local text = M.copy_paths(paths)
  local label = MODES[mode].label

  if #paths == 1 then
    utils.info(label .. " copied: " .. text)
  else
    utils.info(("%d %s copied"):format(#paths, label:lower() .. "s"))
  end
end

---@param selected string[]
---@param opts table
function M.fzf_copy_realpath(selected, opts)
  fzf_copy_paths(selected, opts, "realpath")
end

---@param selected string[]
---@param opts table
function M.fzf_copy_relpath(selected, opts)
  fzf_copy_paths(selected, opts, "relpath")
end

---fzf key the relative-path copy hides behind in fzf-lua pickers, and the
---bytes a terminal sends for it. `alt-r` avoids fzf's own binds; `ctrl-y` is
---taken (`yank`: paste into the query line).
---@see M.picker_opts for why the shift is not in fzf's hands.
local RELPATH_KEY = "alt-r"
local RELPATH_BYTES = "\27r"

---fzf-lua `actions` table for a file picker. Built fresh per picker: fzf-lua
---mutates the tables it is given.
---@return table
function M.path_actions()
  return {
    ["ctrl-c"] = {
      fn = M.fzf_copy_realpath,
      exec_silent = true,
      header = MODES.realpath.header,
    },
    [RELPATH_KEY] = {
      fn = M.fzf_copy_relpath,
      exec_silent = true,
      header = MODES.relpath.header,
    },
  }
end

---Picker opts wired for path copying: <C-c> copies the realpath, <C-S-c> the
---relative path.
---@param opts table fzf-lua picker opts; `actions` and `winopts` are kept
---@return table the same table
function M.picker_opts(opts)
  opts.actions = vim.tbl_extend("keep", opts.actions or {}, M.path_actions())
  opts.winopts = M.with_shift_ctrl_c(opts.winopts)
  return opts
end

---Wrap a picker's `winopts` so that <C-S-c> copies the relative path.
---
---fzf cannot bind the key: it folds `ctrl-C` into `ctrl-c` and ignores the
---CSI-u/modifyOtherKeys encodings a terminal uses to distinguish them. Neovim
---does decode them, so a terminal-mode mapping on the fzf buffer gets the key
---first; forwarding <M-r> from there lets fzf expand `{+}` itself.
---@param winopts table|nil
---@return table
function M.with_shift_ctrl_c(winopts)
  winopts = winopts or {}
  local on_create = winopts.on_create

  winopts.on_create = function(e)
    if on_create then
      on_create(e)
    end

    local buf = e and e.bufnr
    if not (buf and vim.api.nvim_buf_is_valid(buf)) then
      return
    end

    vim.keymap.set("t", "<C-S-c>", function()
      vim.api.nvim_chan_send(vim.bo[buf].channel, RELPATH_BYTES)
    end, { buffer = buf, nowait = true, desc = "Copy relative path" })
  end

  return winopts
end

function M.copy_fs_object_from_nvim_tree()
  local api = require("nvim-tree.api")
  local node = api.tree.get_node_under_cursor()
  if not node or not node.absolute_path then return end

  local path = node.absolute_path
  local name = node.name

  -- macOS
  if vim.fn.has("mac") == 1 then
    vim.fn.system({
      "osascript",
      "-e",
      string.format([[
        set theFile to POSIX file "%s"
        set the clipboard to theFile
      ]], path)
    })

  -- Windows / WSL
  elseif vim.fn.has("win32") == 1 or vim.fn.has("wsl") == 1 then
    local cmd = string.format(
      'powershell.exe -NoProfile -Command "Set-Clipboard -Path \'%s\'"',
      path
    )
    vim.fn.system(cmd)

  -- Linux
  else
    if vim.fn.executable("wl-copy") == 1 then
      vim.fn.system(
        string.format("printf 'file://%s' | wl-copy -t text/uri-list", path)
      )
    elseif vim.fn.executable("xclip") == 1 then
      vim.fn.system(
        string.format("printf 'file://%s' | xclip -selection clipboard -t text/uri-list", path)
      )
    elseif vim.fn.executable("xsel") == 1 then
      vim.fn.system(
        string.format("printf 'file://%s' | xsel --clipboard --input", path)
      )
    else
      vim.notify("No clipboard tool found (wl-copy/xclip/xsel)", vim.log.levels.ERROR)
      return
    end
  end

  vim.notify("Copied filesystem object: " .. name)
end

return M
