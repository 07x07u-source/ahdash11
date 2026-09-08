$tempRoot = [System.IO.Path]::GetFullPath('C:\Users\user\AppData\Local\Temp') +
    [System.IO.Path]::DirectorySeparatorChar

$targets = @(
    'C:\Users\user\AppData\Local\Temp\flutter_tools.2aae0e72',
    'C:\Users\user\AppData\Local\Temp\ahdash11-pg-qa-20260828',
    'C:\Users\user\AppData\Local\Temp\ahdash11-pg-parser',
    'C:\Users\user\AppData\Local\Temp\ahdash11-plpgsql-parser',
    'C:\Users\user\AppData\Local\Temp\ahdash-thmanyah-inspect-83cf30616a83498f8f2d78f5b02a2f86',
    'C:\Users\user\AppData\Local\Temp\ahdash-pglast',
    'C:\Users\user\AppData\Local\Temp\ahdash11-pglast-check',
    'C:\Users\user\AppData\Local\Temp\ahdash-pglast-pg17'
    'C:\Users\user\AppData\Local\Temp\flutter_tools.7eb38075'
    'C:\Users\user\AppData\Local\Temp\flutter_tools.5682f4b9'
    'C:\Users\user\AppData\Local\Temp\flutter_tools.5456e532'
    'C:\Users\user\AppData\Local\Temp\ahdash-pgsql-parser-20260831'
)

foreach ($candidate in $targets) {
    $target = [System.IO.Path]::GetFullPath($candidate)
    if (-not $target.StartsWith(
        $tempRoot,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "Refusing target outside Temp: $target"
    }

    if ([System.IO.Directory]::Exists($target)) {
        Write-Output "Removing temporary directory: $target"
        [System.IO.Directory]::Delete($target, $true)
    }
}
