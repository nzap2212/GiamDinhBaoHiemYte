using System;
using System.Reflection;
using System.Windows;
using GĐBHYT.UI.Pages;

namespace GĐBHYT.UI.Services
{
    public static class PageRegistration
    {
        public static void RegisterTheoDoi130NoiTruPage()
        {
            try
            {
                // Lấy MainWindow
                var mainWindow = Application.Current.MainWindow;
                if (mainWindow == null) return;

                // Lấy loại của MainWindow
                var mainWindowType = mainWindow.GetType();

                // Tìm phương thức đăng ký trang
                var registerPageMethod = mainWindowType.GetMethod("RegisterPage", 
                    BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);

                if (registerPageMethod != null)
                {
                    // Gọi phương thức để đăng ký trang mới
                    registerPageMethod.Invoke(mainWindow, new object[] { "TheoDoi130NoiTru", typeof(TheoDoi130NoiTru) });
                }
                else
                {
                    // Tìm phương thức khác để đăng ký trang
                    var alternativeMethod = mainWindowType.GetMethod("AddPage", 
                        BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);

                    if (alternativeMethod != null)
                    {
                        alternativeMethod.Invoke(mainWindow, new object[] { "TheoDoi130NoiTru", typeof(TheoDoi130NoiTru) });
                    }
                    else
                    {
                        MessageBox.Show("Không thể tìm thấy phương thức đăng ký trang trong MainWindow.");
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi khi đăng ký trang TheoDoi130NoiTru: " + ex.Message);
            }
        }
    }
} 