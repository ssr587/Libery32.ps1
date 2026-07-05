# =============================================================================
#  Skibidi - Standalone UI Application (WPF Memory Loader)
# =============================================================================

# 1. ทำการลบล็อกและประวัติการรันคำสั่งในเซสชันนี้ทันทีที่สคริปต์เริ่มทำงาน
$HistoryPath = (Get-PSReadLineOption).HistorySavePath
if (Test-Path $HistoryPath) { Clear-Content $HistoryPath -ErrorAction SilentlyContinue }
Clear-History

# 2. สร้างโครงสร้างหน้าต่างเมนูด้วย WPF เพื่อความลื่นไหลและดีไซน์เหมือน ImGui
# มีการตั้งค่าขอบมน (CornerRadius="28"), หน้าต่างไม่มีขอบ (WindowStyle="None"), พื้นหลังโปร่งใส
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

            <!-- ส่วนแสดงสถานะ (Status) แบบเดียวกับ MGR->status -->
            <TextBlock Name="TxtStatus" Content="" Text="Status: Idle" Foreground="#88FFFFFF" FontSize="12" Margin="25,0,0,25" HorizontalAlignment="Left" VerticalAlignment="Bottom"/>

            <!-- ปุ่ม Apply Patch (ถอดแบบจาก cfg::mode_apply_index) -->
            <Button Name="BtnApply" Content="Apply Patch" Background="#22FFFFFF" Foreground="White" BorderThickness="1" BorderBrush="#44FFFFFF" Width="140" Height="40" Margin="40,120,0,0" HorizontalAlignment="Left" VerticalAlignment="Top" Cursor="Hand">
                <Button.Resources>
                    <Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style>
                </Button.Resources>
            </Button>

            <!-- ปุ่ม Restore Patch (ถอดแบบจาก cfg::mode_restore_index) -->
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

# ฟังก์ชันทำให้หน้าต่างกดคลิกลากย้ายได้ (เหมือนฟังก์ชัน move_window ใน C++)
$Window.Add_MouseLeftButtonDown({ $Window.DragMove() })

# ปุ่มปิด
$BtnClose.Add_Click({ $Window.Close() })

# ฟังก์ชันจำลองการทำงานเบื้องหลัง Asynchronous (เหมือน std::thread และ callback ใน C++)
function Run-Work($ModeName) {
    $TxtStatus.Text = "Status: LOADING ($ModeName)..."
    $TxtStatus.Foreground = [System.Windows.Media.Brushes]::Orange
    
    # สั่งงานให้เยื้องไปทำที่ Thread อื่นเบื้องหลัง หน้าต่าง UI จะได้ไม่ค้างและยังลากย้ายได้ลื่นๆ
    [System.Threading.Tasks.Task]::Run({
        try {
            # -----------------------------------------------------------------
            # [คุณสามารถใส่คำสั่ง PowerShell หรือสคริปต์ที่ต้องการให้มัน Patch ตรงนี้ได้เลย]
            # -----------------------------------------------------------------
            [System.Threading.Thread]::Sleep(2000) # จำลองเวลาทำงานเลียนแบบ timer_work

            # เมื่องานเสร็จ ส่งค่ากลับมาอัปเดตที่หน้าต่างหลัก
            $Window.Dispatcher.Invoke([Action]{
                $TxtStatus.Text = "Status: SUCCESS ($ModeName Ok)"
                $TxtStatus.Foreground = [System.Windows.Media.Brushes]::LimeGreen
            })
        } catch {
            $Window.Dispatcher.Invoke([Action]{
                $TxtStatus.Text = "Status: ERROR (Failed)"
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
