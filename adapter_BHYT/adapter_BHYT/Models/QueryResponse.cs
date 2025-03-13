namespace adapter_BHYT.Models
{
    /// <summary>
    /// Đại diện cho một phản hồi truy vấn gửi về WebSocket
    /// </summary>
    public class QueryResponse
    {
        /// <summary>
        /// ID duy nhất của truy vấn (khớp với QueryRequest)
        /// </summary>
        public string? QueryId { get; set; }

        /// <summary>
        /// Trạng thái thành công của truy vấn
        /// </summary>
        public bool Success { get; set; }

        /// <summary>
        /// Dữ liệu kết quả truy vấn
        /// </summary>
        public object? Data { get; set; }

        /// <summary>
        /// Thông báo lỗi (nếu có)
        /// </summary>
        public string? ErrorMessage { get; set; }

        /// <summary>
        /// Thời gian tạo phản hồi
        /// </summary>
        public DateTime Timestamp { get; set; } = DateTime.Now;

        /// <summary>
        /// Thông báo thành công (nếu có)
        /// </summary>
        public string? Message { get; set; }

        /// <summary>
        /// Thời gian phản hồi
        /// </summary>
        public DateTime ResponseTime { get; set; } = DateTime.Now;
    }
} 