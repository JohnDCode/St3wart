# Define the directory path to baseline
$directoryPath = "C:/Windows/system32/"

# Define the output CSV file path
$outputFilePath = "./export.csv"

# Initialize an empty array to store file information
$fileInfoArray = @()

# Get all files in the specified directory
$files = Get-ChildItem -Path $directoryPath -File -Force

# Loop through each file and calculate its hash
foreach ($file in $files) {
    $filePath = $file.FullName
    $hash = Get-FileHash -Path $filePath -Algorithm SHA256
    $fileInfo = [PSCustomObject]@{
        FileName = $file.Name
        FilePath = $filePath
        Hash = $hash.Hash
    }
    $fileInfoArray += $fileInfo
}

# Export the file information to a CSV file
$fileInfoArray | Export-Csv -Path $outputFilePath -NoTypeInformation

Write-Host "File hash information has been exported to $outputFilePath."
