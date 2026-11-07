$ErrorActionPreference = 'Stop'
$root = Join-Path $PSScriptRoot 'web'
$repositoryRoot = [IO.Path]::GetFullPath($PSScriptRoot)
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add('http://localhost:4174/')
$listener.Start()
Write-Host 'DR dashboard available at http://localhost:4174/ (Ctrl+C to stop)'
$mimeTypes = @{ '.html' = 'text/html; charset=utf-8'; '.css' = 'text/css; charset=utf-8'; '.js' = 'text/javascript; charset=utf-8'; '.png' = 'image/png'; '.pdf' = 'application/pdf'; '.mp4' = 'video/mp4' }
try {
  while ($listener.IsListening) {
    $context = $listener.GetContext()
    $relative = [Uri]::UnescapeDataString($context.Request.Url.AbsolutePath.TrimStart('/'))
    if ([string]::IsNullOrWhiteSpace($relative)) { $relative = 'index.html' }
    if ($relative.StartsWith('assets/', [StringComparison]::OrdinalIgnoreCase)) {
      $path = [IO.Path]::GetFullPath((Join-Path $repositoryRoot ('docs/' + $relative)))
    } else {
      $path = [IO.Path]::GetFullPath((Join-Path $root $relative))
    }
    $allowedRoot = if ($relative.StartsWith('assets/', [StringComparison]::OrdinalIgnoreCase)) { [IO.Path]::GetFullPath((Join-Path $repositoryRoot 'docs')) } else { [IO.Path]::GetFullPath($root) }
    if (-not $path.StartsWith($allowedRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $path -PathType Leaf)) {
      $context.Response.StatusCode = 404
      $body = [Text.Encoding]::UTF8.GetBytes('Not found')
    } else {
      $extension = [IO.Path]::GetExtension($path).ToLowerInvariant()
      $context.Response.ContentType = if ($mimeTypes.ContainsKey($extension)) { $mimeTypes[$extension] } else { 'application/octet-stream' }
      $body = [IO.File]::ReadAllBytes($path)
    }
    $context.Response.ContentLength64 = $body.Length
    $context.Response.OutputStream.Write($body, 0, $body.Length)
    $context.Response.Close()
  }
} finally {
  $listener.Stop()
  $listener.Close()
}
