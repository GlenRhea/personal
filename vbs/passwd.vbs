'quick and dirty password generator

'start main sub
Main()

sub Main()
	Dim length
	length = ""
	'get input for length of the password
	length = InputBox("Please enter the password length (min 8, max 100):","Password Generator","8")
	'check for errors in input
	if length = "" Then 
		'user clicked cancel
		wscript.quit()
	Elseif Not IsNumeric(length) Then
		'start over if so
		MsgBox("Incorrect entry, try again.")
		Main()
	Elseif length > 100 Or length < 8 Then
		'start over if so
		MsgBox("Incorrect entry, try again.")
		Main()
	Else
	'use an inputbox so they user can copy/paste their password
	answer = inputbox("Copy and paste your password below.","Password Generator",genPasswd(length))
	end If
end sub 'Main

function genPasswd(input)
	'initialize the random function
	Randomize
	'create each digit up to the length specified
	For i = 1 To input
		'uses most of the ascii characters, even spaces!
		digit = Int((95 * Rnd) + 32)
    final = final & chr(digit)
	Next
	'return password
	genPasswd = final
End function 'genPasswd
