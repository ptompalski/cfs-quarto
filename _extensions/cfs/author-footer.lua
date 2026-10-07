local function value_type(value)
  if value == nil then
    return nil
  end

  return pandoc.utils.type(value)
end

local function stringify(value)
  if value == nil then
    return ""
  end

  return pandoc.utils.stringify(value)
end

local function author_list(meta)
  local authors = meta.authors or meta.author
  local authors_type = value_type(authors)

  if authors == nil then
    return {}
  elseif authors_type == "List" or authors_type == "MetaList" then
    return authors
  else
    return { authors }
  end
end

local function author_name(author)
  if value_type(author) == "table" or value_type(author) == "Map" or
      value_type(author) == "MetaMap" then
    local name = author.name or author.literal
    if name ~= nil then
      if value_type(name) == "table" or value_type(name) == "Map" or
          value_type(name) == "MetaMap" then
        return stringify(name.literal or name.family or name.given)
      end

      return stringify(name)
    end

    if author.family ~= nil or author.given ~= nil then
      local given = stringify(author.given)
      local family = stringify(author.family)
      return (given .. " " .. family):gsub("^%s+", ""):gsub("%s+$", "")
    end
  end

  return stringify(author)
end

local function family_name(author)
  if value_type(author) == "table" or value_type(author) == "Map" or
      value_type(author) == "MetaMap" then
    local name = author.name
    if name ~= nil and (value_type(name) == "table" or
        value_type(name) == "Map" or value_type(name) == "MetaMap") and
        name.family ~= nil then
      return stringify(name.family)
    elseif author.family ~= nil then
      return stringify(author.family)
    end
  end

  local name = author_name(author)
  local comma_family = name:match("^%s*([^,]+),")
  if comma_family ~= nil then
    return comma_family:gsub("%s+$", "")
  end

  return name:match("([^%s]+)%s*$") or name
end

local function text_inlines(text)
  local inlines = pandoc.Inlines({})
  local first = true

  for word in text:gmatch("%S+") do
    if not first then
      inlines:insert(pandoc.Space())
    end
    inlines:insert(pandoc.Str(word))
    first = false
  end

  return inlines
end

local function author_label(authors)
  if #authors == 1 then
    return author_name(authors[1])
  elseif #authors == 2 then
    return author_name(authors[1]) .. ", " .. author_name(authors[2])
  elseif #authors > 2 then
    return family_name(authors[1]) .. " et al."
  end

  return ""
end

local function has_class(div, class_name)
  for _, class in ipairs(div.classes) do
    if class == class_name then
      return true
    end
  end

  return false
end

local function prepend_to_footer_div(div, label)
  if not has_class(div, "footer-default") then
    return nil
  end

  local prefix_text = label .. " |"
  if stringify(div.content):sub(1, #prefix_text) == prefix_text then
    return nil
  end

  local prefix = text_inlines(prefix_text)
  local first_block = div.content[1]

  if first_block ~= nil and
      (first_block.t == "Para" or first_block.t == "Plain") then
    prefix:insert(pandoc.Space())
    for _, inline in ipairs(first_block.content) do
      prefix:insert(inline)
    end
    first_block.content = prefix
  else
    div.content:insert(1, pandoc.Para(prefix))
  end

  return div
end

function Pandoc(doc)
  local label = author_label(author_list(doc.meta))

  if label == "" then
    return nil
  end

  return doc:walk({
    Div = function(div)
      return prepend_to_footer_div(div, label)
    end
  })
end
