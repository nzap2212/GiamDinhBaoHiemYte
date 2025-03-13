using System;
using System.Collections.Generic;
using System.Windows.Controls;
using GĐBHYT.UI.Pages;

namespace GĐBHYT.UI.Services
{
    public class NavigationService
    {
        private static NavigationService _instance;
        private Frame _mainFrame;
        private Dictionary<string, Type> _pageTypes;

        private NavigationService()
        {
            _pageTypes = new Dictionary<string, Type>();
            RegisterPages();
        }

        public static NavigationService Instance
        {
            get
            {
                if (_instance == null)
                {
                    _instance = new NavigationService();
                }
                return _instance;
            }
        }

        public void Initialize(Frame mainFrame)
        {
            _mainFrame = mainFrame;
        }

        public void NavigateTo(string pageName)
        {
            if (_mainFrame == null)
            {
                throw new InvalidOperationException("Navigation service not initialized with a frame.");
            }

            if (_pageTypes.ContainsKey(pageName))
            {
                var pageType = _pageTypes[pageName];
                var page = Activator.CreateInstance(pageType);
                _mainFrame.Navigate(page);
            }
            else
            {
                throw new ArgumentException($"Page '{pageName}' not registered.");
            }
        }

        private void RegisterPages()
        {
            // Đăng ký các trang hiện có
            _pageTypes.Add("Dashboard", typeof(mainPage));
            _pageTypes.Add("Quanlyhoso130", typeof(Quanlyhoso130));
            _pageTypes.Add("CapNhatHoSo130", typeof(CapNhatHoSo130));
            
            // Đăng ký trang mới
            _pageTypes.Add("TheoDoi130NoiTru", typeof(TheoDoi130NoiTru));
        }

        public void AddPage(string pageName, Type pageType)
        {
            if (!_pageTypes.ContainsKey(pageName))
            {
                _pageTypes.Add(pageName, pageType);
            }
        }
    }
} 