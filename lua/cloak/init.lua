local group = vim.api.nvim_create_augroup('cloak', {})
local namespace = vim.api.nvim_create_namespace('cloak')

local has_cmp, cmp = pcall(require, 'cmp')

local M = {}

M.opts = {
  enabled = true,
  cloak_character = '*',
  patterns = {
      { file_pattern = '.env*', cloak_pattern = '=.+' }
  },
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

  vim.api.nvim_create_user_command('CloakEnable', M.enable, {})
  vim.api.nvim_create_user_command('CloakDisable', M.disable, {})
  vim.api.nvim_create_user_command('CloakToggle', M.toggle, {})
end

M.uncloak = function()
  vim.api.nvim_buf_clear_namespace(0, namespace, 0, -1)
end

M.cloak = function(cloak_pattern)
  M.uncloak()

  if has_cmp then
    cmp.setup.buffer({ enabled = false })
  end

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for i, line in ipairs(lines) do
    local first, last = line:find(cloak_pattern)

    if first ~= nil then
      vim.api.nvim_buf_set_extmark(
        0, namespace, i - 1, first, {
          virt_text = { { string.rep(M.opts.cloak_character, last - first), 'Comment' } },
          virt_text_pos = 'overlay',
        }
      )
    end
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
