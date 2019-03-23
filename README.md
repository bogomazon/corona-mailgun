# corona-mailgun
Send email using Mailgun API in your Corona SDK app

Example request: 

```
local mailgun = require("mailgun")

--init with your sandbox data
mailgun.init({
	sandboxID = "sandboxXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", --required
	apiKey = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX-XXXXXXXX-XXXXXXXX", --required
	defaultTo = "default@test.com", --optional
	defaultFrom = "sender@test.com", --optional
	defaultSubject = "subject", --optional
	defaultText = "Lorem ipsum", --optional
	defaultCallback = function() print("Message sent!") end, --optional
	debug = true --optional
})

--send email
mailgun.send({
  from = "hansolo@rebelalliance.com",
  to = "luke@jedi.com",
  subject = "Get over it",
  text = "I was first not Greedo."
})
```
