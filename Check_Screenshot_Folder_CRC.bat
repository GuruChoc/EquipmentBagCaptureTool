@echo off
setlocal EnableExtensions

echo.
echo ============================================
echo   Screenshot Folder Checker + CRC32
echo ============================================
echo.

set /p "FOLDER=Enter screenshot folder path: "

if not exist "%FOLDER%\" (
    echo.
    echo ERROR: Folder does not exist.
    echo %FOLDER%
    pause
    exit /b 1
)

set "PS1=%TEMP%\Screenshot_Check_CRC_%RANDOM%_%RANDOM%.ps1"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$lines = Get-Content -LiteralPath '%~f0';" ^
  "$marker = [Array]::IndexOf($lines, '#POWERSHELL#');" ^
  "if ($marker -lt 0) { exit 2 };" ^
  "$lines[($marker + 1)..($lines.Count - 1)] | Set-Content -LiteralPath '%PS1%' -Encoding UTF8"

if errorlevel 1 (
    echo.
    echo ERROR: Could not prepare the CRC checker.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -Folder "%FOLDER%"
set "RC=%ERRORLEVEL%"

del "%PS1%" >nul 2>&1

echo.
if "%RC%"=="0" (
    echo Finished.
    echo Report created in:
    echo %FOLDER%\Screenshot_Check_Report_CRC.txt
) else (
    echo Checker finished with error code %RC%.
)

echo.
pause
exit /b %RC%

#POWERSHELL#
param(
    [Parameter(Mandatory=$true)]
    [string]$Folder
)

$ErrorActionPreference = 'Stop'

function Get-Crc32 {
    param([Parameter(Mandatory=$true)][string]$Path)

    [uint32]$crc = 0xFFFFFFFF
    $table = New-Object 'System.UInt32[]' 256

    for ($i = 0; $i -lt 256; $i++) {
        [uint32]$c = $i
        for ($j = 0; $j -lt 8; $j++) {
            if (($c -band 1) -ne 0) {
                $c = [uint32](0xEDB88320 -bxor ($c -shr 1))
            } else {
                $c = [uint32]($c -shr 1)
            }
        }
        $table[$i] = $c
    }

    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $buffer = New-Object byte[] 65536
        while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            for ($k = 0; $k -lt $read; $k++) {
                $idx = (($crc -bxor $buffer[$k]) -band 0xFF)
                $crc = [uint32](($crc -shr 8) -bxor $table[$idx])
            }
        }
    }
    finally {
        $stream.Dispose()
    }

    $crc = [uint32]($crc -bxor 0xFFFFFFFF)
    '{0:X8}' -f $crc
}

$Folder = (Resolve-Path -LiteralPath $Folder).Path
$Report = Join-Path $Folder 'Screenshot_Check_Report_CRC.txt'

$allFiles = Get-ChildItem -LiteralPath $Folder -File |
    Where-Object { $_.Name -ne 'Screenshot_Check_Report_CRC.txt' }

$imageFiles = $allFiles |
    Where-Object { $_.Extension.ToLowerInvariant() -in @('.png', '.jpg', '.jpeg') } |
    Sort-Object LastWriteTime, Name

$pngCount  = @($imageFiles | Where-Object { $_.Extension -ieq '.png' }).Count
$jpgCount  = @($imageFiles | Where-Object { $_.Extension -ieq '.jpg' }).Count
$jpegCount = @($imageFiles | Where-Object { $_.Extension -ieq '.jpeg' }).Count

$rows = foreach ($file in $imageFiles) {
    [pscustomobject]@{
        Time  = $file.LastWriteTime
        Name  = $file.Name
        Bytes = $file.Length
        CRC32 = Get-Crc32 -Path $file.FullName
    }
}

$duplicateGroups = @(
    $rows |
    Group-Object CRC32 |
    Where-Object { $_.Count -gt 1 } |
    Sort-Object Name
)

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('Screenshot Folder Check + CRC32')
$lines.Add('===============================')
$lines.Add('')
$lines.Add("Folder: $Folder")
$lines.Add("Date checked: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$lines.Add('')
$lines.Add('SUMMARY')
$lines.Add('-------')
$lines.Add("Total files (excluding this report): $($allFiles.Count)")
$lines.Add("PNG files: $pngCount")
$lines.Add("JPG files: $jpgCount")
$lines.Add("JPEG files: $jpegCount")
$lines.Add("Total image files: $($imageFiles.Count)")
$lines.Add("Duplicate CRC32 groups: $($duplicateGroups.Count)")
$lines.Add('')

if ($imageFiles.Count -gt 0) {
    $oldest = $imageFiles | Sort-Object LastWriteTime | Select-Object -First 1
    $newest = $imageFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1

    $lines.Add('OLDEST IMAGE')
    $lines.Add('------------')
    $lines.Add("$($oldest.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))  $($oldest.Name)")
    $lines.Add('')
    $lines.Add('NEWEST IMAGE')
    $lines.Add('------------')
    $lines.Add("$($newest.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))  $($newest.Name)")
    $lines.Add('')
}

$lines.Add('IMAGE DETAILS - CHRONOLOGICAL')
$lines.Add('-----------------------------')
$lines.Add('Date/Time             Bytes       CRC32      Filename')
$lines.Add('-------------------  ----------  --------  ----------------------------------------')

foreach ($row in $rows) {
    $lines.Add(
        ('{0}  {1,10}  {2}  {3}' -f
            $row.Time.ToString('yyyy-MM-dd HH:mm:ss'),
            $row.Bytes,
            $row.CRC32,
            $row.Name)
    )
}

$lines.Add('')
$lines.Add('DUPLICATE CRC32 CHECK')
$lines.Add('---------------------')

if ($duplicateGroups.Count -eq 0) {
    $lines.Add('No duplicate CRC32 values found.')
} else {
    $lines.Add('WARNING: Files below have identical CRC32 values.')
    $lines.Add('Identical CRC32 normally means the files are byte-for-byte identical.')
    $lines.Add('')

    foreach ($group in $duplicateGroups) {
        $lines.Add("CRC32: $($group.Name)  Count: $($group.Count)")
        foreach ($item in $group.Group) {
            $lines.Add("  $($item.Time.ToString('yyyy-MM-dd HH:mm:ss'))  $($item.Name)  ($($item.Bytes) bytes)")
        }
        $lines.Add('')
    }
}

$lines.Add('')
$lines.Add('NOTES')
$lines.Add('-----')
$lines.Add('- CRC32 is useful for spotting exact duplicate image files.')
$lines.Add('- Matching CRC32 values strongly indicate identical file contents.')
$lines.Add('- Different CRC32 values do not prove the screenshots show different equipment.')
$lines.Add('- The report itself is excluded from the file/image counts.')

$lines | Set-Content -LiteralPath $Report -Encoding UTF8

Write-Host ''
Write-Host "Image files found: $($imageFiles.Count)"
Write-Host "Duplicate CRC32 groups: $($duplicateGroups.Count)"
Write-Host ''
Write-Host "Report: $Report"
exit 0
