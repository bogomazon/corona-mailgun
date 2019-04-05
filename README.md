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

Send email with attachments:

```
mailgun.send({
  from = "hansolo@rebelalliance.com",
  to = "luke@jedi.com",
  subject = "Get over it",
  text = "I was first not Greedo.",
  attachments = {
	-- default value for baseDir is system.ResourceDirectory
    {baseDir = system.DocumentsDirectory, filename = "awesome image.png"},
    {baseDir = system.DocumentsDirectory, filename = "few notes.txt"}
  }
})
```