using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Windows.Controls;

namespace GĐBHYT.UI.Pages
{
    /// <summary>
    /// Interaction logic for TheoDoi130NoiTru.xaml
    /// </summary>
    public partial class TheoDoi130NoiTru : UserControl
    {
        public TheoDoi130NoiTru()
        {
            System.Diagnostics.Debug.WriteLine("TheoDoi130NoiTru constructor called");
            InitializeComponent();
            LoadSampleData();
            System.Diagnostics.Debug.WriteLine("TheoDoi130NoiTru initialized successfully");
        }

        private void LoadSampleData()
        {
            var benhNhanList = new ObservableCollection<BenhNhanNoiTruModel>
            {
                new BenhNhanNoiTruModel { SoBenhAn = "BA001", TenBenhNhan = "Nguyễn Văn A", GioiTinh = "Nam", NgayVao = "01/05/2023", ThoiGianVao = "08:30", LyDoVao = "Đau bụng cấp", KhoaVao = "Ngoại", ICDVao = "K35" },
                new BenhNhanNoiTruModel { SoBenhAn = "BA002", TenBenhNhan = "Trần Thị B", GioiTinh = "Nữ", NgayVao = "02/05/2023", ThoiGianVao = "10:15", LyDoVao = "Sốt cao", KhoaVao = "Nội", ICDVao = "A09" },
                new BenhNhanNoiTruModel { SoBenhAn = "BA003", TenBenhNhan = "Lê Văn C", GioiTinh = "Nam", NgayVao = "03/05/2023", ThoiGianVao = "14:45", LyDoVao = "Khó thở", KhoaVao = "Hô hấp", ICDVao = "J18" },
                new BenhNhanNoiTruModel { SoBenhAn = "BA004", TenBenhNhan = "Phạm Thị D", GioiTinh = "Nữ", NgayVao = "04/05/2023", ThoiGianVao = "09:00", LyDoVao = "Đau ngực", KhoaVao = "Tim mạch", ICDVao = "I20" },
                new BenhNhanNoiTruModel { SoBenhAn = "BA005", TenBenhNhan = "Hoàng Văn E", GioiTinh = "Nam", NgayVao = "05/05/2023", ThoiGianVao = "11:30", LyDoVao = "Gãy xương đùi", KhoaVao = "Chấn thương", ICDVao = "S72" },
                new BenhNhanNoiTruModel { SoBenhAn = "BA006", TenBenhNhan = "Ngô Thị F", GioiTinh = "Nữ", NgayVao = "06/05/2023", ThoiGianVao = "16:20", LyDoVao = "Tiểu đường", KhoaVao = "Nội tiết", ICDVao = "E11" },
                new BenhNhanNoiTruModel { SoBenhAn = "BA007", TenBenhNhan = "Đỗ Văn G", GioiTinh = "Nam", NgayVao = "07/05/2023", ThoiGianVao = "13:10", LyDoVao = "Viêm phổi", KhoaVao = "Hô hấp", ICDVao = "J15" },
                new BenhNhanNoiTruModel { SoBenhAn = "BA008", TenBenhNhan = "Vũ Thị H", GioiTinh = "Nữ", NgayVao = "08/05/2023", ThoiGianVao = "07:45", LyDoVao = "Đau đầu", KhoaVao = "Thần kinh", ICDVao = "G43" },
                new BenhNhanNoiTruModel { SoBenhAn = "BA009", TenBenhNhan = "Bùi Văn I", GioiTinh = "Nam", NgayVao = "09/05/2023", ThoiGianVao = "12:00", LyDoVao = "Suy thận", KhoaVao = "Thận", ICDVao = "N18" },
                new BenhNhanNoiTruModel { SoBenhAn = "BA010", TenBenhNhan = "Lý Thị K", GioiTinh = "Nữ", NgayVao = "10/05/2023", ThoiGianVao = "15:30", LyDoVao = "Viêm gan", KhoaVao = "Tiêu hóa", ICDVao = "B19" }
            };

            dataGrid.ItemsSource = benhNhanList;
        }
    }

    public class BenhNhanNoiTruModel
    {
        public string SoBenhAn { get; set; }
        public string TenBenhNhan { get; set; }
        public string GioiTinh { get; set; }
        public string NgayVao { get; set; }
        public string ThoiGianVao { get; set; }
        public string LyDoVao { get; set; }
        public string KhoaVao { get; set; }
        public string ICDVao { get; set; }
    }
} 