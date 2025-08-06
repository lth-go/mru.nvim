local M = {}

M.mru = function(opts, _)
  local current_file = vim.fs.normalize(vim.api.nvim_buf_get_name(0), { _fast = true })
  local cwd = vim.uv.cwd() .. "/"
  local limit = opts.limit or 15

  local files = require("mru").load()

  local filter = function(file)
    if not vim.startswith(file, cwd) then
      return false
    end

    if file == current_file then
      return false
    end

    local file_stat = vim.uv.fs_stat(file)
    if not file_stat or file_stat.type ~= "file" then
      return false
    end

    return true
  end

  local results = {}

  for _, file in ipairs(files) do
    if filter(file) then
      table.insert(results, file)

      if #results >= limit then
        break
      end
    end
  end

  return function(cb)
    for _, file in ipairs(results) do
      cb({ file = file, text = file })
    end
  end
end

return M
