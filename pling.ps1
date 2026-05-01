<#
.SYNOPSIS
    pling - Make the taskbar flash to signal a task is done.

.DESCRIPTION
    Flashes the Windows taskbar and shows a toast notification.
    Works natively on Windows (PowerShell 5.1+).

.EXAMPLE
    .\pling.ps1
    # Flash taskbar with defaults

.EXAMPLE
    .\pling.ps1 -Message "Build done"
    # Flash with a custom message

.EXAMPLE
    cargo build; .\pling.ps1
    # Flash when build finishes
#>

param(
    [string]$Message = "Task complete",
    [switch]$Help
)

if ($Help) {
    Get-Help $MyInvocation.MyCommand.Path -Detailed
    exit 0
}

# ─── Flash the taskbar ──────────────────────────────────────────────────────

# Use P/Invoke to call FlashWindowEx from user32.dll — this is what makes
# the taskbar entry flash orange on Windows.
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public struct FLASHWINFO {
    public uint cbSize;
    public IntPtr hwnd;
    public uint dwFlags;
    public uint uCount;
    public uint dwTimeout;
}

public class WindowFlash {
    [DllImport("user32.dll")]
    public static extern bool FlashWindowEx(ref FLASHWINFO pwfi);

    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    public static bool Flash(IntPtr hwnd) {
        if (hwnd == IntPtr.Zero) return false;
        FLASHWINFO fi = new FLASHWINFO();
        fi.cbSize = (uint)Marshal.SizeOf(typeof(FLASHWINFO));
        fi.hwnd = hwnd;
        fi.dwFlags = 3 | 12;
        fi.uCount = 0;
        fi.dwTimeout = 0;
        return FlashWindowEx(ref fi);
    }
}
"@ -ErrorAction SilentlyContinue

# 1. Flash the taskbar — find window handle (process lookup > GetConsoleWindow)
try {
    $hwnd = [IntPtr]::Zero

    # Try Windows Terminal process first (needed for WT / WSL2)
    $wt = Get-Process WindowsTerminal -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($wt -and $wt.MainWindowHandle -ne [IntPtr]::Zero) {
        $hwnd = $wt.MainWindowHandle
    }

    # Fallback to GetConsoleWindow (works in cmd.exe, old conhost)
    if ($hwnd -eq [IntPtr]::Zero) {
        $hwnd = [WindowFlash]::GetConsoleWindow()
    }

    if ($hwnd -ne [IntPtr]::Zero) {
        [WindowFlash]::Flash($hwnd) | Out-Null
    }
}
catch {
    # Last resort
    Write-Host "`a" -NoNewline
}

# 2. Toast notification (Windows 10/11, no extra modules needed)
try {
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType = WindowsRuntime] | Out-Null

    $template = @"
<toast>
  <visual>
    <binding template="ToastGeneric">
      <text>pling</text>
      <text>$Message</text>
    </binding>
  </visual>
  <audio silent="true"/>
</toast>
"@
    $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $xml.LoadXml($template)
    $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("pling").Show($toast)
}
catch {
    # Toast not available — taskbar flash is enough
}

# 3. Audible beep as extra nudge
[Console]::Beep(800, 200)
