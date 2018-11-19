'complete:
Sub SendToTicket()

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

Sub SendEval()
    Set newItem = Application.CreateItemFromTemplate("C:\Users\user\AppData\Roaming\Microsoft\Templates\Evaluation Data Summary.oft")
    newItem.Display
    Set newItem = Nothing
End Sub

Sub SendSFTP()
    Set newItem = Application.CreateItemFromTemplate("C:\Users\user\AppData\Roaming\Microsoft\Templates\company SFTP Account.oft")
    newItem.Display
    Set newItem = Nothing
End Sub

'end of complete macros




C:\Users\user\AppData\Roaming\Microsoft\Templates\Evaluation Data Summary.oft

Sub MakeItem()
	Set newItem = Application.CreateItemFromTemplate("C:\Users\user\AppData\Roaming\Microsoft\Templates\Evaluation Data Summary.oft")
	newItem.Display
	Set newItem = Nothing
End Sub

Dim template As String
 
Sub OpenTemplate1()
template = "C:\Users\Diane\Templates\template1.oft"
MakeItem
End Sub
 
Sub OpenTemplate2()
template = "C:\Users\Diane\Templates\email.oft"
MakeItem
End Sub
 
Sub MakeItem()
Set newItem = Application.CreateItemFromTemplate(template)
newItem.Display
Set newItem = Nothing
End Sub

Sub AddAttachment ()
Dim newItem as Outlook.MailItem
Set newItem = Application.CreateItem("C:\path\template.oft")
newItem.Attachments.Add "C:\myfile.doc"
newItem.Display
End Sub

Public Sub OpenPublishedForm()
   Dim Items As Outlook.Items
   Dim Item As Object
   Set Items = Application.ActiveExplorer.CurrentFolder.Items
   Set Item = Items.Add("ipm.note.name")
   Item.Display
 End Sub