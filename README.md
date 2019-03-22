# corona-mailgun
Send email using Mailgun API in your Corona SDK app

Example request: 

```
local mailgun = require("mailgun")
mailgun.send({
  from = "hansolo@rebelalliance.com",
  to = "luke@jedi.com",
  subject = "Get over it",
  text = "I was first not Greedo."
})
```
