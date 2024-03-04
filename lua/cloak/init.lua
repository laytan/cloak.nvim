local group = vim.api.nvim_create_augroup('cloak', {})
local namespace = vim.api.nvim_create_namespace('cloak')

-- In case cmp is lazy loaded, we check :CmpStatus instead of a pcall to require
-- so we maintain the lazy load.
local has_cmp = function()
  return vim.fn.exists(':CmpStatus') > 0
end

local M = {}

M.opts = {
  enabled = true,
  cloak_character = '*',
  cloak_length = nil,
  highlight_group = 'Comment',
  try_all_patterns = true,
  patterns = { { file_pattern = '.env*', cloak_pattern = '=.+' } },
}

M.setup = function(opts)
  M.opts = vim.tbl_deep_extend('force', M.opts, opts or {})

  for _, pattern in ipairs(M.opts.patterns) do
    vim.api.nvim_create_autocmd(
      { 'BufRead', 'TextChanged', 'TextChangedI', 'TextChangedP' }, {
        pattern = pattern.file_pattern,
        callback = function()
          if M.opts.enabled then
            M.cloak(pattern.cloak_pattern)
          end
        end,
        group = group,
      }
    )
  end

  -- Handle cloaking the Telescope preview.
  vim.api.nvim_create_autocmd(
    'User', {
      pattern = 'TelescopePreviewerLoaded',
      callback = function(args)
        if not M.opts.enabled then
          return
        end

        local buffer = require('telescope.state').get_existing_prompt_bufnrs()[1]
        local picker = require('telescope.actions.state').get_current_picker(
          buffer
        )
        local base_name = vim.fn.fnamemodify(args.data.bufname, ':t')

        -- If our state variable is set, meaning we have just refreshed after cloaking a buffer,
        -- set the selection to that row again.
        if picker.__cloak_selection then
          picker:set_selection(picker.__cloak_selection)
          picker.__cloak_selection = nil
          vim.schedule(
            function()
              picker:refresh_previewer()
            end
          )
          return
        end

        local is_cloaked, _ = pcall(
          vim.api.nvim_buf_get_var, args.buf, 'cloaked'
        )

        -- Check the buffer agains all configured patterns,
        -- if matched, set a variable on the picker to know where we left off,
        -- set a buffer variable to know we already cloaked it later, and refresh.
        -- a refresh will result in the cloak being visible, and will make this
        -- aucmd be called again right away with the first result, which we will then
        -- set to what we have stored in the code above.
        for _, pattern in ipairs(M.opts.patterns) do
          -- Could be a string or a table of patterns.
          local file_patterns = pattern.file_pattern
          if type(file_patterns) == 'string' then
            file_patterns = { file_patterns }
          end

          for _, file_pattern in ipairs(file_patterns) do
            if base_name ~= nil and base_name:match(file_pattern) ~= nil then
              M.cloak(pattern)
              vim.api.nvim_buf_set_var(args.buf, 'cloaked', true)
              if is_cloaked then
                return
              end

              local row = picker:get_selection_row()
              picker.__cloak_selection = row
              picker:refresh()
              return
            end
          end
        end
      end,
      group = group,
    }
  )

  vim.api.nvim_create_user_command('CloakEnable', M.enable, {})
  vim.api.nvim_create_user_command('CloakDisable', M.disable, {})
  vim.api.nvim_create_user_command('CloakToggle', M.toggle, {})
end

M.uncloak = function()
  vim.api.nvim_buf_clear_namespace(0, namespace, 0, -1)
end

M.cloak = function(cloak_pattern)
  M.uncloak()

  if type(cloak_pattern) == 'string' then
    cloak_pattern = { cloak_pattern }
  end

  if has_cmp() then
    require('cmp').setup.buffer({ enabled = false })
  end

  local function determine_replacement(first_col, last_col)
    if tonumber(M.opts.cloak_length) ~= nil then
      return string.rep(M.opts.cloak_character, M.opts.cloak_length)..string.rep(' ', last_col - first_col)
    else
      return string.rep(M.opts.cloak_character, last_col - first_col)
    end
  end

  local found_pattern = false
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for i, line in ipairs(lines) do
    -- Find all matches for the current line
    local searchStartIndex = 1
    while searchStartIndex < #line do
      -- Find best pattern based on starting position and tiebreak with length
      local first, last = -1, 1
      for _, pattern in ipairs(cloak_pattern) do
        local current_first, current_last = line:find(pattern, searchStartIndex)
        if current_first ~= nil
          and (first < 0
            or current_first < first
            or (current_first == first and current_last > last)) then
          first, last = current_first, current_last
          if M.opts.try_all_patterns == false then break end
        end
      end
      if first >= 0 then
        found_pattern = true
        vim.api.nvim_buf_set_extmark(
          0, namespace, i - 1, first, {
            hl_mode = 'combine',
            virt_text = {
              {
                determine_replacement(first, last),
                M.opts.highlight_group,
              },
            },
            virt_text_pos = 'overlay',
          }
        )
      else break end
      searchStartIndex = last
    end
  end
  if found_pattern then
    vim.opt_local.wrap = false
  end
end

M.disable = function()
  M.uncloak()
  M.opts.enabled = false
end

M.enable = function()
  M.opts.enabled = true
  vim.cmd('doautocmd TextChanged')
end

M.toggle = function()
  if M.opts.enabled then
    M.disable()
  else
    M.enable()
  end
end

return M
