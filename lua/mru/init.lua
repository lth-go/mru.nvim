local file = require("mru.file")
local utils = require("mru.utils")

local M = {
  opts = {
    threshold = 2000,
    file_ignore_patterns = {
      "^%.git/",
      "/%.git/",
      "/usr/",
      "/tmp/",
    },
  },
  db = vim.fn.stdpath("data") .. "/mru",
  previous = nil,
}

M.load = function()
  local stat = file.stat(M.db)
  if stat == nil or stat.type ~= "file" then
    return {}
  end

  local content = file.read_file(M.db)
  if content == nil then
    return {}
  end

  local file_paths = utils.reverse_uniq(vim.split(content, "\n"))
  if #file_paths == 0 then
    return {}
  end

  return file_paths
end

M.add = function(file_path)
  if file_path == "" then
    return
  end

  for _, v in ipairs(M.opts.file_ignore_patterns) do
    if string.find(file_path, v) then
      return
    end
  end

  if file_path == M.previous then
    return
  end

  M.previous = file_path

  file.write_file_append(M.db, file_path .. "\n")
end

M.sync = function()
  local file_paths = M.load()
  file_paths = utils.reverse(file_paths)

  if #file_paths > M.opts.threshold then
    file_paths = vim.list_slice(file_paths, 1, M.opts.threshold)
  end

  file.write_file(M.db, table.concat(file_paths, "\n") .. "\n")
end

M.setup = function(opts)
  M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})

  M.add_autocmd()
  M.run()
end

M.run = function()
  local timer = vim.uv.new_timer()

  timer:start(
    1000 * 60 * 5,
    1000 * 60 * 10,
    vim.schedule_wrap(function()
      M.sync()
    end)
  )
end

M.add_autocmd = function()
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = vim.api.nvim_create_augroup("mru.nvim", {}),
    callback = function(args)
      local current_win = vim.api.nvim_get_current_win()
      if vim.api.nvim_win_get_config(current_win).relative ~= "" then
        return
      end

      if not vim.api.nvim_buf_is_valid(args.buf) then
        return
      end

      if vim.bo[args.buf].buftype ~= "" then
        return
      end

      if vim.bo[args.buf].bufhidden ~= "" then
        return
      end

      if not vim.bo[args.buf].buflisted then
        return
      end

      local current_file = vim.api.nvim_buf_get_name(args.buf)
      if current_file == "" then
        return
      end

      local stat = file.stat(current_file)
      if stat == nil or stat.type ~= "file" then
        return
      end

      current_file = vim.fn.fnamemodify(current_file, ":p")

      M.add(current_file)
    end,
  })
end

return {
  load = M.load,
  setup = M.setup,
}
