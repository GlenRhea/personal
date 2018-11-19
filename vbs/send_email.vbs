'sendEmail "Glen Rhea <glen.rhea@arkansas.gov>", "Glen Rhea <glen.rhea@arkansas.gov>", "hi", "testing", ""
'sendEmail "glen.rhea@arkansas.gov", "glen.rhea@arkansas.gov", "hi", "testing", ""
Set objArgs = WScript.Arguments.Unnamed

'check for commandline args, else prompt user
Select Case objArgs.Count
    Case 2
        sendEmail "smtpuser@company.com", "user@company.com", objArgs.Item(0), objArgs.Item(1), "" 'objArgs.Item(1)
    Case Else
	wscript.echo("Usage: send_email.vbs subject body")
        wscript.quit(1)
End Select

'sendEmail "smtpuser@company.com", "user@company.com", "test", "123", "" 'objArgs.Item(1)

Sub sendEmail(sentfrom, sendto, subject, textBody, attachment)
	Set objMessage = CreateObject("CDO.Message")
	objMessage.Subject = subject
	objMessage.Sender = sentfrom
	'need this to display "from" address, doesn't use the .sender address
	objMessage.From = sentfrom
	objMessage.To = sendTo
	objMessage.Cc = SendToCC
	objMessage.TextBody = TextBody
	'The line below shows how to send using HTML included directly in your script
	'objMessage.HTMLBody = "<h1>This is some sample message html.</h1>" 

	'objMessage.AddAttachment Attachment 'attach the output file
	'objMessage.AddAttachment outputAttachment1 'attach the no acct file

	'==This section provides the configuration information for the remote SMTP server.
	'==Normally you will only change the server name or IP.

	objMessage.Configuration.Fields.Item _
	("http://schemas.microsoft.com/cdo/configuration/sendusing") = 2
	
	'Name Or IP of Remote SMTP Server
	objMessage.Configuration.Fields.Item _
	("http://schemas.microsoft.com/cdo/configuration/smtpserver") = "smtpserver"

	'Server port (typically 25)
	objMessage.Configuration.Fields.Item _
	("http://schemas.microsoft.com/cdo/configuration/smtpserverport") = 25

	objMessage.Configuration.Fields.Update

	'==End remote SMTP server configuration section==

	objMessage.Send

	WScript.Echo "Email Sent"
End sub 'sendEmail