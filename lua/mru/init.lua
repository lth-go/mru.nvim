local file = require("mru.file")

local uniq_reverse = function(list)
  local seen = {}
  local result = {}

  for i = #list, 1, -1 do
    local item = list[i]
    if item ~= "" and not seen[item] then
      table.insert(result, item)
      seen[item] = true
    end
  end

  return result
end

local M = {
  opts = {
    threshold = 500,
    file_ignore_patterns = {
      "^%.git/",
      "/%.git/",
    },
    enable_autocmd = true,
  },
  file = vim.fn.stdpath("data") .. "/mru",
  previous = nil,
}

M.load = function()
  local stat = file.stat(M.file)
  if stat == nil or stat.type ~= "file" then
    return {}
  end

  local content = file.read_file(M.file)
  if content == nil then
    return {}
  end

  local files = uniq_reverse(vim.split(content, "\n"))
  if #files == 0 then
    return {}
  end

  local is_sync = false

  if stat.mtime.sec < (os.time() - 3600 * 3) then
    is_sync = is_sync or true
  end

  if #files > M.opts.threshold * 2 then
    is_sync = is_sync or true

    files = vim.list_slice(files, 1, M.opts.threshold)
  end

  if is_sync then
    M.sync(vim.fn.reverse(vim.fn.copy(files)))
  end

  return files
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

  file.write_file_append(M.file, file_path .. "\n")
end

M.sync = function(file_paths)
  file.write_file(M.file, table.concat(file_paths, "\n") .. "\n")
end

M.setup = function(opts)
  M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})

  if M.opts.enable_autocmd then
    M.add_autocmd()
  end
end

M.add_autocmd = function()
  vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("mru.nvim", {}),
    callback = function(args)
      if not vim.api.nvim_buf_is_valid(args.buf) then
        return
      end

      if vim.api.nvim_get_option_value("buftype", { buf = args.buf }) ~= "" then
        return
      end

      if vim.api.nvim_get_option_value("bufhidden", { buf = args.buf }) ~= "" then
        return
      end

      local current_file = vim.api.nvim_buf_get_name(args.buf)
      if current_file == "" then
        return
      end

      current_file = vim.fn.fnamemodify(current_file, ":p")

      M.add(current_file)
    end,
  })
end

return {
  load = M.load,
  add = M.add,
  setup = M.setup,
}
