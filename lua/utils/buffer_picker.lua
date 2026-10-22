local M = {}

local function entry_from_selection(selected, opts)
  local path = require("fzf-lua.path")
  local utils = require("fzf-lua.utils")
  local entry = path.entry_to_file(selected[1], opts)
  if entry.bufnr or not entry.path then
    return entry
  end
  local fullpath = entry.path
  if not path.is_absolute(fullpath) then
    fullpath = path.join({ opts.cwd or utils.cwd(), fullpath })
  end
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(b) == fullpath then
      entry.bufnr = b
      break
    end
  end
  return entry
end

local function tabwin_for_buf(bufnr)
  for _, tabh in ipairs(vim.api.nvim_list_tabpages()) do
    for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(tabh)) do
      if vim.api.nvim_win_get_buf(winid) == bufnr then
        return tabh, winid
      end
    end
  end
end

local function focus_buf_window(entry, opts)
  local utils = require("fzf-lua.utils")
  if not utils.is_term_buffer(0) then
    vim.cmd("normal! m`")
  end
  local tabh, winid = tabwin_for_buf(entry.bufnr)
  if not tabh or not winid then
    return false
  end
  vim.api.nvim_set_current_tabpage(tabh)
  vim.api.nvim_set_current_win(winid)
  if not opts.no_action_set_cursor and (entry.line > 0 or entry.col > 0) then
    pcall(vim.api.nvim_win_set_cursor, 0, {
      math.max(1, entry.line),
      math.max(1, entry.col or 0) - 1,
    })
  end
  if not utils.is_term_buffer(0) and not opts.no_action_zz then
    vim.cmd("norm! zvzz")
  end
  return true
end

--- fzf-lua buffers: jump to the tab/window showing the buffer, or open in a new tab.
function M.switch_tab_or_tabnew(selected, opts)
  local actions = require("fzf-lua.actions")
  if not selected[1] then
    return
  end
  if #selected > 1 then
    return actions.buf_edit_or_qf(selected, opts)
  end

  local entry = entry_from_selection(selected, opts)
  if entry.bufnr and focus_buf_window(entry, opts) then
    return
  end

  actions.buf_tabedit(selected, opts)
end

return M
