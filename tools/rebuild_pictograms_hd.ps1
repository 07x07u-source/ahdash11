param(
    [string]$GeneratedRoot = "C:\Users\user\.codex\generated_images\01a043ca-1faa-7811-bb22-fb13d14c850d",
    [string]$OutputRoot = "C:\dev\ahdash11\mobile\assets\pictograms"
)

$ErrorActionPreference = 'Stop'

$assets = [ordered]@{
    'exec-3464074d-6590-4921-b268-163ab5c19504.png' = 'ahdash_win.png'
    'exec-e5776709-05f3-4ae1-b56f-66220f3af669.png' = 'ahdash_champion.png'
    'exec-80bbd9bd-7fbd-4ed7-aa92-1bc292d242df.png' = 'ahdash_tournament.png'
    'exec-f28cf707-50ba-4d27-ad08-c9f982f93215.png' = 'ahdash_draw.png'
    'exec-954c6037-d20a-4955-bde9-73a2b9c5a7e7.png' = 'ahdash_premium.png'
    'exec-54d23d50-9091-4967-9cf3-4707c90cde57.png' = 'ahdash_categories_step.png'
    'exec-c0ae3183-be83-4bc4-94e8-7ee4e2dc2fd5.png' = 'ahdash_teams_step.png'
    'exec-4629e7a9-0156-4c9e-89af-645f432bf70a.png' = 'ahdash_question_step.png'
    'exec-670f796e-e1d5-4123-bd1b-b49ecba4f79d.png' = 'ahdash_empty_games.png'
    'exec-93a39169-011f-4f75-9e4b-566ec6e801d0.png' = 'ahdash_empty_friends.png'
    'exec-afb51175-e3a8-4c54-b1f0-67be31da093a.png' = 'helpers\ahdash_two_chances.png'
    'exec-a5544508-9e52-48bd-a453-4b6e406277bc.png' = 'helpers\ahdash_call_friend.png'
    'exec-c88c0acd-7bc9-4145-baed-1796d4cfba63.png' = 'helpers\ahdash_risk.png'
    'exec-de7126e1-90c2-4d18-9cb2-29196563451d.png' = 'helpers\ahdash_bench.png'
    'exec-5a24630a-5bd4-44c7-a038-ac75d20f46ad.png' = 'helpers\ahdash_pass.png'
}

foreach ($entry in $assets.GetEnumerator()) {
    $source = Join-Path $GeneratedRoot $entry.Key
    $destination = Join-Path $OutputRoot $entry.Value
    if (-not (Test-Path -LiteralPath $source)) {
        throw "Missing generated pictogram source: $source"
    }
    $destinationDirectory = Split-Path -Parent $destination
    New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
    Copy-Item -LiteralPath $source -Destination $destination -Force
}

& "$PSScriptRoot\normalize_pictograms.ps1" `
    -InputRoot $OutputRoot `
    -CanvasSize 1024 `
    -SafeArea 80

Write-Output "Rebuilt $($assets.Count) transparent PNG pictograms at 1024x1024."
