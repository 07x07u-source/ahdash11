param(
    [string]$InputRoot = "C:\dev\ahdash11\mobile\assets\pictograms",
    [int]$CanvasSize = 256,
    [int]$SafeArea = 20
)

Add-Type -AssemblyName System.Drawing

$normalizerSource = @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;

public static class AhdashPictogramNormalizer
{
    public static void Normalize(string path, int canvasSize, int safeArea)
    {
        using (var original = new Bitmap(path))
        using (var source = new Bitmap(original.Width, original.Height, PixelFormat.Format32bppArgb))
        {
            using (var graphics = Graphics.FromImage(source))
            {
                graphics.DrawImageUnscaled(original, 0, 0);
            }

            var bounds = new Rectangle(0, 0, source.Width, source.Height);
            var data = source.LockBits(bounds, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
            var bytes = new byte[Math.Abs(data.Stride) * source.Height];
            Marshal.Copy(data.Scan0, bytes, 0, bytes.Length);

            var minX = source.Width;
            var minY = source.Height;
            var maxX = -1;
            var maxY = -1;

            for (var y = 0; y < source.Height; y++)
            {
                var row = y * data.Stride;
                for (var x = 0; x < source.Width; x++)
                {
                    var offset = row + (x * 4);
                    var b = bytes[offset];
                    var g = bytes[offset + 1];
                    var r = bytes[offset + 2];
                    var luminance = (int)(0.2126 * r + 0.7152 * g + 0.0722 * b);
                    byte alpha;
                    if (luminance >= 232) alpha = 0;
                    else if (luminance <= 128) alpha = 255;
                    else alpha = (byte)(255 * (232 - luminance) / 104);

                    bytes[offset] = 0;
                    bytes[offset + 1] = 0;
                    bytes[offset + 2] = 0;
                    bytes[offset + 3] = alpha;

                    if (alpha > 8)
                    {
                        if (x < minX) minX = x;
                        if (y < minY) minY = y;
                        if (x > maxX) maxX = x;
                        if (y > maxY) maxY = y;
                    }
                }
            }

            Marshal.Copy(bytes, 0, data.Scan0, bytes.Length);
            source.UnlockBits(data);

            if (maxX < minX || maxY < minY)
                throw new InvalidOperationException("No foreground pixels found in " + path);

            var contentWidth = maxX - minX + 1;
            var contentHeight = maxY - minY + 1;
            var available = canvasSize - (2 * safeArea);
            var scale = Math.Min((double)available / contentWidth, (double)available / contentHeight);
            var drawWidth = (int)Math.Round(contentWidth * scale);
            var drawHeight = (int)Math.Round(contentHeight * scale);
            var drawX = (canvasSize - drawWidth) / 2;
            var drawY = (canvasSize - drawHeight) / 2;

            using (var output = new Bitmap(canvasSize, canvasSize, PixelFormat.Format32bppArgb))
            using (var graphics = Graphics.FromImage(output))
            {
                graphics.Clear(Color.Transparent);
                graphics.CompositingMode = CompositingMode.SourceCopy;
                graphics.CompositingQuality = CompositingQuality.HighQuality;
                graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
                graphics.PixelOffsetMode = PixelOffsetMode.HighQuality;
                graphics.SmoothingMode = SmoothingMode.HighQuality;
                graphics.DrawImage(
                    source,
                    new Rectangle(drawX, drawY, drawWidth, drawHeight),
                    new Rectangle(minX, minY, contentWidth, contentHeight),
                    GraphicsUnit.Pixel
                );

                output.Save(path + ".normalized.png", ImageFormat.Png);
            }
        }

        var normalized = path + ".normalized.png";
        File.Copy(normalized, path, true);
        File.Delete(normalized);
    }
}
'@

$drawingAssembly = [System.Drawing.Bitmap].Assembly.Location
$primitivesAssembly = [System.Drawing.Rectangle].Assembly.Location
$gdiAssembly = [System.AppDomain]::CurrentDomain.GetAssemblies() |
    Where-Object { $_.GetName().Name -eq 'System.Private.Windows.GdiPlus' } |
    Select-Object -First 1 -ExpandProperty Location
$windowsCoreAssembly = [System.AppDomain]::CurrentDomain.GetAssemblies() |
    Where-Object { $_.GetName().Name -eq 'System.Private.Windows.Core' } |
    Select-Object -First 1 -ExpandProperty Location
Add-Type -TypeDefinition $normalizerSource -ReferencedAssemblies @(
    $drawingAssembly,
    $primitivesAssembly,
    $gdiAssembly,
    $windowsCoreAssembly
) -ErrorAction Stop

$target = Get-Item -LiteralPath $InputRoot
$files = if ($target.PSIsContainer) {
    Get-ChildItem -LiteralPath $target.FullName -Recurse -Filter *.png |
        Where-Object { $_.Name -notlike '*.normalized.png' }
} else {
    @($target)
}

foreach ($file in $files) {
    $probe = [System.Drawing.Bitmap]::new($file.FullName)
    try {
        $alreadyNormalized = $probe.Width -eq $CanvasSize -and
            $probe.Height -eq $CanvasSize -and
            $probe.PixelFormat -eq [System.Drawing.Imaging.PixelFormat]::Format32bppArgb -and
            $probe.GetPixel(0, 0).A -eq 0
    }
    finally {
        $probe.Dispose()
    }

    if ($alreadyNormalized) {
        Write-Output "Already normalized: $($file.FullName)"
        continue
    }

    [AhdashPictogramNormalizer]::Normalize($file.FullName, $CanvasSize, $SafeArea)
    Write-Output "Normalized: $($file.FullName)"
}
