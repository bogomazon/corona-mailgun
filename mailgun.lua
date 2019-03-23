local M = {}

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

local debug = false
local sandboxID
local apiKey

local defaultFrom
local defaultTo
local defaultSubject
local defaultText
local defaultCallback

function M.init(params)
  local params = params or {}

  -- sandbox id and api key from mailgun console
  sandboxID = params.sandboxID or "sandboxXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  apiKey = params.apiKey or "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX-XXXXXXXX-XXXXXXXX"

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
  
end

function M.send(data)
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

  local body = ""
  body = "from="..from
  body = body.."&to="..to
  body = body.."&subject="..subject
  body = body.."&text="..text

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
      native.showAlert( "Mailgun error", "Error: "..tostring(e.status), {"ok"} )
    end

  end

  network.request( url, "POST", listener, params);

end

return M
