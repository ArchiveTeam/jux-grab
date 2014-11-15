dofile("urlcode.lua")
dofile("table_show.lua")
JSON = (loadfile "JSON.lua")()

local url_count = 0
local tries = 0
local item_type = os.getenv('item_type')
local item_value = os.getenv('item_value')

local downloaded = {}
local addedtolist = {}

load_json_file = function(file)
  if file then
    local f = io.open(file)
    local data = f:read("*all")
    f:close()
    return JSON:decode(data)
  else
    return nil
  end
end

read_file = function(file)
  if file then
    local f = assert(io.open(file))
    local data = f:read("*all")
    f:close()
    return data
  else
    return ""
  end
end

wget.callbacks.download_child_p = function(urlpos, parent, depth, start_url_parsed, iri, verdict, reason)
  local url = urlpos["url"]["url"]
  local html = urlpos["link_expect_html"]
  local parenturl = parent["url"]
  local html = nil
  
  if downloaded[url] == true or addedtolist[url] == true then
    return false
  end
  
  if string.match(url, "https://") then
    newurl = string.gsub(url, "https://", "http://")
  elseif string.match(url, "http://") then
    newurl = url
  end
  
  if item_type == "jux" and (downloaded[newurl] ~= true or addedtolist[newurl] ~= true) then
    if string.match(url, item_value.."%.jux%.com") then
      addedtolist[url] = true
      return true
    else
      return false
    end
  end
end


wget.callbacks.get_urls = function(file, url, is_css, iri)
  local urls = {}
  local html = nil
        
  if item_type == "jux" then
    if string.match(url, item_value.."%.jux%.com") then
      
      html = read_file(file)
      
      io.stdout:write("Url "..url.." is being checked for extracting links.  \n")
      io.stdout:flush()
      
      if string.match(url, item_value.."%.jux%.com/[0-9]+[^/]") then
        local newurl = url..".json"
        if downloaded[newurl] ~= true and addedtolist[newurl] ~= true then
          table.insert(urls, { url=newurl })
          addedtolist[newurl] = true
        end
      end
      
      if string.match(url, item_value.."%.jux%.com/[^/]+/[0-9]+[^/a-zA-Z]") then
        local postid = string.match(url, "%.jux%.com/[^/]+/([0-9]+)[^/a-zA-Z]")
        local newurl = item_value..".jux.com/"..postid
        if downloaded[newurl] ~= true and addedtolist[newurl] ~= true then
          table.insert(urls, { url=newurl })
          addedtolist[newurl] = true
        end
      end
      
      if string.match(url, "/sitemap%.xml") then
        for customurl in string.gmatch(html, ">(http[s]?://[^<]+)<") do
          if downloaded[customurl] ~= true and addedtolist[customurl] ~= true then
            table.insert(urls, { url=customurl })
            addedtolist[customurl] = true
          end
        end
      end
      
      for customurl in string.gmatch(html, '"(http[s]?://[^"]+)"') do
        if string.match(customurl, item_value.."%.jux%.com") then
          if string.match(customurl, "https://") then
            local newcustomurl = string.gsub(customurl, "https://", "http://")
            if downloaded[newcustomurl] ~= true and addedtolist[newcustomurl] ~= true then
              table.insert(urls, { url=customurl })
              addedtolist[newcustomurl] = true
            end
          elseif string.match(customurl, "http://") then
            if downloaded[customurl] ~= true and addedtolist[customurl] ~= true then
              table.insert(urls, { url=customurl })
              addedtolist[customurl] = true
            end
          end
        end
      end
      for customurlnf in string.gmatch(html, '"//([^"]+)"') do
        if string.match(customurlnf, item_value.."%.jux%.com") then
          local base = "http://"
          local customurl = base..customurlnf
          if downloaded[customurl] ~= true and addedtolist[customurl] ~= true then
            table.insert(urls, { url=customurl })
            addedtolist[customurl] = true
          end
        end
      end
      for customurlnf in string.gmatch(html, '"(/[^/][^"]+)"') do
        if string.match(customurlnf, item_value.."%.jux%.com") then
          local base = "http://"..item_value..".jux.com"
          local customurl = base..customurlnf
          if downloaded[customurl] ~= true and addedtolist[customurl] ~= true then
            table.insert(urls, { url=customurl })
            addedtolist[customurl] = true
          end
        end
      end
    end
  end
  
  return urls
end
  

wget.callbacks.httploop_result = function(url, err, http_stat)
  -- NEW for 2014: Slightly more verbose messages because people keep
  -- complaining that it's not moving or not working
  local status_code = http_stat["statcode"]
  
  url_count = url_count + 1
  io.stdout:write(url_count .. "=" .. status_code .. " " .. url["url"] .. ".  \n")
  io.stdout:flush()
  
  if (status_code >= 200 and status_code <= 399) or status_code == 403 then
    if string.match(url["url"], "https://") then
      local newurl = string.gsub(url["url"], "https://", "http://")
      downloaded[newurl] = true
    else
      downloaded[url["url"]] = true
    end
  end
  
  if status_code >= 500 or
    (status_code >= 400 and status_code ~= 404 and status_code ~= 403) then
    io.stdout:write("\nServer returned "..http_stat.statcode..". Sleeping.\n")
    io.stdout:flush()

    os.execute("sleep 1")

    tries = tries + 1

    if tries >= 20 then
      io.stdout:write("\nI give up...\n")
      io.stdout:flush()
      return wget.actions.ABORT
    else
      return wget.actions.CONTINUE
    end
  elseif status_code == 0 then
    io.stdout:write("\nServer returned "..http_stat.statcode..". Sleeping.\n")
    io.stdout:flush()

    os.execute("sleep 10")

    tries = tries + 1

    if tries >= 10 then
      io.stdout:write("\nI give up...\n")
      io.stdout:flush()
      return wget.actions.ABORT
    else
      return wget.actions.CONTINUE
    end
  end

  tries = 0

  -- We're okay; sleep a bit (if we have to) and continue
  -- local sleep_time = 0.1 * (math.random(75, 1000) / 100.0)
  local sleep_time = 0

  --  if string.match(url["host"], "cdn") or string.match(url["host"], "media") then
  --    -- We should be able to go fast on images since that's what a web browser does
  --    sleep_time = 0
  --  end

  if sleep_time > 0.001 then
    os.execute("sleep " .. sleep_time)
  end

  return wget.actions.NOTHING
end