using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace GĐBHYT.UI.Components
{
    /// <summary>
    /// Interaction logic for SlideBar.xaml
    /// </summary>
    public partial class SlideBar : UserControl
    {
        // Event để thông báo cho MainWindow khi có mục được chọn
        public event EventHandler<MenuNavigationEventArgs> NavigationRequested;

        // Lưu trữ mục menu đang được chọn
        private StackPanel _currentSelectedItem;

        public SlideBar()
        {
            InitializeComponent();
        }

        /// <summary>
        /// Xử lý sự kiện khi người dùng click vào một mục menu
        /// </summary>
        private void NavigationItem_Click(object sender, MouseButtonEventArgs e)
        {
            if (sender is StackPanel clickedItem)
            {
                // Thêm debug
                System.Diagnostics.Debug.WriteLine($"Clicked on menu item with tag: {clickedItem.Tag}");
                
                // Đánh dấu mục được chọn
                HighlightSelectedItem(clickedItem);
                
                // Lấy tag để xác định trang cần chuyển đến
                string pageName = clickedItem.Tag?.ToString();
                
                // Kích hoạt sự kiện để thông báo cho MainWindow
                if (!string.IsNullOrEmpty(pageName))
                {
                    System.Diagnostics.Debug.WriteLine($"Raising NavigationRequested event with pageName: {pageName}");
                    NavigationRequested?.Invoke(this, new MenuNavigationEventArgs(pageName));
                }
                else
                {
                    System.Diagnostics.Debug.WriteLine("pageName is null or empty");
                }
            }
        }

        /// <summary>
        /// Đánh dấu mục menu được chọn bằng cách thay đổi style
        /// </summary>
        private void HighlightSelectedItem(StackPanel selectedItem)
        {
            // Bỏ đánh dấu mục trước đó (nếu có)
            if (_currentSelectedItem != null)
            {
                _currentSelectedItem.Style = (Style)FindResource("NavItemStyle");
            }

            // Đánh dấu mục mới
            selectedItem.Style = (Style)FindResource("SelectedNavItemStyle");
            _currentSelectedItem = selectedItem;
        }

        /// <summary>
        /// Phương thức public để chọn một mục menu từ bên ngoài
        /// </summary>
        public void SelectMenuItem(string menuTag)
        {
            // Tìm mục menu theo tag
            foreach (var child in this.FindVisualChildren<StackPanel>())
            {
                if (child.Tag?.ToString() == menuTag)
                {
                    HighlightSelectedItem(child);
                    break;
                }
            }
        }
    }

    /// <summary>
    /// Class chứa thông tin về sự kiện điều hướng
    /// </summary>
    public class MenuNavigationEventArgs : EventArgs
    {
        public string PageName { get; }

        public MenuNavigationEventArgs(string pageName)
        {
            PageName = pageName;
        }
    }

    /// <summary>
    /// Extension methods để tìm kiếm các phần tử con trong visual tree
    /// </summary>
    public static class VisualTreeHelperExtensions
    {
        public static IEnumerable<T> FindVisualChildren<T>(this DependencyObject depObj) where T : DependencyObject
        {
            if (depObj == null) yield break;

            for (int i = 0; i < VisualTreeHelper.GetChildrenCount(depObj); i++)
            {
                var child = VisualTreeHelper.GetChild(depObj, i);
                
                if (child is T t)
                    yield return t;

                foreach (var childOfChild in FindVisualChildren<T>(child))
                    yield return childOfChild;
            }
        }
    }
}
