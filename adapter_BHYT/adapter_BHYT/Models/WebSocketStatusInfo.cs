using adapter_BHYT.Services;

namespace adapter_BHYT.Models
{
    /// <summary>
    /// Thông tin trạng thái kết nối WebSocket
    /// </summary>
    public class WebSocketStatusInfo
    {
        /// <summary>
        /// Trạng thái kết nối
        /// </summary>
        public bool IsConnected { get; set; }

        /// <summary>
        /// Trạng thái kết nối chi tiết
        /// </summary>
        public WebSocketConnectionStatus ConnectionStatus { get; set; }

        /// <summary>
        /// URL máy chủ WebSocket
        /// </summary>
        public string ServerUrl { get; set; } = string.Empty;

        /// <summary>
        /// Thời gian kết nối gần nhất
        /// </summary>
        public DateTime LastConnectedTime { get; set; }

        /// <summary>
        /// Thời gian ngắt kết nối gần nhất
        /// </summary>
        public DateTime LastDisconnectedTime { get; set; }

        /// <summary>
        /// Số lần thử kết nối lại
        /// </summary>
        public int ReconnectAttempts { get; set; }

        /// <summary>
        /// Số tin nhắn đã nhận
        /// </summary>
        public int MessagesReceived { get; set; }

        /// <summary>
        /// Số tin nhắn đã gửi
        /// </summary>
        public int MessagesSent { get; set; }

        /// <summary>
        /// Thông báo lỗi gần nhất
        /// </summary>
        public string LastErrorMessage { get; set; } = string.Empty;
    }
} 