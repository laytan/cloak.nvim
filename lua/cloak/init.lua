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
            M.cloak(pattern)
          end
        end,
        group = group,
      }
    )
  end

  vim.api.nvim_create_user_command('CloakEnable', M.enable, {})
  vim.api.nvim_create_user_command('CloakDisable', M.disable, {})
  vim.api.nvim_create_user_command('CloakToggle', M.toggle, {})
end

M.uncloak = function()
  vim.api.nvim_buf_clear_namespace(0, namespace, 0, -1)
end

M.cloak = function(pattern)
  M.uncloak()

  local cloak_pattern =
    type(pattern.cloak_pattern) == 'string'
    and { pattern.cloak_pattern }
    or pattern.cloak_pattern

  if has_cmp() then
    require('cmp').setup.buffer({ enabled = false })
  end

  local function determine_replacement(length, prefix)
    local cloak_str = prefix
      .. M.opts.cloak_character:rep(
        tonumber(M.opts.cloak_length)
        or length - vim.fn.strchars(prefix))
    local remaining_length = length - vim.fn.strchars(cloak_str)
    -- Fixme:
    -- - When cloak_length is longer than the text underlying it,
    --   it results in overlaying of extra text
    -- => Possiblie solutions would could be implemented using inline virtual text
    --    (https://github.com/neovim/neovim/pull/20130)
    return cloak_str -- :sub(1, math.min(remaining_length - 1, -1))
      .. (' '):rep(remaining_length)
  end

  local found_pattern = false
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for i, line in ipairs(lines) do
    -- Find all matches for the current line
    local searchStartIndex = 1
    while searchStartIndex < #line do
      -- Find best pattern based on starting position and tiebreak with length
      local first, last, matching_pattern, has_groups = -1, 1, nil, nil, false
      for _, pattern in ipairs(cloak_pattern) do
        local current_first, current_last, capture_group =
          line:find(pattern, searchStartIndex)
        if current_first ~= nil
          and (first < 0
            or current_first < first
            or (current_first == first and current_last > last)) then
          first, last, matching_pattern, has_groups =
            current_first, current_last, pattern, capture_group ~= nil
          if M.opts.try_all_patterns == false then break end
        end
      end
      if first >= 0 then
        found_pattern = true
        local prefix = line:sub(first,first)
        if has_groups and pattern.replace ~= nil then
          prefix = line:sub(first,last):gsub(matching_pattern, pattern.replace, 1)
        end
        vim.api.nvim_buf_set_extmark(
          0, namespace, i - 1, first-1, {
            hl_mode = 'combine',
            virt_text = {
              {
                determine_replacement(last - first + 1, prefix),
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
