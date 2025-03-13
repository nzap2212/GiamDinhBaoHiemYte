namespace adapter_BHYT.Models
{
    /// <summary>
    /// Lưu trữ cấu hình API từ Google Sheets
    /// </summary>
    public class ApiConfig
    {
        /// <summary>
        /// Dictionary lưu trữ cấu hình dưới dạng key-value
        /// </summary>
        public Dictionary<string, string> ConfigItems { get; set; } = new Dictionary<string, string>();

        /// <summary>
        /// Thời gian cập nhật cuối cùng
        /// </summary>
        public DateTime LastUpdated { get; set; } = DateTime.MinValue;
    }
} 