using System;
using System.Windows;

namespace GĐBHYT.UI
{
    /// <summary>
    /// Interaction logic for App.xaml
    /// </summary>
    public partial class App : Application
    {
        protected override void OnStartup(StartupEventArgs e)
        {
            base.OnStartup(e);
            
            // Không cần thêm code đăng ký trang ở đây nữa
            // Vì chúng ta đã thêm trực tiếp vào MainWindow.xaml.cs
        }
    }
}
