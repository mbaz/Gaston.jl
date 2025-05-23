


-- remove any lines with the hide_line directive.
function CodeBlock(el)
  if el.classes:includes('cell-code') then
    el.text = filter_lines(el.text, function(line)
      return not line:match("#| ?hide_line%s*$")
    end)
    return el
  end
end

-- apply filter_stream directive to cells
function Div(el)
  if el.classes:includes("cell") then
    local filters = el.attributes["filter_stream"]
    if filters then
      -- process cell-code
      return pandoc.walk_block(el, {
        CodeBlock = function(el)
          -- CodeBlock that isn't `cell-code` is output
          if not el.classes:includes("cell-code") then
            for filter in filters:gmatch("[^%s,]+") do
              el.text = filter_lines(el.text, function(line)
                return not line:find(filter, 1, true)
              end)
            end
            return el
          end
        end
      })
      
    end

  end
  
end

function filter_lines(text, filter)
  local lines = pandoc.List()
  local code = text .. "\n"
  for line in code:gmatch("([^\r\n]*)[\r\n]") do
    if filter(line) then
      lines:insert(line)
    end
  end
  return table.concat(lines, "\n")
end


