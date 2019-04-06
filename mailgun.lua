local M = {}
local socket_url = require("socket.url")

-- Project: Mailgun 0.12
-- Description: Send email with mailgun.com API
-- --
-- Date: Mar 22, 2019
-- Updated: Apr 6, 2019
-- Author: Viacheslav Bogomazov

M.isInitialized = false
local debug = false
local sandboxID
local apiKey

local defaultFrom
local defaultTo
local defaultSubject
local defaultText
local defaultCallback
local multipartEncode

function M.init(params)
  M.isInitialized = false
  local params = params or {}

  -- sandbox id and api key from mailgun console
  if (type(params.sandboxID) ~= "string") then
    print("warning: mailgun plugin failed to initialize. 'sandboxID' parameter is required. You can find it at mailgun dashboard")
    return
  end

  if (type(params.apiKey) ~= "string") then
    print("warning: mailgun plugin failed to initialize. 'apiKey' parameter is required")
    return
  end

  sandboxID = params.sandboxID -- "sandboxXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  apiKey = params.apiKey -- "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX-XXXXXXXX-XXXXXXXX"

  -- default user email if missing
  defaultFrom = params.defaultFrom or "crab@test.com"
  -- recepient email (only confirmed emails are working in sandbox)
  defaultTo = params.defaultTo or "yourmail@test.com"
  -- email subject
  defaultSubject = params.defaultSubject or "Hello, World!"
  -- email body
  defaultText = params.defaultText or "This is a test email from Mailgun."
  -- debug mode
  debug = params.debug

  -- default confirmation callback
  defaultCallback = params.defaultCallback or function()
    native.showAlert("Mailgun", "Your message has been sent successfully.", {"Thanks"})
  end

  M.isInitialized = true
end

function M.send(data)
  if (not M.isInitialized) then
    print("warning: mailgun needs to be configured before being used")
    return
  end
  native.setActivityIndicator( true )
  local data = data or {}
  local from = tostring(data.from or defaultFrom)
  local to = tostring(data.to or defaultTo)
  local subject = data.subject or defaultSubject
  local text = data.text or defaultText
  local callback = data.callback or defaultCallback

  local url = "https://api:"..apiKey.."@api.mailgun.net/v3/"..sandboxID..".mailgun.org/messages"

  local params = {}
  local headers = {}

  local body
  if (data.attachments and #data.attachments > 0) then
    local mime = require("mime")
    local toEncode = {
      to = to,
      from = from,
      subject = subject,
      text = text
    }

    for i = 1, #data.attachments do
      local attachment = data.attachments[i]
      local baseDir = attachment.baseDir or system.DocumentsDirectory
      local path = system.pathForFile(attachment.filename, baseDir)
      if (path == nil) then
        local warningMessage = "warning: attachment path not found: "
        print(warningMessage, attachment.filename)
        toEncode.text = toEncode.text.."\n\n"..warningMessage..tostring(attachment.filename)
      else
        local file = io.open( path , "rb" )
        if (file == nil) then
          local warningMessage = "warning: attachment file not found: "
          print(warningMessage, attachment.filename)
          toEncode.text = toEncode.text.."\n\n"..warningMessage..tostring(attachment.filename)
        else
          local content = file:read("*a")
          file:close()
          toEncode["attachment" .. i] = {
            key = "attachment",
            name = attachment.filename,
            data = mime.b64(content),
            content_transfer_encoding = "base64"
          }
        end
      end
    end
    local boundary
    body, boundary = multipartEncode(toEncode)
    headers["Content-Type"] = "multipart/form-data; charset=utf-8; boundary=" .. boundary
  end

  if (body == nil) then
    body = {
      "from="..tostring(from),
      "to="..tostring(to),
      "subject="..socket_url.escape(subject),
      "text="..socket_url.escape(text),
    }
    body = table.concat(body, "&")
  end

  params.headers = headers
  params.body = body

  local listener = function(e)
    native.setActivityIndicator( false )
    if debug then
      print("mailgun:", e.status)
      --print_r(e) -- uncomment to print event contents
    end
    if e.status == 200 then
      callback()
    else
      native.showAlert( "Mailgun error", "Error status: "..tostring(e.status) .. "\n" .. tostring(e.response), {"ok"} )
    end

  end

  if debug then
    print("mailgun: sending post request to", to, ", subject = ", subject)
  end
  network.request(url, "POST", listener, params);
end


--this part of code taken from https://github.com/catwell/lua-multipart-post
--[[
Copyright (C) 2012-2013 by Moodstocks SAS
Copyright (C) 2014-2016 by Pierre Chapuis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]

--[[
  modifications: allow using v.key instead of parent table key for encode
  because we want to post multiple attachment files in body
]]

local fmt = function(p, ...)
  if select('#', ...) == 0 then
      return p
  else return string.format(p, ...) end
end

local tprintf = function(t, p, ...)
  t[#t+1] = fmt(p, ...)
end

local append_data = function(r, k, data, extra)
  tprintf(r, "content-disposition: form-data; name=\"%s\"", k)
  if extra.filename then
      tprintf(r, "; filename=\"%s\"", extra.filename)
  end
  if extra.content_type then
      tprintf(r, "\r\ncontent-type: %s", extra.content_type)
  end
  if extra.content_transfer_encoding then
      tprintf(
          r, "\r\ncontent-transfer-encoding: %s",
          extra.content_transfer_encoding
      )
  end
  tprintf(r, "\r\n\r\n")
  tprintf(r, data)
  tprintf(r, "\r\n")
end

local gen_boundary = function()
  local t = {"BOUNDARY-"}
  for i=2,17 do t[i] = string.char(math.random(65, 90)) end
  t[18] = "-BOUNDARY"
  return table.concat(t)
end

multipartEncode = function(t, boundary)
  boundary = boundary or gen_boundary()
  local r = {}
  local _t
  for k,v in pairs(t) do
      tprintf(r, "--%s\r\n", boundary)
      _t = type(v)
      if _t == "string" then
          append_data(r, k, v, {})
      elseif _t == "table" then
          assert(v.data, "invalid input")
          local extra = {
              filename = v.filename or v.name,
              content_type = v.content_type or v.mimetype
                  or "application/octet-stream",
              content_transfer_encoding = v.content_transfer_encoding or "binary",
          }
          append_data(r, v.key or k, v.data, extra)
      else error(string.format("unexpected type %s", _t)) end
  end
  tprintf(r, "--%s--\r\n", boundary)
  return table.concat(r), boundary
end

return M