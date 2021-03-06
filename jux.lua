dofile("urlcode.lua")
dofile("table_show.lua")
JSON = (loadfile "JSON.lua")()

local url_count = 0
local tries = 0
local externaldomain = "nothing"
local item_type = os.getenv('item_type')
local item_value = os.getenv('item_value')

local downloaded = {}
local addedtolist = {}
local insitemap = {}

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
    if string.match(url, item_value.."%.jux%.com")
      or string.match(url, externaldomain)
      or string.match(url, "s3%.amazonaws%.com")
      or string.match(url, "ajax%.googleapies%.com")
      or string.match(url, "fonts%.googleapies%.com")
      or string.match(url, "fonts%.gstatic%.com")
      or string.match(url, "api%.mixpanel%.com")
      or string.match(url, "cdn%.mxpnl%.com")
      or string.match(url, "js%-agent%.newrelic%.com")
      or string.match(url, "beacon%-1%.newrelic%.com")
      or string.match(url, "doubleclick%.net")
      or string.match(url, "%.cloudfront%.net")
      or string.match(url, "/assets/") then
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
    
    if insitemap[url] == true and not string.match(url, item_value.."%.jux%.com") then
      externaldomain = string.match(url, "http[s]?://([^/]+)/")
    end
    
    if string.match(url, item_value.."%.jux%.com") or string.match(url, externaldomain) then
      
      html = read_file(file)
      
      if (string.match(url, item_value.."%.jux%.com/[0-9]+[^/]") or string.match(url, externaldomain.."/[0-9]+[^/]")) and not string.match(url, "%.json") then
        local newurl = url..".json"
        if downloaded[newurl] ~= true and addedtolist[newurl] ~= true then
          table.insert(urls, { url=newurl })
          addedtolist[newurl] = true
        end
      end
      
      if (string.match(url, item_value.."%.jux%.com") or string.match(url, externaldomain)) and not (string.match(url, "%?_escaped_fragment_=") and string.match(url, "%.json") and string.match(url, "%.txt") and string.match(url, "%.xml") and string.match(url, "%.ico") and string.match(url, "%.png")) then
        local newurl = url.."?_escaped_fragment_="
        if downloaded[newurl] ~= true and addedtolist[newurl] ~= true then
          table.insert(urls, { url=newurl })
          addedtolist[newurl] = true
        end
      end
      
      local jsonbase = string.match(url, "(http[s]?://[^/]+/)")
      local ownerjson = jsonbase.."owner.json"
      if downloaded[ownerjson] ~= true and addedtolist[ownerjson] ~= true then
        table.insert(urls, { url=ownerjson })
        addedtolist[ownerjson] = true
      end
      local sitemapxml = jsonbase.."sitemap.xml"
      if downloaded[sitemapxml] ~= true and addedtolist[sitemapxml] ~= true then
        table.insert(urls, { url=sitemapxml })
        addedtolist[sitemapxml] = true
      end
      local robotstxt = jsonbase.."robots.txt"
      if downloaded[robotstxt] ~= true and addedtolist[robotstxt] ~= true then
        table.insert(urls, { url=robotstxt })
        addedtolist[robotstxt] = true
      end
      local quarksjson1 = jsonbase.."quarks.json"
      if downloaded[quarksjson1] ~= true and addedtolist[quarksjson1] ~= true then
        table.insert(urls, { url=quarksjson1 })
        addedtolist[quarksjson1] = true
      end
      local quarksjson2 = jsonbase.."quarks.json?per_page=1000000000"
      if downloaded[quarksjson2] ~= true and addedtolist[quarksjson2] ~= true then
        table.insert(urls, { url=quarksjson2 })
        addedtolist[quarksjson2] = true
      end
      
      
      if string.match(url, item_value.."%.jux%.com/[^/]+/[0-9]+[^/a-zA-Z]") or string.match(url, externaldomain.."/[^/]+/[0-9]+[^/a-zA-Z]") then
        local basesite = string.match(url, "http[s]?://([^/]+)/")
        local postid = string.match(url, "http[s]?://"..basesite.."/[^/]+/([0-9]+[^/a-zA-Z])")
        local newurl = "http://"..basesite.."/"..postid
        local newpostidjson = url..".json"
        if downloaded[newurl] ~= true and addedtolist[newurl] ~= true then
          table.insert(urls, { url=newurl })
          addedtolist[newurl] = true
        end
        if not string.match(url, "%.json") then
          if downloaded[newpostidjson] ~= true and addedtolist[newpostidjson] ~= true then
            table.insert(urls, { url=newpostidjson })
            addedtolist[newpostidjson] = true
          end
        end
      end
      
      if string.match(url, "/sitemap%.xml") then
        for customurl in string.gmatch(html, ">(http[s]?://[^<]+)<") do
          if downloaded[customurl] ~= true and addedtolist[customurl] ~= true then
            table.insert(urls, { url=customurl })
            addedtolist[customurl] = true
            insitemap[customurl] = true
          end
        end
      end
      
      if string.match(url, "http[s]?%%3A%%2F%%2F.+") then
        for customurlnf in string.gmatch(url, "(http[s]?%%3A%%2F%%2F.+)") do
          customurln = string.gsub(customurlnf, "%%2F", "/")
          customurl = string.gsub(customurln, "%%3A", ":")
          if downloaded[customurl] ~= true and addedtolist[customurl] ~= true then
            table.insert(urls, { url=customurl })
            addedtolist[customurl] = true
          end
        end
      end
      
      for customurl in string.gmatch(html, '"(http[s]?://[^"]+)"') do
        if string.match(customurl, item_value.."%.jux%.com")
          or string.match(customurl, "s3%.amazonaws%.com")
          or string.match(customurl, externaldomain)
          or string.match(customurl, "ajax%.googleapies%.com")
          or string.match(customurl, "fonts%.googleapies%.com")
          or string.match(customurl, "fonts%.gstatic%.com")
          or string.match(customurl, "api%.mixpanel%.com")
          or string.match(customurl, "cdn%.mxpnl%.com")
          or string.match(customurl, "js%-agent%.newrelic%.com")
          or string.match(customurl, "beacon%-1%.newrelic%.com")
          or string.match(customurl, "doubleclick%.net")
          or string.match(customurl, "%.cloudfront%.net")
          or string.match(customurl, "/assets/") then
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
        if string.match(customurlnf, item_value.."%.jux%.com")
          or string.match(customurlnf, "s3%.amazonaws%.com")
          or string.match(customurlnf, externaldomain)
          or string.match(customurlnf, "ajax%.googleapies%.com")
          or string.match(customurlnf, "fonts%.googleapies%.com")
          or string.match(customurlnf, "fonts%.gstatic%.com")
          or string.match(customurlnf, "api%.mixpanel%.com")
          or string.match(customurlnf, "cdn%.mxpnl%.com")
          or string.match(customurlnf, "js%-agent%.newrelic%.com")
          or string.match(customurlnf, "beacon%-1%.newrelic%.com")
          or string.match(customurlnf, "doubleclick%.net")
          or string.match(customurlnf, "%.cloudfront%.net")
          or string.match(customurlnf, "/assets/") then
          local base = "http://"
          local customurl = base..customurlnf
          if downloaded[customurl] ~= true and addedtolist[customurl] ~= true then
            table.insert(urls, { url=customurl })
            addedtolist[customurl] = true
          end
        end
      end
      for customurlnf in string.gmatch(html, '"(/[^/][^"]+)"') do
        local base = string.match(url, "http[s]?://([^/]+)/")
        local customurl = base..customurlnf
        if downloaded[customurl] ~= true and addedtolist[customurl] ~= true then
          table.insert(urls, { url=customurl })
          addedtolist[customurl] = true
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
  
  if status_code == (503 or 500) and not (string.match(url["url"], item_value.."%.jux%.com") or string.match(url["url"], externaldomain)) then
    return wget.actions.EXIT
  elseif status_code >= 500 or
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
