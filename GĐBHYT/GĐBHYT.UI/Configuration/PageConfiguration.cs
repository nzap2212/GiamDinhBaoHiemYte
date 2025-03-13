using GĐBHYT.UI.Pages;
using System;

namespace GĐBHYT.UI.Configuration
{
    public static class PageConfiguration
    {
        public static void RegisterPages()
        {
            // Đăng ký trang mới
            RegisterPage("TheoDoi130NoiTru", typeof(TheoDoi130NoiTru), "Theo dõi bệnh nhân nội trú", "Giám định 130");
        }
        
        private static void RegisterPage(string key, Type pageType, string title, string category)
        {
            // Thực hiện đăng ký trang theo cơ chế của ứng dụng
        }
    }
} 