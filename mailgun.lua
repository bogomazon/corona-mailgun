local M = {}
local socket_url = require("socket.url")

-- Project: Mailgun 0.11
-- Description: Send email with mailgun.com API
-- --
-- Date: Mar 22, 2019
-- Updated: Mar 23, 2019
-- Author: Viacheslav Bogomazov

--[[
-- example
local mailgun = require("mailgun")
mailgun.send({
  from = "hansolo@rebelalliance.com",
  to = "luke@jedi.com",
  subject = "Get over it",
  text = "I was first not Greedo."
})
--]]

M.isInitialized = false
local debug = false
local sandboxID
local apiKey

local defaultFrom
local defaultTo
local defaultSubject
local defaultText
local defaultCallback

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
    print("warning: mailgun should need to be configured before usage")
    return
  end
  native.setActivityIndicator( true )
  local data = data or {}
  local from = data.from or defaultFrom
  local to = data.to or defaultTo
  local subject = data.subject or defaultSubject
  local text = data.text or defaultText
  local callback = data.callback or defaultCallback

  local url = "https://api:"..apiKey.."@api.mailgun.net/v3/"..sandboxID..".mailgun.org/messages"

  local params = {}
  local headers = {}

  local body = {
    "from="..tostring(from),
    "to="..tostring(to),
    "subject="..socket_url.escape(subject),
    "text="..socket_url.escape(text),
  }

  params.headers = headers
  params.body = table.concat(body, "&")

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
  network.request( url, "POST", listener, params);

end

return M
