param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("v1", "v2", "minimal", "v3", "off", "fps")]
    [string]$Variant,

    # with -Variant fps: target fps (60, 90, 120...). Installs patches\mirai-<Fps>fps.ips AND
    # sets refresh_scale = Fps/59.8281 in the TOP-LEVEL section of Zakuro's settings.toml.
    # Both must match or the game runs fast/slow as a whole.
    [int]$Fps = 0
)

$root = "C:\Users\Kuro\Documents\Mirai"
$mods = "$env:APPDATA\zakuro\mods\0004000000148C00"
$target = "$mods\code.ips"
$settings = "$env:APPDATA\zakuro\settings.toml"
New-Item -ItemType Directory -Force $mods | Out-Null

# refresh_scale MUST live in the top-level section. Appending at the end of the file would
# put it after [per_game], inside a game's settings table; that fails to parse, zakuro falls
# back to defaults (knob 1.0) and the fps patch then runs fast/slow. Insert before [keys].
function Set-RefreshScale([double]$value) {
    $lines = [System.Collections.Generic.List[string]](Get-Content $settings)
    $lines.RemoveAll({ param($l) $l -match '^\s*refresh_scale\s*=' })
    $top = $lines.FindIndex({ param($l) $l -match '^\[' })
    if ($top -lt 0) { $lines.Add("refresh_scale = $value") }
    else { $lines.Insert($top, "refresh_scale = $value") }
    Set-Content $settings $lines
}

function Test-SettingsToml {
    python -c "import tomllib,sys; tomllib.load(open(r'$settings','rb')); print('settings ok')" 2>$null
    return $LASTEXITCODE -eq 0
}

if ($Variant -eq "fps") {
    if ($Fps -lt 30) { Write-Output "give -Fps (examples: 60, 90, 120)"; exit 1 }
    python "$root\tools\make-fps-ips.py" $Fps
    if ($LASTEXITCODE -ne 0) { exit 1 }
    $scale = [math]::Round($Fps / (268111856.0 / 4481136.0), 6)
    Copy-Item "$root\patches\mirai-$($Fps)fps.ips" $target -Force
    Copy-Item $settings "$settings.bak" -Force
    Set-RefreshScale $scale
    if (-not (Test-SettingsToml)) {
        Copy-Item "$settings.bak" $settings -Force
        Write-Output "settings.toml would not parse, restored the backup, NOT switching. report this."
        exit 1
    }
    Write-Output "installed $Fps fps patch + refresh_scale = $scale"
    Write-Output "launch with run-mirai.cmd (the standard launcher at the repo root)"
    exit 0
}

switch ($Variant) {
    "v1" { Copy-Item "$root\patches\mirai-60fps-prototype-v1.ips" $target -Force }
    "v2" { Copy-Item "$root\patches\mirai-60fps-prototype-v2.ips" $target -Force }
    "minimal" { Copy-Item "$root\patches\mirai-60fps-minimal.ips" $target -Force }
    "v3" { Copy-Item "$root\patches\mirai-60fps-v3-camera.ips" $target -Force }
    "off" { if (Test-Path $target) { Remove-Item $target -Force } }
}
Copy-Item $settings "$settings.bak" -Force
# the classic variants are tuned for the stock ~59.83 Hz screen rate: reset the knob
Set-RefreshScale 1.0

$desc = @{
    off = "stock game, 30 fps, nothing patched"
    minimal = "60 Hz loop + 30.0f step halved: 2 records"
    v1 = "60 Hz loop + 30.0f step + the findings doc's nine 3e-5 copies: 11 records"
    v2 = "v1 plus the second real 3e-5 copy at 0x0038B198: 12 records"
    v3 = "v2 + the camera-cut floor fix: the current best 60 fps build"
}[$Variant]

if (Test-Path $target) {
    $size = (Get-Item $target).Length
    Write-Output "installed $Variant ($size bytes): $desc"
}
else {
    Write-Output "installed $Variant : $desc"
}
Write-Output "launch with run-mirai.cmd"
