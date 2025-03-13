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
    /// Interaction logic for Header.xaml
    /// </summary>
    public partial class Header : UserControl
    {
        public Header()
        {
            InitializeComponent();
        }

        /// <summary>
        /// Cập nhật tiêu đề trang hiển thị trên header
        /// </summary>
        /// <param name="pageTitle">Tên trang cần hiển thị</param>
        public void UpdatePageTitle(string pageTitle)
        {
            if (PageTitleText != null)
            {
                PageTitleText.Text = pageTitle;
            }
        }
    }
}
