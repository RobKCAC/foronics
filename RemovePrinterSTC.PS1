# Set the name of the printer you want to remove
$printerName = "NPIE7674C"

# Check if the printer exists
$printer = Get-Printer -Name $printerName -ErrorAction SilentlyContinue

if ($null -ne $printer) {
    # Remove the printer
    Remove-Printer -Name $printerName
    Write-Host "Printer '$printerName' has been removed successfully."
} else {
    Write-Host "Printer '$printerName' not found."
}
