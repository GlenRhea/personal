Get-MailboxDatabase "Database Name" | Get-MailboxStatistics | Sort totalitemsize -desc | ft displayname, totalitemsize, itemcount

Get-MailboxDatabase "Mailbox Database 0004745584" | Get-MailboxStatistics | Sort totalitemsize -desc | ft displayname, totalitemsize, itemcount
