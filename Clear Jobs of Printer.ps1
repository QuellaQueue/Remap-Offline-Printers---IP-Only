$PrinterName = "{[printer_name]}"

Try{
    Get-PrintJob -PrinterName $Printername | ForEach-Object { Remove-PrintJob -PrinterName $_.PrinterName -ID $_.ID }
}catch{}