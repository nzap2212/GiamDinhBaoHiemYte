using LiveCharts;
using LiveCharts.Wpf;
using System.Collections.Generic;
using System.ComponentModel;

namespace GDBHYT.UI.ViewModels
{
    public class ChartsViewModels : INotifyPropertyChanged
    {
        private SeriesCollection _seriesCollection;
        private List<string> _labels;

        public SeriesCollection SeriesCollection
        {
            get => _seriesCollection;
            set
            {
                _seriesCollection = value;
                OnPropertyChanged(nameof(SeriesCollection));
            }
        }

        public List<string> Labels
        {
            get => _labels;
            set
            {
                _labels = value;
                OnPropertyChanged(nameof(Labels));
            }
        }

        public ChartsViewModels()
        {
            LoadChartData();
        }

        private void LoadChartData()
        {
            // Dữ liệu cột (Khám bệnh, Ngoại trú, Nội trú)
            var khamBenh = new ColumnSeries
            {
                Title = "Khám bệnh",
                Values = new ChartValues<int> { 100, 200, 150, 500, 1200, 3000, 2000 },
                Fill = System.Windows.Media.Brushes.LightBlue
            };

            var ngoaiTru = new ColumnSeries
            {
                Title = "Ngoại trú",
                Values = new ChartValues<int> { 50, 100, 80, 300, 900, 2500, 1800 },
                Fill = System.Windows.Media.Brushes.Red
            };

            var noiTru = new ColumnSeries
            {
                Title = "Nội trú",
                Values = new ChartValues<int> { 200, 400, 300, 700, 1500, 3500, 2500 },
                Fill = System.Windows.Media.Brushes.DarkBlue
            };

            // Dữ liệu đường (Tổng số hồ sơ)
            var tongHoSo = new LineSeries
            {
                Title = "Tổng hồ sơ",
                Values = new ChartValues<int> { 350, 700, 530, 1500, 3600, 9000, 6300, 8000 },
                PointGeometry = DefaultGeometries.Circle,
                PointGeometrySize = 10,
                StrokeThickness = 2
            };

            // Dữ liệu đường (Tổng tiền - scaled xuống)
            var tongTien = new LineSeries
            {
                Title = "Tổng tiền (scaled)",
                Values = new ChartValues<int> { 500, 1200, 900, 3500, 7800, 20000, 14000, 23000 },
                PointGeometry = DefaultGeometries.Circle,
                PointGeometrySize = 10,
                StrokeThickness = 2,
                Stroke = System.Windows.Media.Brushes.Magenta
            };

            // Gán vào SeriesCollection
            SeriesCollection = new SeriesCollection { khamBenh, ngoaiTru, noiTru, tongHoSo, tongTien };

            // Nhãn trục X (Tháng)
            Labels = new List<string> { "Th3 2024", "Th4 2024", "Th5 2024", "Th6 2024", "Th11 2024", "Th12 2024", "Th1 2025" };
        }

        public event PropertyChangedEventHandler PropertyChanged;
        protected void OnPropertyChanged(string propertyName)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}
