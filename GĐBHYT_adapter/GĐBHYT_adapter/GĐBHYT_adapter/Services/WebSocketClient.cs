using Newtonsoft.Json;
using System;
using System.Net.WebSockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace GĐBHYT_adapter.Services
{
    public class WebSocketClient
    {
        private readonly Uri _serverUri;
        private ClientWebSocket _webSocket;

        public WebSocketClient(string serverUrl)
        {
            _serverUri = new Uri(serverUrl);
            _webSocket = new ClientWebSocket();
        }

        public async Task ConnectAsync()
        {
            try
            {
                await _webSocket.ConnectAsync(_serverUri, CancellationToken.None);
                Console.WriteLine("🔗 Kết nối WebSocket thành công!");
                _ = ListenForMessages(); // Bắt đầu lắng nghe dữ liệu
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Lỗi kết nối WebSocket: {ex.Message}");
            }
        }

        private async Task ListenForMessages()
        {
            var buffer = new byte[4096];

            while (_webSocket.State == WebSocketState.Open)
            {
                var result = await _webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), CancellationToken.None);

                if (result.MessageType == WebSocketMessageType.Close)
                {
                    Console.WriteLine("🔴 WebSocket bị đóng.");
                    await _webSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Client đóng kết nối", CancellationToken.None);
                    break;
                }

                string message = Encoding.UTF8.GetString(buffer, 0, result.Count);
                Console.WriteLine($"📩 Nhận dữ liệu từ Server: {message}");

                // Xử lý truy vấn SQL từ server và gửi kết quả lại
                await HandleQueryAsync(message);
            }
        }

        private async Task HandleQueryAsync(string jsonMessage)
        {
            try
            {
                var request = JsonConvert.DeserializeObject<QueryRequest>(jsonMessage);
                if (request?.Query == null) return;

                Console.WriteLine($"🔎 Truy vấn SQL: {request.Query}");

                // Gọi DatabaseService để thực thi SQL
                var dbService = new DatabaseService();
                var resultData = await dbService.ExecuteQueryAsync(request.Query);

                // Chuẩn bị phản hồi JSON
                var response = new
                {
                    status = "success",
                    data = resultData
                };

                string jsonResponse = JsonConvert.SerializeObject(response);
                await SendMessageAsync(jsonResponse);
            }
            catch (Exception ex)
            {
                var errorResponse = new { status = "error", message = ex.Message };
                await SendMessageAsync(JsonConvert.SerializeObject(errorResponse));
            }
        }

        public async Task SendMessageAsync(string message)
        {
            if (_webSocket.State == WebSocketState.Open)
            {
                var bytes = Encoding.UTF8.GetBytes(message);
                await _webSocket.SendAsync(new ArraySegment<byte>(bytes), WebSocketMessageType.Text, true, CancellationToken.None);
                Console.WriteLine($"📤 Đã gửi dữ liệu: {message}");
            }
        }
    }

    // Định nghĩa model JSON nhận từ server
    public class QueryRequest
    {
        public string Query { get; set; }
    }
}
