-- Telescope picker: staged files on the left, `git diff --cached` preview on the right
local function staged_changes()
  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local previewers = require 'telescope.previewers'
  local putils = require 'telescope.previewers.utils'
  local make_entry = require 'telescope.make_entry'
  local conf = require('telescope.config').values

  local root = vim.fn.systemlist({ 'git', 'rev-parse', '--show-toplevel' })[1]
  if vim.v.shell_error ~= 0 then
    vim.notify('Not inside a git repository', vim.log.levels.WARN)
    return
  end

  pickers
    .new({}, {
      prompt_title = 'Staged changes',
      finder = finders.new_oneshot_job(
        { 'git', 'diff', '--cached', '--name-only' },
        { cwd = root, entry_maker = make_entry.gen_from_file { cwd = root } }
      ),
      sorter = conf.file_sorter {},
      previewer = previewers.new_buffer_previewer {
        title = 'git diff --cached',
        define_preview = function(self, entry)
          putils.job_maker({ 'git', '--no-pager', 'diff', '--cached', '--', entry.value }, self.state.bufnr, {
            value = entry.value,
            bufname = self.state.bufname,
            cwd = root,
            callback = function(bufnr)
              if vim.api.nvim_buf_is_valid(bufnr) then putils.highlighter(bufnr, 'diff') end
            end,
          })
        end,
      },
    })
    :find()
end

return {
  'nvim-telescope/telescope.nvim',
  keys = {
    { '<leader>gs', staged_changes, desc = '[G]it [S]taged changes' },
    { '<leader>gS', function() require('telescope.builtin').git_status() end, desc = '[G]it [S]tatus (all changes)' },
  },
}
