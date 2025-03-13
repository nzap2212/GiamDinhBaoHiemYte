using System;
using System.Collections.Generic;
using System.Windows;
using System.Windows.Controls;
using GĐBHYT.UI.Components;
using GĐBHYT.UI.Pages;

namespace GĐBHYT.UI
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        // Dictionary để lưu trữ các trang
        private Dictionary<string, UserControl> _pages;

        public MainWindow()
        {
            InitializeComponent();
            InitializePages();
            
            // Đăng ký sự kiện điều hướng từ SlideBar
            sideBar.NavigationRequested += SideBar_NavigationRequested;
            
            // Mặc định hiển thị trang chủ
            NavigateToPage("Dashboard");
            
            // Thêm dòng này để kiểm tra
            // ShowTheoDoi130NoiTru();
        }

        /// <summary>
        /// Khởi tạo các trang trong ứng dụng
        /// </summary>
        private void InitializePages()
        {
            _pages = new Dictionary<string, UserControl>
            {
                { "Dashboard", new mainPage() },
                { "QuanLyHoSo130", new Quanlyhoso130() },
                { "CapNhatHoSo130", new CapNhatHoSo130() },
                { "TheoDoi130NoiTru", new TheoDoi130NoiTru() }
            };
        }

        /// <summary>
        /// Xử lý sự kiện khi người dùng chọn một mục trong SlideBar
        /// </summary>
        private void SideBar_NavigationRequested(object sender, MenuNavigationEventArgs e)
        {
            NavigateToPage(e.PageName);
        }

        /// <summary>
        /// Điều hướng đến trang được chỉ định
        /// </summary>
        private void NavigateToPage(string pageName)
        {
            System.Diagnostics.Debug.WriteLine($"NavigateToPage called with pageName: {pageName}");
            
            if (_pages.ContainsKey(pageName))
            {
                System.Diagnostics.Debug.WriteLine($"Page found in dictionary: {pageName}");
                
                // Hiển thị trang được chọn
                contentFrame.Content = _pages[pageName];
                
                // Cập nhật tiêu đề trang trên header
                UpdatePageTitle(pageName);
                
                // Đánh dấu mục menu đang được chọn
                sideBar.SelectMenuItem(pageName);
            }
            else
            {
                System.Diagnostics.Debug.WriteLine($"Page NOT found in dictionary: {pageName}");
                MessageBox.Show($"Trang '{pageName}' không tồn tại.", "Lỗi điều hướng", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        /// <summary>
        /// Cập nhật tiêu đề trang trên header
        /// </summary>
        private void UpdatePageTitle(string pageName)
        {
            string pageTitle = "Trang chủ";
            
            switch (pageName)
            {
                case "Dashboard":
                    pageTitle = "Trang chủ";
                    break;
                case "QuanLyHoSo130":
                    pageTitle = "Quản lý hồ sơ 130";
                    break;
                case "CapNhatHoSo130":
                    pageTitle = "Cập nhật hồ sơ 130";
                    break;
                case "TheoDoi130NoiTru":
                    pageTitle = "Theo dõi bệnh nhân nội trú";
                    break;
            }
            
            header.UpdatePageTitle(pageTitle);
        }

        /// <summary>
        /// Phương thức để đăng ký trang mới từ bên ngoài
        /// </summary>
        public void RegisterPage(string pageName, Type pageType)
        {
            if (!_pages.ContainsKey(pageName))
            {
                var page = Activator.CreateInstance(pageType) as UserControl;
                if (page != null)
                {
                    _pages.Add(pageName, page);
                }
            }
        }

        private void TestButton_Click(object sender, RoutedEventArgs e)
        {
            NavigateToPage("TheoDoi130NoiTru");
        }

        public void ShowTheoDoi130NoiTru()
        {
            System.Diagnostics.Debug.WriteLine("ShowTheoDoi130NoiTru called");
            contentFrame.Content = new TheoDoi130NoiTru();
            header.UpdatePageTitle("Theo dõi bệnh nhân nội trú");
            sideBar.SelectMenuItem("TheoDoi130NoiTru");
        }
    }
}