# Define the path to the ini file
$IniFile = Join-Path -Path $PSScriptRoot -ChildPath "toastarch.ini"

# Function to get the path to the BSArch executable
# Function to get the path to the BSArch executable
function Get-BSArchPath
{
    # If the ini file exists, read the path from it
    if (Test-Path -Path $IniFile) {
        $BSArchPath = Get-Content -Path $IniFile
        # If the path in the ini file is valid, return it
        if (Test-Path -Path $BSArchPath) {
            Write-Host "Found BSArchPath in ini file: $BSArchPath"
            return $BSArchPath
        } else {
            Write-Host "Path in ini file is not valid: $BSArchPath"
        }
    } else {
        Write-Host "Ini file does not exist: $IniFile"
    }

    # Otherwise, display a file chooser dialog to get the path
    $BSArchPath = Get-FileName -initialDirectory "C:\" -filter "BSArch (*.exe)|bsarch.exe"
    if ($BSArchPath -ne "") {
        # If the ini file does not exist, create it
        if (!(Test-Path -Path $IniFile)) {
            New-Item -ItemType File -Path $IniFile -Force
        }
        # Save the path to the ini file
        $BSArchPath | Out-File -FilePath $IniFile -ErrorAction Stop
        Write-Host "Saved BSArchPath to ini file: $BSArchPath"
    } else {
        Write-Host "No path selected in file dialog"
    }
    return $BSArchPath
}

# Function to display a file chooser dialog and return the selected file
function Get-FileName($initialDirectory, $filter)
{   
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = $filter
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}

# Function to unpack a .ba2 file
function Unpack($BSArchPath)
{
    $ba2File = Get-FileName -initialDirectory "C:\" -filter "BA2 files (*.ba2)|*.ba2"
    Write-Host "ba2File: $ba2File" # Debug parameter

    if ($ba2File -ne "") {
        $folderName = [System.IO.Path]::GetFileNameWithoutExtension($ba2File)
        $folderPath = Join-Path -Path ([System.IO.Path]::GetDirectoryName($ba2File)) -ChildPath $folderName
        Write-Host "folderName: $folderName" # Debug parameter
        Write-Host "folderPath: $folderPath" # Debug parameter

        New-Item -ItemType Directory -Force -Path $folderPath
        & $BSArchPath unpack $ba2File $folderPath
    }
}

# Function to pack a directory into a .ba2 file
function Pack($BSArchPath)
{
    $directory = Get-Path -initialDirectory "C:\" -filter "Directories|*.*" -selectFolder $true
    Write-Host "Directory: $directory" # Debug parameter

    if ($directory -ne "") {
        # Ask the user to save the .ba2 file
        [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
        $SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
        $SaveFileDialog.initialDirectory = "C:\"
        $SaveFileDialog.filter = "BA2 files (*.ba2)|*.ba2"
        $SaveFileDialog.ShowDialog() | Out-Null
        $ba2File = $SaveFileDialog.filename
        Write-Host "ba2File: $ba2File" # Debug parameter
        
        Write-Host "1. tes3 (for Morrowind)"
        Write-Host "2. tes4 (for Oblivion)"
        Write-Host "3. fo3 (for Fallout 3)"
        Write-Host "4. fnv (for Fallout: New Vegas)"
        Write-Host "5. tes5 (for Skyrim LE)"
        Write-Host "6. sse (for Skyrim Special Edition)"
        Write-Host "7. fo4 (for Fallout 4 General [Anything but textures!!!])"
        Write-Host "8. fo4dds (for Fallout 4 Textures)"
        $archiveTypeChoice = Read-Host -Prompt "Enter the number of the archive type you want to use"
    $archiveType = if ($archiveTypeChoice -eq "1") { "-tes3" } elseif ($archiveTypeChoice -eq "2") { "-tes4" } elseif ($archiveTypeChoice -eq "3") { "-fo3" } elseif ($archiveTypeChoice -eq "4") { "-fnv" } elseif ($archiveTypeChoice -eq "5") { "-tes5" } elseif ($archiveTypeChoice -eq "6") { "-sse" } elseif ($archiveTypeChoice -eq "7") { "-fo4" } elseif ($archiveTypeChoice -eq "8") { "-fo4dds" } else { $null }

    if ($null -ne $archiveType) {
        $compression = ""
        if ($archiveType -eq "-fo4dds") {
            $compression = "-z"
        } elseif ($archiveType -eq "-fo4") {
            $compressChoice = ""
            while ($compressChoice -ne "y" -and $compressChoice -ne "n") {
                $compressChoice = Read-Host -Prompt "Do you want to compress the pack? SELECT NO (N) IF THERE ARE SOUND FILES BEING PACKED (y/n)"
                if ($compressChoice -eq "y") {
                    $compression = "-z"
                } elseif ($compressChoice -ne "n") {
                    Write-Host "Y OR N.... **Facepalm**."
                }
            }
        }
        & $BSArchPath pack $directory $ba2File $archiveType $compression -mt -share
    } else {
        Write-Host "Invalid archive type. Please enter a number between 1 and 8."
        }
    }
}
function Get-Path($initialDirectory, $filter, $selectFolder)
{   
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
    if ($selectFolder) {
        $Dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $Dialog.ShowDialog() | Out-Null
        return $Dialog.SelectedPath
    } else {
        $Dialog = New-Object System.Windows.Forms.OpenFileDialog
        $Dialog.initialDirectory = $initialDirectory
        $Dialog.filter = $filter
        $Dialog.ShowDialog() | Out-Null
        return $Dialog.filename
    }
}

# Main script
$BSArchPath = Get-BSArchPath
if ($BSArchPath -ne "") {
    Write-Host "1. Pack"
    Write-Host "2. Unpack"
    $action = Read-Host -Prompt "Thanks for using CannibalToasts BSArch Packing script!. Pick a number"
    if ($action -eq "2") {
        Unpack -BSArchPath $BSArchPath
    } elseif ($action -eq "1") {
        Pack -BSArchPath $BSArchPath
    } else {
        Write-Host "Invalid action. Please enter 1 or 2."
    }
}