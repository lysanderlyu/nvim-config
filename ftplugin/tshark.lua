-- Fold `tshark -V` output by protocol section.
--
-- Section titles sit at column 0 and their fields are indented under them, so one
-- fold per title is enough: with foldlevel=0 a capture opens showing ONLY the
-- section titles, and zR / zj / zk / <CR> move around inside it.
local function is_title(line)
  -- column-0 line that is NOT a flush-left hexdump row ("0000  60 c8 5b ...")
  return line:match('^%S') ~= nil and line:match('^[0-9a-f]+%s%s') == nil
end

_G.TsharkFoldLevel = function(lnum)
  if is_title(vim.fn.getline(lnum)) then
    return '>1'
  end
  return '=' -- keep the indented lines (and hexdumps) in the current fold
end

_G.TsharkFoldText = function()
  local extra = vim.v.foldend - vim.v.foldstart
  return vim.fn.getline(vim.v.foldstart) .. '   [+' .. extra .. ']'
end

vim.opt_local.foldmethod = 'expr'
vim.opt_local.foldexpr = 'v:lua.TsharkFoldLevel(v:lnum)'
vim.opt_local.foldtext = 'v:lua.TsharkFoldText()'
vim.opt_local.foldminlines = 1
vim.opt_local.foldlevel = 0 -- titles only on open; `zR` opens everything
vim.opt_local.foldenable = true
