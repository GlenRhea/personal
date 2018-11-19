Sub Complete()

' Send Completed Message to support

On Error Resume Next

Dim oApp As Outlook.Application
Dim objFolder As Outlook.MAPIFolder
Set oApp = New Outlook.Application
Set objNS = Application.GetNamespace("MAPI")
Set objInbox = objNS.GetDefaultFolder(olFolderInbox)
Set objFolder = objInbox.Folders("Helpdesk")
Dim oEmail As Outlook.MailItem

'Require that this procedure be called only when a message is selected
If Application.ActiveExplorer.Selection.Count = 0 Then
    Exit Sub
End If

For Each objItem In Application.ActiveExplorer.Selection
    If objFolder.DefaultItemType = olMailItem Then
        If objItem.Class = olMail Then
            Response = MsgBox("Forward message (" + Item.Subject + ") to Appended Subject")
            Set myForward = objItem.Forward
            myForward.Subject = "APPENDED SUBJECT - " + objItem.Subject + ""
            myForward.Recipients.Add "John Doe <jdoe@someaddress.com>"
            myForward.Send
        End If
    End If
Next

End Sub

Sub Complete()

' Send Completed Message to support

On Error Resume Next

Dim oApp As Outlook.Application
Dim objFolder As Outlook.MAPIFolder
Set oApp = New Outlook.Application
Set objNS = Application.GetNamespace("MAPI")
Set objInbox = objNS.GetDefaultFolder(olFolderInbox)
Set objFolder = objInbox.Folders("Helpdesk")
Dim oEmail As Outlook.MailItem

'Require that this procedure be called only when a message is selected
If Application.ActiveExplorer.Selection.Count = 0 Then
    Exit Sub
End If

For Each objItem In Application.ActiveExplorer.Selection
    If objFolder.DefaultItemType = olMailItem Then
        If objItem.Class = olMail Then
            ' Response = MsgBox("Forward message (" + Item.Subject + ") to Appended Subject")
            response = InputBox( _
                prompt:="Type in the number of the ticket you want to append to", _
                Title:="Input Ticket Number", _
                Default:="Input ticket number here")
            'Error handling
            If Len(response) = 0 Then
                MsgBox "No ticket number entered!"
                Exit Sub
            ElseIf IsNumeric(response) Then
                If CStr(CLng(response)) = response Then
                    Set myForward = objItem.Forward
                    myForward.Subject = "[ ##" + response + "## : " + objItem.Subject + " ]"
                    myForward.Recipients.Add "Support <support@company.com>"
                    myForward.Send
                Else
                    MsgBox "Please enter a ticket NUMBER!"
                    Exit Sub
                End If
            Else
                MsgBox "Please enter a ticket NUMBER!"
                Exit Sub
            End If
        End If
    End If
Next

End Sub
