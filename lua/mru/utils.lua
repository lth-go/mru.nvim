local M = {}

M.reverse = function(list)
  local result = {}

  for i = #list, 1, -1 do
    local item = list[i]
    table.insert(result, item)
  end

  return result
end

M.reverse_uniq = function(list)
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

return M
