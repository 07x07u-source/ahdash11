$targets = @(
    @{
        Path = 'C:\Users\user\AppData\Local\Temp\flutter_tools.b787ce8'
        AllowedRoot = 'C:\Users\user\AppData\Local\Temp'
    },
    @{
        Path = 'C:\dev\ahdash11\admin\.next'
        AllowedRoot = 'C:\dev\ahdash11\admin'
    },
    @{
        Path = 'C:\dev\ahdash11\admin\node_modules'
        AllowedRoot = 'C:\dev\ahdash11\admin'
    },
    @{
        Path = 'C:\dev\ahdash11\mobile\build'
        AllowedRoot = 'C:\dev\ahdash11\mobile'
    },
    @{
        Path = 'C:\dev\ahdash11\mobile\.dart_tool\flutter_build'
        AllowedRoot = 'C:\dev\ahdash11\mobile\.dart_tool'
    }
)

foreach ($entry in $targets) {
    $target = [System.IO.Path]::GetFullPath($entry.Path)
    $allowedRoot = [System.IO.Path]::GetFullPath($entry.AllowedRoot) +
        [System.IO.Path]::DirectorySeparatorChar
    if (-not $target.StartsWith(
        $allowedRoot,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "Refusing target outside allowed root: $target"
    }

    if ([System.IO.Directory]::Exists($target)) {
        Write-Output "Removing generated cache: $target"
        [System.IO.Directory]::Delete($target, $true)
    }
}
