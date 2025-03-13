using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Net.WebSockets;
using System.Reactive.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Websocket.Client;
using adapter_BHYT.Models;

namespace adapter_BHYT.Services
{
    /// <summary>
    /// Service xử lý kết nối WebSocket
    /// </summary>
    public class WebSocketService : IDisposable
    {
        private readonly ILogger<WebSocketService> _logger;
        private readonly MessageProcessor _messageProcessor;
        private readonly GoogleSheetsService _googleSheetsService;
        private readonly IConfiguration _configuration;
        private string _serverUrl;
        private int _reconnectInterval;
        private WebsocketClient? _client;
        private bool _isRunning;
        private readonly CancellationTokenSource _cancellationTokenSource = new CancellationTokenSource();
        
        // Thêm các thuộc tính để theo dõi trạng thái kết nối
        private DateTime _lastConnectedTime = DateTime.MinValue;
        private DateTime _lastDisconnectedTime = DateTime.MinValue;
        private int _reconnectAttempts = 0;
        private int _messagesReceived = 0;
        private int _messagesSent = 0;
        private string _lastErrorMessage = string.Empty;
        private WebSocketConnectionStatus _connectionStatus = WebSocketConnectionStatus.Disconnected;

        // Thêm các biến theo dõi hiệu suất
        private long _totalMessagesProcessed = 0;
        private long _currentActiveConnections = 0;
        private readonly ConcurrentDictionary<string, DateTime> _activeRequests = new();
        private readonly ConcurrentQueue<(DateTime Timestamp, TimeSpan ProcessingTime)> _processingTimes = new();
        private const int MAX_PROCESSING_TIMES_HISTORY = 1000;

        // Thêm các thuộc tính public
        public bool IsRunning => _isRunning;
        public string ServerUrl => _serverUrl;
        public int ReconnectInterval => _reconnectInterval;

        /// <summary>
        /// Khởi tạo WebSocketService
        /// </summary>
        /// <param name="configuration">Cấu hình ứng dụng</param>
        /// <param name="logger">Logger</param>
        /// <param name="messageProcessor">Service xử lý tin nhắn</param>
        /// <param name="googleSheetsService">Service đọc cấu hình từ Google Sheets</param>
        public WebSocketService(
            IConfiguration configuration,
            ILogger<WebSocketService> logger,
            MessageProcessor messageProcessor,
            GoogleSheetsService googleSheetsService)
        {
            _logger = logger;
            _messageProcessor = messageProcessor;
            _googleSheetsService = googleSheetsService;
            _configuration = configuration;
            
            // Đọc cấu hình mặc định từ appsettings.json
            _serverUrl = _configuration["WebSocket:ServerUrl"] ?? "ws://localhost:8080/adapter";
            _reconnectInterval = _configuration.GetValue<int>("WebSocket:ReconnectInterval", 5000);
            
            // Cấu hình sẽ được cập nhật từ Google Sheets khi Start
        }

        /// <summary>
        /// Bắt đầu kết nối WebSocket
        /// </summary>
        public async Task StartAsync()
        {
            if (_isRunning)
            {
                _logger.LogWarning("WebSocket đã đang chạy");
                return;
            }

            try
            {
                // Cập nhật cấu hình từ Google Sheets
                await UpdateConfigFromGoogleSheetsAsync();
                
                _logger.LogInformation("Khởi động WebSocket với URL: {ServerUrl}", _serverUrl);
                
                // Khởi tạo client
                var url = new Uri(_serverUrl);
                _client = new WebsocketClient(url)
                {
                    ReconnectTimeout = TimeSpan.FromMilliseconds(_reconnectInterval),
                    ErrorReconnectTimeout = TimeSpan.FromMilliseconds(_reconnectInterval)
                };

                // Đăng ký các event handlers
                _client.ReconnectionHappened.Subscribe(info =>
                {
                    _logger.LogInformation("Kết nối lại WebSocket: {Type}", info.Type);
                });

                _client.DisconnectionHappened.Subscribe(info =>
                {
                    _logger.LogWarning("Kết nối WebSocket bị đóng: {Type}, Lý do: {Description}", 
                        info.Type, info.CloseStatusDescription);
                });

                _client.MessageReceived.Subscribe(msg =>
                {
                    _ = HandleMessageAsync(msg.Text);
                });

                // Bắt đầu kết nối
                await _client.Start();
                _isRunning = true;

                // Bắt đầu task kiểm tra kết nối định kỳ
                _ = Task.Run(async () => await MonitorConnectionLoopAsync(), _cancellationTokenSource.Token);
                
                _logger.LogInformation("WebSocket đã khởi động thành công");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khởi động WebSocket: {Error}", ex.Message);
                throw;
            }
        }

        /// <summary>
        /// Cập nhật cấu hình từ Google Sheets
        /// </summary>
        private async Task UpdateConfigFromGoogleSheetsAsync()
        {
            try
            {
                _logger.LogInformation("Đang cập nhật cấu hình WebSocket từ Google Sheets...");
                
                // Đọc URL WebSocket từ Google Sheets
                string serverUrl = await _googleSheetsService.GetApiConfigValueAsync("api_websocket", _serverUrl);
                if (!string.IsNullOrEmpty(serverUrl))
                {
                    _logger.LogInformation("Đã tìm thấy URL WebSocket trong Google Sheets: {ServerUrl}", serverUrl);
                    _serverUrl = serverUrl;
                    _logger.LogInformation("Đã cập nhật URL WebSocket: {ServerUrl}", _serverUrl);
                }
                else
                {
                    _logger.LogWarning("Không tìm thấy URL WebSocket trong Google Sheets, sử dụng URL mặc định: {ServerUrl}", _serverUrl);
                }
                
                // Đọc thời gian reconnect từ Google Sheets
                string reconnectIntervalStr = await _googleSheetsService.GetApiConfigValueAsync("api_websocket_reconnect_interval", _reconnectInterval.ToString());
                if (int.TryParse(reconnectIntervalStr, out int reconnectInterval))
                {
                    _reconnectInterval = reconnectInterval;
                    _logger.LogInformation("Đã cập nhật thời gian kết nối lại: {ReconnectInterval}ms", _reconnectInterval);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi cập nhật cấu hình từ Google Sheets: {Error}", ex.Message);
                _logger.LogWarning("Sử dụng cấu hình mặc định từ appsettings.json");
            }
        }

        /// <summary>
        /// Cập nhật lại cấu hình từ Google Sheets
        /// </summary>
        public async Task RefreshConfigAsync()
        {
            await UpdateConfigFromGoogleSheetsAsync();
            
            // Nếu đang chạy, cập nhật cấu hình cho client
            if (_isRunning && _client != null)
            {
                _client.ReconnectTimeout = TimeSpan.FromMilliseconds(_reconnectInterval);
                _client.ErrorReconnectTimeout = TimeSpan.FromMilliseconds(_reconnectInterval);
                
                // Nếu URL thay đổi, cần khởi động lại client
                if (_client.Url.ToString() != _serverUrl)
                {
                    _logger.LogInformation("URL WebSocket đã thay đổi, khởi động lại kết nối...");
                    await StopAsync();
                    await StartAsync();
                }
            }
        }

        /// <summary>
        /// Dừng kết nối WebSocket
        /// </summary>
        public async Task StopAsync()
        {
            if (!_isRunning || _client == null)
            {
                return;
            }

            try
            {
                _logger.LogInformation("Đang dừng kết nối WebSocket");
                await _client.Stop(System.Net.WebSockets.WebSocketCloseStatus.NormalClosure, "Đóng kết nối theo yêu cầu");
                _isRunning = false;
                _connectionStatus = WebSocketConnectionStatus.Disconnected;
                _lastDisconnectedTime = DateTime.Now;
                _logger.LogInformation("Kết nối WebSocket đã dừng");
            }
            catch (Exception ex)
            {
                _lastErrorMessage = ex.Message;
                _logger.LogError(ex, "Lỗi khi dừng kết nối WebSocket: {Error}", ex.Message);
            }
        }

        /// <summary>
        /// Xử lý tin nhắn nhận được từ WebSocket
        /// </summary>
        /// <param name="message">Nội dung tin nhắn</param>
        private async Task HandleMessageAsync(string message)
        {
            var startTime = DateTime.Now;
            string? requestId = null;

            try
            {
                _logger.LogInformation("Nhận được tin nhắn WebSocket");
                _logger.LogDebug("Nội dung tin nhắn: {Message}", message);

                var request = JsonConvert.DeserializeObject<QueryRequest>(message);
                if (request == null)
                {
                    _logger.LogWarning("Định dạng tin nhắn không hợp lệ");
                    return;
                }

                // Kiểm tra và tạo QueryId nếu chưa có
                if (string.IsNullOrEmpty(request.QueryId))
                {
                    request.QueryId = Guid.NewGuid().ToString();
                    _logger.LogInformation("Tạo mới QueryId: {QueryId}", request.QueryId);
                }

                requestId = request.QueryId;
                
                // Kiểm tra requestId trước khi thêm vào dictionary
                if (!string.IsNullOrEmpty(requestId))
                {
                    _activeRequests.TryAdd(requestId, startTime);
                    Interlocked.Increment(ref _currentActiveConnections);

                    // Xử lý yêu cầu bất đồng bộ
                    var response = await _messageProcessor.ProcessRequestAsync(request);

                    // Log thông tin bệnh nhân từ kết quả truy vấn
                    if (response.Success && response.Data is List<Dictionary<string, object>> resultList && resultList.Count > 0)
                    {
                        _logger.LogInformation("Đã nhận kết quả truy vấn với {Count} bệnh nhân", resultList.Count);
                        
                        foreach (var row in resultList)
                        {
                            // Lấy thông tin bệnh nhân
                            string patientId = GetValueOrDefault(row, "SoVaoVien", "");
                            string patientName = GetValueOrDefault(row, "TenBenhNhan", "");
                            string department = GetValueOrDefault(row, "TenPhongBan", "");
                            string admissionTime = GetValueOrDefault(row, "ThoiGianVao", "");
                            
                            // Log thông tin bệnh nhân
                            _logger.LogInformation("Đã gửi bệnh nhân_ID: {PatientId}, Tên: {PatientName}, Khoa: {Department}, Thời gian vào: {AdmissionTime}", 
                                patientId, patientName, department, admissionTime);
                        }
                    }
                    else if (!response.Success)
                    {
                        _logger.LogWarning("Truy vấn không thành công: {Message}", response.Message);
                    }

                    // Gửi kết quả
                    if (_client?.IsRunning == true)
                    {
                        var jsonResponse = JsonConvert.SerializeObject(response, new JsonSerializerSettings
                        {
                            ReferenceLoopHandling = ReferenceLoopHandling.Ignore,
                            NullValueHandling = NullValueHandling.Include,
                            Formatting = Formatting.Indented
                        });
                        
                        await _client.SendInstant(jsonResponse);
                        _logger.LogDebug("Đã gửi phản hồi: {Response}", jsonResponse);
                    }

                    Interlocked.Increment(ref _totalMessagesProcessed);
                }
                else
                {
                    _logger.LogWarning("Không thể xử lý tin nhắn: QueryId không hợp lệ");
                    // Có thể gửi thông báo lỗi về client
                    if (_client?.IsRunning == true)
                    {
                        var errorResponse = new QueryResponse
                        {
                            QueryId = "ERROR",
                            Success = false,
                            Message = "QueryId không hợp lệ"
                        };
                        await _client.SendInstant(JsonConvert.SerializeObject(errorResponse));
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi xử lý tin nhắn WebSocket: {Error}", ex.Message);
                
                // Gửi thông báo lỗi về client
                if (_client?.IsRunning == true)
                {
                    var errorResponse = new QueryResponse
                    {
                        QueryId = requestId ?? "ERROR",
                        Success = false,
                        Message = $"Lỗi xử lý: {ex.Message}"
                    };
                    await _client.SendInstant(JsonConvert.SerializeObject(errorResponse));
                }
            }
            finally
            {
                if (!string.IsNullOrEmpty(requestId))
                {
                    _activeRequests.TryRemove(requestId, out _);
                    Interlocked.Decrement(ref _currentActiveConnections);
                }

                // Ghi nhận thời gian xử lý
                var processingTime = DateTime.Now - startTime;
                _processingTimes.Enqueue((startTime, processingTime));

                // Giới hạn kích thước history
                while (_processingTimes.Count > MAX_PROCESSING_TIMES_HISTORY)
                {
                    _processingTimes.TryDequeue(out _);
                }
            }
        }

        /// <summary>
        /// Lấy giá trị từ Dictionary với xử lý null
        /// </summary>
        private string GetValueOrDefault(Dictionary<string, object> row, string key, string defaultValue)
        {
            if (row.TryGetValue(key, out var value) && value != null)
            {
                return value.ToString() ?? defaultValue;
            }
            return defaultValue;
        }

        /// <summary>
        /// Lấy thông tin trạng thái kết nối WebSocket
        /// </summary>
        /// <returns>Đối tượng chứa thông tin trạng thái</returns>
        public WebSocketStatusInfo GetStatus()
        {
            return new WebSocketStatusInfo
            {
                IsConnected = _client?.IsRunning ?? false,
                ConnectionStatus = _connectionStatus,
                ServerUrl = _serverUrl,
                LastConnectedTime = _lastConnectedTime,
                LastDisconnectedTime = _lastDisconnectedTime,
                ReconnectAttempts = _reconnectAttempts,
                MessagesReceived = _messagesReceived,
                MessagesSent = _messagesSent,
                LastErrorMessage = _lastErrorMessage
            };
        }

        /// <summary>
        /// Gửi tin nhắn ping để kiểm tra kết nối
        /// </summary>
        /// <returns>True nếu ping thành công, ngược lại là False</returns>
        public async Task<bool> PingAsync()
        {
            if (_client == null || !_client.IsRunning)
            {
                _logger.LogWarning("Không thể ping: WebSocket không hoạt động");
                return false;
            }

            try
            {
                var pingMessage = new { type = "ping", timestamp = DateTime.Now };
                var json = JsonConvert.SerializeObject(pingMessage);
                await _client.SendInstant(json);
                _messagesSent++;
                _logger.LogInformation("Đã gửi ping thành công");
                return true;
            }
            catch (Exception ex)
            {
                _lastErrorMessage = ex.Message;
                _logger.LogError(ex, "Lỗi gửi ping: {Error}", ex.Message);
                return false;
            }
        }

        /// <summary>
        /// Lấy thông tin hiệu suất xử lý
        /// </summary>
        public PerformanceMetrics GetPerformanceMetrics()
        {
            var processingTimes = _processingTimes.ToArray();
            var avgProcessingTime = processingTimes.Length > 0 
                ? TimeSpan.FromTicks((long)processingTimes.Average(x => x.ProcessingTime.Ticks))
                : TimeSpan.Zero;

            return new PerformanceMetrics
            {
                TotalMessagesProcessed = _totalMessagesProcessed,
                CurrentActiveConnections = _currentActiveConnections,
                AverageProcessingTime = avgProcessingTime,
                PendingRequests = _messageProcessor.GetPendingRequestsCount(),
                ActiveRequestIds = _activeRequests.Keys.ToList()
            };
        }

        // Thêm phương thức gửi tin nhắn
        public async Task SendMessageAsync(string message)
        {
            if (!_isRunning || _client == null)
            {
                throw new InvalidOperationException("WebSocket chưa được khởi động");
            }

            try
            {
                _logger.LogInformation("Gửi tin nhắn WebSocket");
                _logger.LogDebug("Nội dung tin nhắn: {Message}", message);
                
                await _client.SendInstant(message);
                
                _logger.LogInformation("Đã gửi tin nhắn thành công");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi gửi tin nhắn WebSocket: {Error}", ex.Message);
                throw;
            }
        }

        /// <summary>
        /// Giải phóng tài nguyên
        /// </summary>
        public void Dispose()
        {
            _cancellationTokenSource.Cancel();
            _client?.Dispose();
            _cancellationTokenSource.Dispose();
        }

        /// <summary>
        /// Giám sát kết nối WebSocket
        /// </summary>
        private async Task MonitorConnectionLoopAsync()
        {
            try
            {
                while (!_cancellationTokenSource.IsCancellationRequested && _isRunning)
                {
                    if (_client != null)
                    {
                        if (!_client.IsRunning)
                        {
                            _logger.LogWarning("WebSocket không hoạt động, đang thử kết nối lại...");
                            await _client.Reconnect();
                        }
                    }
                    
                    await Task.Delay(5000, _cancellationTokenSource.Token);
                }
            }
            catch (OperationCanceledException)
            {
                // Bỏ qua khi task bị hủy
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi giám sát kết nối WebSocket: {Error}", ex.Message);
            }
        }

        // Thêm phương thức đồng bộ để làm mới cấu hình
        public void RefreshConfigSync()
        {
            try
            {
                UpdateConfigFromGoogleSheetsAsync().GetAwaiter().GetResult();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi làm mới cấu hình WebSocket: {Error}", ex.Message);
            }
        }
    }

    /// <summary>
    /// Trạng thái kết nối WebSocket
    /// </summary>
    public enum WebSocketConnectionStatus
    {
        Disconnected,
        Connecting,
        Connected,
        Error
    }
} 