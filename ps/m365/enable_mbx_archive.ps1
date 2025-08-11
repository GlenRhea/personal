$tenantid = "GUID HERE"

Connect-ExchangeOnline -TenantID $tenantid

Get-Mailbox -ResultSize Unlimited | Enable-Mailbox -Archive 