using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using MaterialDesignThemes.Wpf;
using GĐBHYT.UI.Models;
using GĐBHYT.UI.Pages;

namespace GĐBHYT.UI.Services
{
    public class NavigationManager
    {
        private static NavigationManager _instance;
        private ObservableCollection<NavigationItem> _navigationItems;

        private NavigationManager()
        {
            _navigationItems = new ObservableCollection<NavigationItem>();
            InitializeNavigationItems();
        }

        public static NavigationManager Instance
        {
            get
            {
                if (_instance == null)
                {
                    _instance = new NavigationManager();
                }
                return _instance;
            }
        }

        public ObservableCollection<NavigationItem> NavigationItems => _navigationItems;

        private void InitializeNavigationItems()
        {
            // Tạo các mục điều hướng
            var dashboardItem = new NavigationItem
            {
                Icon = PackIconKind.ViewDashboard,
                Label = "Dashboard",
                NavigationType = typeof(mainPage)
            };
            _navigationItems.Add(dashboardItem);

            // Thêm mục Giám định 130 và các trang con
            var giamDinh130Item = new NavigationItem
            {
                Icon = PackIconKind.FileDocument,
                Label = "Giám định 130",
                NavigationType = typeof(object),
                Children = new List<NavigationItem>
                {
                    new NavigationItem
                    {
                        Icon = PackIconKind.ViewList,
                        Label = "Quản lý hồ sơ 130",
                        NavigationType = typeof(Quanlyhoso130)
                    },
                    new NavigationItem
                    {
                        Icon = PackIconKind.FileEdit,
                        Label = "Cập nhật hồ sơ 130",
                        NavigationType = typeof(CapNhatHoSo130)
                    },
                    new NavigationItem
                    {
                        Icon = PackIconKind.HospitalBuilding,
                        Label = "Theo dõi bệnh nhân nội trú",
                        NavigationType = typeof(TheoDoi130NoiTru)
                    }
                }
            };
            _navigationItems.Add(giamDinh130Item);

            // Thêm các mục điều hướng khác nếu cần
        }

        public void AddNavigationItem(NavigationItem item)
        {
            _navigationItems.Add(item);
        }

        public void AddChildNavigationItem(string parentLabel, NavigationItem childItem)
        {
            var parentItem = _navigationItems.FirstOrDefault(item => item.Label == parentLabel);
            if (parentItem != null)
            {
                parentItem.Children.Add(childItem);
            }
        }
    }
} 