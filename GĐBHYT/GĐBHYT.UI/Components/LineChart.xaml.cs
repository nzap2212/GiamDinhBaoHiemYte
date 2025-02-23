using GDBHYT.UI.ViewModels;
using System.Windows.Controls;


namespace GĐBHYT.UI.Components
{
    /// <summary>
    /// Interaction logic for LineChart.xaml
    /// </summary>
    public partial class LineChart : UserControl
    {
        public LineChart()
        {
            InitializeComponent();
            DataContext = new ChartsViewModels();
        }
    }
}
