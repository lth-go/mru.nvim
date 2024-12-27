local conf = require("telescope.config").values
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local pickers = require("telescope.pickers")
local telescope = require("telescope")

local mru = function(opts)
  local current_buffer = vim.api.nvim_get_current_buf()
  local current_file = vim.api.nvim_buf_get_name(current_buffer)
  local cwd = vim.uv.cwd() .. "/"
  local limit = 20

  local files = require("mru").load()

  files = vim.tbl_filter(function(file)
    return vim.startswith(file, cwd)
  end, files)

  local results = {}
  local seen = {}

  for _, file in ipairs(files) do
    if not seen[file] and file ~= current_file then
      local file_stat = vim.uv.fs_stat(file)
      if file_stat and file_stat.type == "file" then
        table.insert(results, file)
        seen[file] = true

        if #results >= limit then
          break
        end
      end
    end
  end

  pickers
    .new(opts, {
      prompt_title = "MRU",
      finder = finders.new_table({
        results = results,
        entry_maker = make_entry.gen_from_file(opts),
      }),
      sorter = conf.file_sorter(opts),
      previewer = conf.grep_previewer(opts),
    })
    :find()
end

return telescope.register_extension({
  exports = {
    mru = mru,
  },
})
