$outputFile = ".\output.txt"

Get-ChildItem -Path C:\Windows -Recurse -File | Where-Object {
    $acl = Get-Acl $_.FullName
    $userAccess = $acl.Access | Where-Object {
        $_.IdentityReference -match "Users" -and $_.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::Write
    }
    $userAccess -ne $null
} | Select-Object FullName | Out-File -FilePath $outputFile
