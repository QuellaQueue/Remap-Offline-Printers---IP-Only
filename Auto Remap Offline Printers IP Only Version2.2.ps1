try{ 

    #THIS VERSION ONLY WORKS FOR LOCAL IP MAPPINGS, WSD MAPPINGS ARE IGNORED

    #Changelog Ver2: No longer unintentionally warns of excessive ports on every single use
    #Changelog Ver2.2: No longer restarts spooler on every run. Only resets it when necessary to remap a port.
    #Changelog Ver2.2: Added additional notifications so it's easier to track if steps are being skipped.
    #Collects the list of Currently Offline Printers and resets the print spooler
    #to free up the ports
    
    $OfflinePrinters = get-printer | Where-Object { $_.PrinterStatus -eq 'Offline' }
    
    foreach ($currentprinter in $OfflinePrinters){
        $pName = $currentprinter.name    
        $portName = $currentprinter.PortName
        $portDescription = (get-printerport -name $portName).description
        $portNum
        #Checks if the printer is on IP
        if($portDescription -like "*TCP/IP*"){ 
            Write-Output "Remapping $pName"
            $portNum = (get-printerport -name $portName).PrinterHostAddress

            #Clears Printer Queue
            Get-PrintJob -PrinterName $pName | ForEach-Object { Remove-PrintJob -PrinterName $_.PrinterName -ID $_.ID }
            #Removes Printer and Port
            Write-Output "Attempting to remove printer " + $pName
            Remove-Printer -Name $pName -ErrorAction SilentlyContinue
            try{
                Remove-printerPort -name $portName -ErrorAction Continue
            }catch{
                try{
                    Write-Output "Could not delete port. Trying Again."
                    restart-service -name Spooler                
                    Remove-printerPort -name $portName -ErrorAction SilentlyContinue
                }catch{
                    
                    $portName = $portname + "_1"
                    Remove-printerPort -name $portName -ErrorAction SilentlyContinue
                    Write-Output "Multiple in-use ports of the same IP address exist for this printer. Continuing remapping, but please delete the extra ports."
                }
            }
            #Adds Printer and Port Back
            Write-Output "Attempting to readd printer " + $pName
            Add-printerport -Name $portName -printerhostaddress $portNum -ErrorAction SilentlyContinue
            Add-Printer -name $pName -DriverName "Microsoft IPP Class Driver" -portname $portName -ErrorAction continue
            try{
                Set-printer -name $pName -drivername "HP Universal Printing PCL 6" 
            }catch{ Write-Output "Could not set driver to Duly Standard Driver. Please add HP Universal Printing PCL 6 driver to this computer."}
        }
        else{
            Write-Output "$pName is Not a TCP/IP Printer mapping. Skipping this printer."
            
            ##ADD WSD REMAPPING HERE
        }

    }
    if($OfflinePrinters -eq $null){ Write-Output "No Offline Printers Detected. Please check that the printer is not in an Error state, and is already mapped to this device."}
}catch{
    Write-Error "Unexpected Error Occurred. Error: $_" 
}finally{
    Write-Output "No further action needed. Exiting."
}