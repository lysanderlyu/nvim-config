-- plantuml-previewer.lua
return {
  {
    'lysanderlyu/plantuml-previewer.vim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'aklt/plantuml-syntax',
      'tyru/open-browser.vim',
    },
    config = function()
      local viewer = vim.fn.stdpath('data') .. '/lazy/plantuml-previewer.vim/viewer'

      local function is_fence_open(line)
        if not line then
          return false
        end
        local lower = line:lower()
        return lower:match('^%s*```+%s*plantuml') ~= nil
          or lower:match('^%s*```+%s*puml') ~= nil
      end

      local function is_fence_close(line)
        return line ~= nil and line:match('^%s*```+%s*$') ~= nil
      end

      -- The viewer is a static file:// page, so ask the browser whether a tab
      -- with it is still open. Returns true/false, or nil if the check failed.
      local function viewer_tab_open()
        local browsers = {
          'Google Chrome',
          'Safari',
          'Arc',
          'Brave Browser',
          'Microsoft Edge',
          'Chromium',
          'Vivaldi',
        }
        local parts = {
          'tell application "System Events" to set runningNames to name of every application process',
        }
        for _, name in ipairs(browsers) do
          parts[#parts + 1] = string.format([[
if runningNames contains "%s" then
  try
    tell application "%s"
      repeat with w in windows
        repeat with t in tabs of w
          if (URL of t as text) contains "plantuml-previewer.vim/viewer" then
            return "true"
          end if
        end repeat
      end repeat
    end tell
  end try
end if]], name, name)
        end
        parts[#parts + 1] = 'return "false"'

        local out = vim.fn.system({ 'osascript', '-e', table.concat(parts, '\n') })
        if vim.v.shell_error ~= 0 then
          return nil
        end
        return vim.trim(out) == 'true'
      end

      local function ensure_viewer_open()
        local tab_open = viewer_tab_open()
        if tab_open == false or (tab_open == nil and not vim.g.plantuml_previewer_opened) then
          vim.fn.jobstart({ 'open', viewer .. '/index.html' })
        end
        vim.g.plantuml_previewer_opened = true
      end

      -- Write the lines out as a temporary diagram next to the source file
      -- (so relative !include paths resolve) and feed the result to the
      -- viewer, which polls tmp.js once a second.
      local function preview_lines(lines)
        if vim.fn.executable('plantuml') == 0 then
          vim.notify('plantuml not found in PATH', vim.log.levels.ERROR)
          return
        end

        -- PlantUML needs a complete diagram
        if not lines[1] or not lines[1]:match('^%s*@start') then
          table.insert(lines, 1, '@startuml')
        end
        if not lines[#lines] or not lines[#lines]:match('^%s*@end') then
          table.insert(lines, '@enduml')
        end

        local src_dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':h')
        if src_dir == '' or vim.fn.isdirectory(src_dir) == 0 then
          src_dir = viewer
        end

        local stem = '.plantuml-preview-' .. vim.fn.getpid()
        local puml = src_dir .. '/' .. stem .. '.puml'
        local svg = src_dir .. '/' .. stem .. '.svg'

        if vim.fn.writefile(lines, puml) ~= 0 then
          vim.notify('Cannot write ' .. puml, vim.log.levels.ERROR)
          return
        end

        local ok, obj = pcall(function()
          return vim.system({ 'plantuml', '-tsvg', '-o', src_dir, puml }, { text = true }):wait()
        end)

        if not ok or obj.code ~= 0 or vim.fn.filereadable(svg) == 0 then
          vim.fn.delete(puml)
          local err = ok and (obj.stderr ~= '' and obj.stderr or 'render failed') or tostring(obj)
          vim.notify('PlantUML Error: ' .. err, vim.log.levels.ERROR)
          return
        end

        vim.uv.fs_copyfile(svg, viewer .. '/tmp.svg')
        vim.fn.delete(puml)
        vim.fn.delete(svg)

        vim.fn.writefile({
          "window.updateDiagramURL('" .. string.format('%d', vim.uv.hrtime()) .. "')",
        }, viewer .. '/tmp.js')

        ensure_viewer_open()
      end

      -- Treesitter: content of the ```plantuml block containing the cursor
      local function plantuml_block_at_cursor()
        local ok, parser = pcall(vim.treesitter.get_parser, 0)
        if not ok or not parser then
          return nil
        end
        local ok_parse, trees = pcall(parser.parse, parser, true)
        if not ok_parse or not trees or not trees[1] then
          return nil
        end

        local row, col = unpack(vim.api.nvim_win_get_cursor(0))
        local node = trees[1]:root():descendant_for_range(row - 1, col, row - 1, col)
        while node and node:type() ~= 'fenced_code_block' do
          node = node:parent()
        end
        if not node then
          return nil
        end

        local info, content
        for child in node:iter_children() do
          if child:type() == 'info_string' then
            info = child
          elseif child:type() == 'code_fence_content' then
            content = child
          end
        end
        if not info or not content then
          return nil
        end

        local lang = vim.treesitter.get_node_text(info, 0):lower():match('^%s*([%w_+%-]+)')
        if lang ~= 'plantuml' and lang ~= 'puml' then
          return nil
        end

        local lines = vim.split(vim.treesitter.get_node_text(content, 0), '\n', { plain = true })
        while #lines > 0 and lines[#lines]:match('^%s*$') do
          table.remove(lines)
        end
        return lines
      end

      -- Key mappings
      vim.keymap.set('n', '<leader>ps', ':PlantumlSave<CR>', { desc = 'PlantUML Save' })
      vim.keymap.set('n', '<leader>pt', function()
        -- Inside a ```plantuml fence, preview just that block; elsewhere keep
        -- the plugin's whole-file toggle.
        local lines = plantuml_block_at_cursor()
        if lines then
          preview_lines(lines)
          return
        end
        vim.cmd('PlantumlToggle')
        -- The viewer page stays open even when the previewer is toggled off
        vim.g.plantuml_previewer_opened = true
      end, { desc = 'PlantUML Toggle/Preview Block' })

      -- Preview only the visually selected lines, stripping markdown fences.
      vim.keymap.set('v', '<leader>pt', function()
        -- '< and '> are not set yet inside a Lua visual-mode mapping
        local anchor = vim.fn.line('v')
        local cursor = vim.fn.line('.')
        local start_line = math.min(anchor, cursor)
        local end_line = math.max(anchor, cursor)

        local buf = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local content_start, content_end = start_line, end_line

        if is_fence_open(buf[start_line]) then
          -- Drop the opening ```plantuml fence
          content_start = start_line + 1
          if end_line > start_line and is_fence_close(buf[end_line]) then
            content_end = end_line - 1
          elseif end_line == start_line then
            -- Only the fence line was selected: take the whole code block
            content_end = #buf
            for i = start_line + 1, #buf do
              if is_fence_close(buf[i]) then
                content_end = i - 1
                break
              end
            end
          end
        elseif end_line > start_line and is_fence_close(buf[end_line]) then
          -- Started inside the block but selected its closing fence
          content_end = end_line - 1
        end

        local lines = vim.list_slice(buf, content_start, content_end)
        if #lines == 0 then
          vim.notify('No PlantUML code in selection', vim.log.levels.WARN)
          return
        end

        preview_lines(lines)
      end, { desc = 'PlantUML Preview Selection' })
    end,
  },
}
