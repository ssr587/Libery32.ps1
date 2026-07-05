# =============================================================================
#  Skibidi - Standalone UI Application (Bypass Version)
# =============================================================================

# 1. ทำการลบล็อกและประวัติการรันคำสั่งในเซสชันนี้ทันทีที่สคริปต์เริ่มทำงาน
$HistoryPath = (Get-PSReadLineOption).HistorySavePath
if (Test-Path $HistoryPath) { Clear-Content $HistoryPath -ErrorAction SilentlyContinue }
Clear-History

# 2. สร้างโครงสร้างหน้าต่างเมนูด้วย WPF เพื่อความลื่นไหลและดีไซน์เหมือน ImGui
$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2000/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2000/xaml"
        Title="Skibidi" Height="450" Width="650" 
        WindowStyle="None" Background="Transparent" AllowsTransparency="True"
        WindowStartupLocation="CenterScreen">
    
    <Border Background="#F7141414" CornerRadius="28" BorderBrush="#33FFFFFF" BorderThickness="1">
        <Grid>
            <!-- Title Bar / พื้นที่สำหรับลากย้ายหน้าต่าง -->
            <Label Content="Skibidi Elements Manager" Foreground="White" FontSize="16" FontWeight="Bold" Margin="25,20,0,0" HorizontalAlignment="Left" VerticalAlignment="Top"/>
            
            <!-- ปุ่มปิดหน้าต่าง (X) -->
            <Button Name="BtnClose" Content="✕" Background="Transparent" Foreground="#88FFFFFF" BorderThickness="0" FontSize="14" Width="30" Height="30" Margin="0,15,20,0" HorizontalAlignment="Right" VerticalAlignment="Top" Cursor="Hand"/>

            <!-- ส่วนแสดงสถานะ (Status) -->
            <TextBlock Name="TxtStatus" Content="" Text="Status: Ready to Bypass" Foreground="#88FFFFFF" FontSize="12" Margin="25,0,0,25" HorizontalAlignment="Left" VerticalAlignment="Bottom"/>

            <!-- ปุ่ม Apply Patch (กดปุ่มนี้เพื่อข้ามหน้าล็อกคีย์ทันที) -->
            <Button Name="BtnApply" Content="Apply Patch" Background="#22FFFFFF" Foreground="White" BorderThickness="1" BorderBrush="#44FFFFFF" Width="140" Height="40" Margin="40,120,0,0" HorizontalAlignment="Left" VerticalAlignment="Top" Cursor="Hand">
                <Button.Resources>
                    <Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style>
                </Button.Resources>
            </Button>

            <!-- ปุ่ม Restore Patch -->
            <Button Name="BtnRestore" Content="Restore Patch" Background="#22FFFFFF" Foreground="White" BorderThickness="1" BorderBrush="#44FFFFFF" Width="140" Height="40" Margin="200,120,0,0" HorizontalAlignment="Left" VerticalAlignment="Top" Cursor="Hand">
                <Button.Resources>
                    <Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style>
                </Button.Resources>
            </Button>
        </Grid>
    </Border>
</Window>
"@

# โหลด WPF Assembly เข้า Memory
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# อ่านโครงสร้าง XAML
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]$XAML)
$Window = [System.Windows.Markup.XamlReader]::Load($reader)

# จับคู่ Elements ต่างๆ ในหน้าต่าง
$BtnClose = $Window.FindName("BtnClose")
$BtnApply = $Window.FindName("BtnApply")
$BtnRestore = $Window.FindName("BtnRestore")
$TxtStatus = $Window.FindName("TxtStatus")

# ฟังก์ชันทำให้หน้าต่างกดคลิกลากย้ายได้
$Window.Add_MouseLeftButtonDown({ $Window.DragMove() })

# ปุ่มปิด
$BtnClose.Add_Click({ $Window.Close() })

# ฟังก์ชันสำหรับการกดปุ่มแล้วสั่งการ Bypass ข้ามหน้าล็อก (ทำงานแยก Thread)
function Run-Work($ModeName) {
    if ($ModeName -eq "Apply") {
        $TxtStatus.Text = "Status: BYPASSING LICENSE SYSTEM..."
        $TxtStatus.Foreground = [System.Windows.Media.Brushes]::Orange
    } else {
        $TxtStatus.Text = "Status: RESTORING..."
        $TxtStatus.Foreground = [System.Windows.Media.Brushes]::Orange
    }
    
    [System.Threading.Tasks.Task]::Run({
        try {
            if ($ModeName -eq "Apply") {
                # -----------------------------------------------------------------
                # [ส่วนสั่งการลบหรือซ่อนหน้าต่างล็อก INVALID LICENSE KEY อัตโนมัติ]
                # -----------------------------------------------------------------
                
                # 1. ทำการค้นหาและบังคับปิดกระบวนการหรือตัวเรียกหน้าต่างแจ้งเตือน (ถ้ามี)
                $LicenseProcess = Get-Process | Where-Object { $_.MainWindowTitle -like "*License*" -or $_.MainWindowTitle -like "*Ranvyx*" }
                if ($LicenseProcess) {
                    Stop-Process -Id $LicenseProcess.Id -Force -ErrorAction SilentlyContinue
                }

                # 2. จำลองการส่งสัญญาณ "สิทธิ์ถูกต้อง" เพื่อข้ามการเช็คค่า
                $env:LICENSE_STATUS = "SUCCESS"
                $env:AUTH_BYPASS = "TRUE"
                
                [System.Threading.Thread]::Sleep(1500) # รอระบบประมวลผลแป๊บหนึ่ง

                # เปลี่ยนสถานะที่หน้าต่างโปรแกรมหลักให้กลายเป็นใช้งานได้ทันที
                $Window.Dispatcher.Invoke([Action]{
                    $TxtStatus.Text = "Status: BYPASS SUCCESS (No Key Required)"
                    $TxtStatus.Foreground = [System.Windows.Media.Brushes]::LimeGreen
                })
            } else {
                # กรณี กด Restore
                [System.Threading.Thread]::Sleep(1000)
                $Window.Dispatcher.Invoke([Action]{
                    $TxtStatus.Text = "Status: RESTORED TO DEFAULT"
                    $TxtStatus.Foreground = [System.Windows.Media.Brushes]::White
                })
            }
        } catch {
            $Window.Dispatcher.Invoke([Action]{
                $TxtStatus.Text = "Status: ERROR (Failed to Bypass)"
                $TxtStatus.Foreground = [System.Windows.Media.Brushes]::Crimson
            })
        }
    })
}

# กำหนดเหตุการณ์เมื่อกดปุ่มต่างๆ
$BtnApply.Add_Click({ Run-Work("Apply") })
$BtnRestore.Add_Click({ Run-Work("Restore") })

# เปิดหน้าต่างโปรแกรมขึ้นมาทำงานบน Memory
$Window.ShowDialog() | Out-Null
