$ErrorActionPreference = 'Stop'
robocopy "C:\Program Files (x86)\World of Warcraft\_forever_\WTF" "$PSScriptRoot\WTF" /MIR
# Robocopy uses 0 through 7 for successful mirror operations.
if ($LASTEXITCODE -ge 8) { exit $LASTEXITCODE }
exit 0
