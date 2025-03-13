using adapter_BHYT.Models;
using adapter_BHYT.Utils;
using Microsoft.Extensions.Logging;
using System.IO;
using Newtonsoft.Json.Linq;
using System.Text;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace adapter_BHYT.Services
{
    /// <summary>
    /// Service xử lý giao diện console
    /// </summary>
    public class ConsoleService
    {
        private readonly ILogger<ConsoleService> _logger;
        private readonly WebSocketService _webSocketService;
        private readonly DatabaseService _databaseService;
        private readonly GoogleSheetsService _googleSheetsService;
        private bool _isRunning = false;
        private readonly CancellationTokenSource _cancellationTokenSource = new CancellationTokenSource();

        /// <summary>
        /// Khởi tạo ConsoleService
        /// </summary>
        /// <param name="logger">Logger</param>
        /// <param name="webSocketService">Service xử lý WebSocket</param>
        /// <param name="databaseService">Service xử lý cơ sở dữ liệu</param>
        /// <param name="googleSheetsService">Service xử lý Google Sheets</param>
        public ConsoleService(
            ILogger<ConsoleService> logger,
            WebSocketService webSocketService,
            DatabaseService databaseService,
            GoogleSheetsService googleSheetsService)
        {
            _logger = logger;
            _webSocketService = webSocketService;
            _databaseService = databaseService;
            _googleSheetsService = googleSheetsService;
        }

        /// <summary>
        /// Chạy ứng dụng console
        /// </summary>
        public async Task RunAsync()
        {
            // Cấu hình console để hiển thị tiếng Việt
            ConsoleHelper.ConfigureConsoleForVietnamese();
            
            ConsoleHelper.DisplayHeader("ỨNG DỤNG ADAPTER BHYT");
            
            // Hiển thị menu chính
            while (!_cancellationTokenSource.Token.IsCancellationRequested)
            {
                string[] options = {
                    "Khởi động dịch vụ",
                    "Dừng dịch vụ",
                    "Xem trạng thái hệ thống",
                    "Xem trạng thái kết nối WebSocket",
                    "Làm mới cấu hình API",
                    "Kiểm tra kết nối cơ sở dữ liệu",
                    "Cấu hình kết nối cơ sở dữ liệu",
                    "Thông tin ứng dụng",
                    "Thông tin hiệu suất xử lý",
                    "Thoát"
                };
                
                int choice = ConsoleHelper.ShowMenu("MENU CHÍNH", options);
                
                switch (choice)
                {
                    case 0: // Khởi động dịch vụ
                        await StartServiceAsync();
                        break;
                        
                    case 1: // Dừng dịch vụ
                        await StopServiceAsync();
                        break;
                        
                    case 2: // Xem trạng thái hệ thống
                        ShowStatus();
                        break;
                        
                    case 3: // Xem trạng thái kết nối WebSocket
                        ShowWebSocketStatus();
                        break;
                        
                    case 4: // Làm mới cấu hình API
                        await RefreshConfigAsync();
                        break;
                        
                    case 5: // Kiểm tra kết nối cơ sở dữ liệu
                        await TestDatabaseConnectionAsync();
                        break;
                        
                    case 6: // Cấu hình kết nối cơ sở dữ liệu
                        ConfigureDatabaseConnection();
                        break;
                        
                    case 7: // Thông tin ứng dụng
                        ShowAbout();
                        break;
                        
                    case 8: // Thông tin hiệu suất xử lý
                        ShowPerformanceMetrics();
                        break;
                        
                    case 9: // Thoát
                        await ExitApplicationAsync();
                        return;
                }
            }
        }

        /// <summary>
        /// Khởi động dịch vụ
        /// </summary>
        private async Task StartServiceAsync()
        {
            if (_isRunning)
            {
                Console.Clear();
                ConsoleHelper.ColoredMessage("Dịch vụ đã đang chạy!", ConsoleColor.Yellow);
                Thread.Sleep(1000);
                return;
            }

            try
            {
                Console.Clear();
                ConsoleHelper.DisplayHeader("KHỞI ĐỘNG DỊCH VỤ");
                
                // Kiểm tra kết nối cơ sở dữ liệu
                ConsoleHelper.ColoredMessage("Đang kiểm tra kết nối cơ sở dữ liệu...", ConsoleColor.Cyan);
                bool dbConnected = await _databaseService.TestConnectionAsync();
                if (!dbConnected)
                {
                    ConsoleHelper.ColoredMessage("Không thể kết nối đến cơ sở dữ liệu. Vui lòng kiểm tra cấu hình.", ConsoleColor.Red);
                    Thread.Sleep(2000);
                    return;
                }
                
                // Khởi động cập nhật cấu hình
                ConsoleHelper.ColoredMessage("Đang khởi động dịch vụ cập nhật cấu hình...", ConsoleColor.Cyan);
                _googleSheetsService.StartConfigRefresh();
                
                // Khởi động WebSocket
                ConsoleHelper.ColoredMessage("Đang khởi động kết nối WebSocket...", ConsoleColor.Cyan);
                await _webSocketService.StartAsync();
                
                _isRunning = true;
                ConsoleHelper.ColoredMessage("Dịch vụ đã khởi động thành công!", ConsoleColor.Green);
                Thread.Sleep(1000);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi khởi động dịch vụ: {Error}", ex.Message);
                ConsoleHelper.ColoredMessage($"Lỗi khi khởi động dịch vụ: {ex.Message}", ConsoleColor.Red);
                Thread.Sleep(2000);
            }
        }

        /// <summary>
        /// Dừng dịch vụ
        /// </summary>
        private async Task StopServiceAsync()
        {
            if (!_isRunning)
            {
                Console.Clear();
                ConsoleHelper.ColoredMessage("Dịch vụ chưa được khởi động!", ConsoleColor.Yellow);
                Thread.Sleep(1000);
                return;
            }

            try
            {
                Console.Clear();
                ConsoleHelper.DisplayHeader("DỪNG DỊCH VỤ");
                
                // Dừng WebSocket
                ConsoleHelper.ColoredMessage("Đang dừng kết nối WebSocket...", ConsoleColor.Cyan);
                await _webSocketService.StopAsync();
                
                // Dừng cập nhật cấu hình
                ConsoleHelper.ColoredMessage("Đang dừng dịch vụ cập nhật cấu hình...", ConsoleColor.Cyan);
                _googleSheetsService.StopConfigRefresh();
                
                _isRunning = false;
                ConsoleHelper.ColoredMessage("Dịch vụ đã dừng thành công!", ConsoleColor.Green);
                Thread.Sleep(1000);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi dừng dịch vụ: {Error}", ex.Message);
                ConsoleHelper.ColoredMessage($"Lỗi khi dừng dịch vụ: {ex.Message}", ConsoleColor.Red);
                Thread.Sleep(2000);
            }
        }

        /// <summary>
        /// Hiển thị trạng thái hệ thống
        /// </summary>
        private void ShowStatus()
        {
            Console.Clear();
            ConsoleHelper.DisplayHeader("TRẠNG THÁI HỆ THỐNG");
            
            Console.WriteLine($"Thời gian hiện tại: {DateTime.Now}");
            Console.WriteLine();
            
            Console.Write("Trạng thái dịch vụ: ");
            if (_isRunning)
            {
                ConsoleHelper.ColoredMessage("ĐANG CHẠY", ConsoleColor.Green);
            }
            else
            {
                ConsoleHelper.ColoredMessage("DỪNG", ConsoleColor.Red);
            }
            
            // Thêm thông tin trạng thái WebSocket
            var wsStatus = _webSocketService.GetStatus();
            Console.Write("Trạng thái WebSocket: ");
            switch (wsStatus.ConnectionStatus)
            {
                case WebSocketConnectionStatus.Connected:
                    ConsoleHelper.ColoredMessage("ĐÃ KẾT NỐI", ConsoleColor.Green);
                    break;
                case WebSocketConnectionStatus.Connecting:
                    ConsoleHelper.ColoredMessage("ĐANG KẾT NỐI", ConsoleColor.Yellow);
                    break;
                case WebSocketConnectionStatus.Disconnected:
                    ConsoleHelper.ColoredMessage("NGẮT KẾT NỐI", ConsoleColor.Red);
                    break;
                case WebSocketConnectionStatus.Error:
                    ConsoleHelper.ColoredMessage("LỖI", ConsoleColor.Red);
                    break;
            }
            
            var config = _googleSheetsService.GetConfig();
            Console.WriteLine($"Số lượng cấu hình API: {config.ConfigItems.Count}");
            Console.WriteLine($"Cập nhật cấu hình lần cuối: {(config.LastUpdated == DateTime.MinValue ? "Chưa cập nhật" : config.LastUpdated.ToString())}");
            
            Console.WriteLine("\nNhấn phím bất kỳ để quay lại...");
            Console.ReadKey();
        }

        /// <summary>
        /// Làm mới cấu hình API
        /// </summary>
        private async Task RefreshConfigAsync()
        {
            Console.Clear();
            ConsoleHelper.DisplayHeader("LÀM MỚI CẤU HÌNH API");
            
            try
            {
                ConsoleHelper.ColoredMessage("Đang cập nhật cấu hình từ Google Sheets...", ConsoleColor.Cyan);
                await _googleSheetsService.RefreshConfigAsync();
                
                var config = _googleSheetsService.GetConfig();
                ConsoleHelper.DisplayTable("CẤU HÌNH API ĐÃ CẬP NHẬT", config.ConfigItems);
                
                ConsoleHelper.ColoredMessage("Cấu hình đã được cập nhật thành công!", ConsoleColor.Green);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi cập nhật cấu hình: {Error}", ex.Message);
                ConsoleHelper.ColoredMessage($"Lỗi khi cập nhật cấu hình: {ex.Message}", ConsoleColor.Red);
            }
            
            Console.WriteLine("\nNhấn phím bất kỳ để quay lại...");
            Console.ReadKey();
        }

        /// <summary>
        /// Kiểm tra kết nối cơ sở dữ liệu
        /// </summary>
        private async Task TestDatabaseConnectionAsync()
        {
            Console.Clear();
            ConsoleHelper.DisplayHeader("KIỂM TRA KẾT NỐI CƠ SỞ DỮ LIỆU");
            
            ConsoleHelper.ColoredMessage("Đang kiểm tra kết nối...", ConsoleColor.Cyan);
            bool connected = await _databaseService.TestConnectionAsync();
            
            if (connected)
            {
                ConsoleHelper.ColoredMessage("Kết nối đến cơ sở dữ liệu thành công!", ConsoleColor.Green);
            }
            else
            {
                ConsoleHelper.ColoredMessage("Không thể kết nối đến cơ sở dữ liệu. Vui lòng kiểm tra cấu hình.", ConsoleColor.Red);
            }
            
            Console.WriteLine("\nNhấn phím bất kỳ để quay lại...");
            Console.ReadKey();
        }

        /// <summary>
        /// Hiển thị thông tin về ứng dụng
        /// </summary>
        private void ShowAbout()
        {
            Console.Clear();
            ConsoleHelper.DisplayHeader("THÔNG TIN ỨNG DỤNG");
            
            Console.WriteLine("Tên ứng dụng: Adapter BHYT");
            Console.WriteLine("Phiên bản: 1.0.0");
            Console.WriteLine("Mô tả: Ứng dụng kết nối cơ sở dữ liệu bệnh viện với server Node.js");
            
            Console.WriteLine("\nChức năng chính:");
            Console.WriteLine("- Kết nối với server Node.js thông qua WebSocket");
            Console.WriteLine("- Thực thi truy vấn SQL dựa trên yêu cầu từ server");
            Console.WriteLine("- Tự động cập nhật cấu hình API từ Google Sheets");
            
            Console.WriteLine("\nNhấn phím bất kỳ để quay lại...");
            Console.ReadKey();
        }

        /// <summary>
        /// Thoát ứng dụng
        /// </summary>
        private async Task ExitApplicationAsync()
        {
            Console.Clear();
            ConsoleHelper.DisplayHeader("THOÁT ỨNG DỤNG");
            
            if (_isRunning)
            {
                ConsoleHelper.ColoredMessage("Đang dừng dịch vụ trước khi thoát...", ConsoleColor.Cyan);
                await StopServiceAsync();
            }
            
            ConsoleHelper.ColoredMessage("Cảm ơn bạn đã sử dụng ứng dụng!", ConsoleColor.Green);
            _cancellationTokenSource.Cancel();
            Thread.Sleep(1000);
        }

        /// <summary>
        /// Hiển thị trạng thái kết nối WebSocket
        /// </summary>
        private void ShowWebSocketStatus()
        {
            var status = _webSocketService.GetStatus();
            ConsoleHelper.DisplayWebSocketStatus(status);
        }

        private async Task TestWebSocketConnectionAsync()
        {
            Console.Clear();
            ConsoleHelper.DisplayHeader("KIỂM TRA KẾT NỐI WEBSOCKET");
            
            var status = _webSocketService.GetStatus();
            
            if (!status.IsConnected)
            {
                ConsoleHelper.ColoredMessage("WebSocket chưa được kết nối. Vui lòng khởi động dịch vụ trước.", ConsoleColor.Yellow);
                Console.WriteLine("\nNhấn phím bất kỳ để quay lại...");
                Console.ReadKey();
                return;
            }
            
            ConsoleHelper.ColoredMessage("Đang gửi ping đến server...", ConsoleColor.Cyan);
            bool pingSuccess = await _webSocketService.PingAsync();
            
            if (pingSuccess)
            {
                ConsoleHelper.ColoredMessage("Ping thành công! Kết nối WebSocket hoạt động bình thường.", ConsoleColor.Green);
            }
            else
            {
                ConsoleHelper.ColoredMessage("Ping thất bại! Có vấn đề với kết nối WebSocket.", ConsoleColor.Red);
            }
            
            Console.WriteLine("\nNhấn phím bất kỳ để quay lại...");
            Console.ReadKey();
        }

        private void ConfigureDatabaseConnection()
        {
            Console.Clear();
            ConsoleHelper.DisplayHeader("CẤU HÌNH KẾT NỐI CƠ SỞ DỮ LIỆU");
            
            string[] options = {
                "Sử dụng Windows Authentication",
                "Sử dụng SQL Server Authentication",
                "Quay lại"
            };
            
            int choice = ConsoleHelper.ShowMenu("CHỌN LOẠI XÁC THỰC", options);
            
            switch (choice)
            {
                case 0: // Windows Authentication
                    ConfigureWindowsAuthentication();
                    break;
                    
                case 1: // SQL Server Authentication
                    ConfigureSqlServerAuthentication();
                    break;
                    
                case 2: // Quay lại
                    return;
            }
        }

        private void ConfigureWindowsAuthentication()
        {
            Console.Clear();
            ConsoleHelper.DisplayHeader("CẤU HÌNH WINDOWS AUTHENTICATION");
            
            Console.Write("Nhập tên server SQL: ");
            string server = Console.ReadLine() ?? "localhost";
            
            Console.Write("Nhập tên database: ");
            string database = Console.ReadLine() ?? "";
            
            // Cập nhật file appsettings.json
            UpdateAppSettings(false, server, database, "", "");
            
            ConsoleHelper.ColoredMessage("Đã cập nhật cấu hình kết nối thành công!", ConsoleColor.Green);
            Thread.Sleep(1000);
        }

        private void ConfigureSqlServerAuthentication()
        {
            Console.Clear();
            ConsoleHelper.DisplayHeader("CẤU HÌNH SQL SERVER AUTHENTICATION");
            
            Console.Write("Nhập tên server SQL: ");
            string server = Console.ReadLine() ?? "localhost";
            
            Console.Write("Nhập tên database: ");
            string database = Console.ReadLine() ?? "";
            
            Console.Write("Nhập tên đăng nhập: ");
            string userId = Console.ReadLine() ?? "";
            
            Console.Write("Nhập mật khẩu: ");
            string password = ReadPassword();
            
            // Cập nhật file appsettings.json
            UpdateAppSettings(true, server, database, userId, password);
            
            ConsoleHelper.ColoredMessage("Đã cập nhật cấu hình kết nối thành công!", ConsoleColor.Green);
            Thread.Sleep(1000);
        }

        private string ReadPassword()
        {
            var password = new StringBuilder();
            while (true)
            {
                var key = Console.ReadKey(true);
                if (key.Key == ConsoleKey.Enter)
                    break;
                if (key.Key == ConsoleKey.Backspace && password.Length > 0)
                {
                    password.Remove(password.Length - 1, 1);
                    Console.Write("\b \b");
                }
                else if (!char.IsControl(key.KeyChar))
                {
                    password.Append(key.KeyChar);
                    Console.Write("*");
                }
            }
            Console.WriteLine();
            return password.ToString();
        }

        private void UpdateAppSettings(bool useSqlAuth, string server, string database, string userId, string password)
        {
            try
            {
                string appSettingsPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "appsettings.json");
                string json = File.ReadAllText(appSettingsPath);
                
                JObject appSettings = JObject.Parse(json);
                
                // Cập nhật cấu hình Database
                if (appSettings["Database"] == null)
                    appSettings["Database"] = new JObject();
                    
                appSettings["Database"]["UseSqlAuthentication"] = useSqlAuth;
                appSettings["Database"]["Server"] = server;
                appSettings["Database"]["Database"] = database;
                
                if (useSqlAuth)
                {
                    appSettings["Database"]["UserId"] = userId;
                    appSettings["Database"]["Password"] = password;
                    
                    // Cập nhật ConnectionStrings
                    if (appSettings["ConnectionStrings"] == null)
                        appSettings["ConnectionStrings"] = new JObject();
                        
                    appSettings["ConnectionStrings"]["DefaultConnection"] = 
                        $"Server={server};Database={database};User Id={userId};Password={password};TrustServerCertificate=True;";
                }
                else
                {
                    // Cập nhật ConnectionStrings cho Windows Authentication
                    if (appSettings["ConnectionStrings"] == null)
                        appSettings["ConnectionStrings"] = new JObject();
                        
                    appSettings["ConnectionStrings"]["DefaultConnection"] = 
                        $"Server={server};Database={database};Trusted_Connection=True;TrustServerCertificate=True;";
                }
                
                // Lưu lại file
                File.WriteAllText(appSettingsPath, appSettings.ToString(Formatting.Indented));
                
                // Thông báo cần khởi động lại ứng dụng
                ConsoleHelper.ColoredMessage("Cấu hình đã được cập nhật. Vui lòng khởi động lại ứng dụng để áp dụng thay đổi.", ConsoleColor.Yellow);
                Thread.Sleep(2000);
            }
            catch (Exception ex)
            {
                ConsoleHelper.ColoredMessage($"Lỗi khi cập nhật cấu hình: {ex.Message}", ConsoleColor.Red);
                Thread.Sleep(2000);
            }
        }

        private void ShowPerformanceMetrics()
        {
            Console.Clear();
            ConsoleHelper.DisplayHeader("THÔNG TIN HIỆU SUẤT XỬ LÝ");

            var metrics = _webSocketService.GetPerformanceMetrics();
            
            Console.WriteLine($"Tổng số tin nhắn đã xử lý: {metrics.TotalMessagesProcessed}");
            Console.WriteLine($"Số kết nối đang hoạt động: {metrics.CurrentActiveConnections}");
            Console.WriteLine($"Thời gian xử lý trung bình: {metrics.AverageProcessingTime.TotalMilliseconds:F2}ms");
            Console.WriteLine($"Số yêu cầu đang chờ xử lý: {metrics.PendingRequests}");
            
            if (metrics.ActiveRequestIds.Any())
            {
                Console.WriteLine("\nCác yêu cầu đang xử lý:");
                foreach (var requestId in metrics.ActiveRequestIds)
                {
                    Console.WriteLine($"- {requestId}");
                }
            }

            Console.WriteLine("\nNhấn phím bất kỳ để quay lại...");
            Console.ReadKey();
        }

        public void Start()
        {
            bool exit = false;
            while (!exit)
            {
                Console.Clear();
                ConsoleHelper.DisplayHeader("ADAPTER BHYT - MENU CHÍNH");
                
                Console.WriteLine("1. Khởi động WebSocket");
                Console.WriteLine("2. Dừng WebSocket");
                Console.WriteLine("3. Kiểm tra trạng thái WebSocket");
                Console.WriteLine("4. Gửi tin nhắn kiểm tra");
                Console.WriteLine("5. Xem thông tin hiệu suất");
                Console.WriteLine("6. Làm mới cấu hình từ Google Sheets");
                Console.WriteLine("0. Thoát");
                
                Console.Write("\nNhập lựa chọn của bạn: ");
                string? choice = Console.ReadLine();
                
                switch (choice)
                {
                    case "1":
                        StartWebSocketHandler();
                        break;
                    case "2":
                        StopWebSocketHandler();
                        break;
                    case "3":
                        CheckWebSocketStatusHandler();
                        break;
                    case "4":
                        SendTestMessageHandler();
                        break;
                    case "5":
                        ShowPerformanceMetrics();
                        break;
                    case "6":
                        RefreshConfig();
                        break;
                    case "0":
                        exit = true;
                        break;
                    default:
                        Console.WriteLine("Lựa chọn không hợp lệ. Vui lòng thử lại.");
                        Console.ReadKey();
                        break;
                }
            }
        }

        private async void StartWebSocketHandler()
        {
            Console.Clear();
            ConsoleHelper.DisplayHeader("KHỞI ĐỘNG WEBSOCKET");
            
            try
            {
                Console.WriteLine("Đang khởi động WebSocket...");
                await _webSocketService.StartAsync();
                Console.WriteLine("\nWebSocket đã khởi động thành công!");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"\nLỗi khởi động WebSocket: {ex.Message}");
            }
            
            Console.WriteLine("\nNhấn phím bất kỳ để quay lại...");
            Console.ReadKey();
        }

        private async void StopWebSocketHandler()
        {
            Console.Clear();
            ConsoleHelper.DisplayHeader("DỪNG WEBSOCKET");
            
            try
            {
                Console.WriteLine("Đang dừng WebSocket...");
                await _webSocketService.StopAsync();
                Console.WriteLine("\nWebSocket đã dừng thành công!");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"\nLỗi dừng WebSocket: {ex.Message}");
            }
            
            Console.WriteLine("\nNhấn phím bất kỳ để quay lại...");
            Console.ReadKey();
        }

        private void CheckWebSocketStatusHandler()
        {
            Console.Clear();
            ConsoleHelper.DisplayHeader("TRẠNG THÁI WEBSOCKET");
            
            bool isRunning = _webSocketService.IsRunning;
            Console.WriteLine($"WebSocket đang {(isRunning ? "chạy" : "dừng")}");
            
            if (isRunning)
            {
                Console.WriteLine($"URL: {_webSocketService.ServerUrl}");
                Console.WriteLine($"Thời gian kết nối lại: {_webSocketService.ReconnectInterval}ms");
            }
            
            Console.WriteLine("\nNhấn phím bất kỳ để quay lại...");
            Console.ReadKey();
        }

        private async void SendTestMessageHandler()
        {
            Console.Clear();
            ConsoleHelper.DisplayHeader("GỬI TIN NHẮN KIỂM TRA");
            
            if (!_webSocketService.IsRunning)
            {
                Console.WriteLine("WebSocket chưa được khởi động. Vui lòng khởi động trước khi gửi tin nhắn.");
                Console.WriteLine("\nNhấn phím bất kỳ để quay lại...");
                Console.ReadKey();
                return;
            }
            
            Console.WriteLine("Nhập nội dung tin nhắn (để trống để sử dụng tin nhắn mặc định):");
            string? message = Console.ReadLine();
            
            if (string.IsNullOrEmpty(message))
            {
                message = "{\"QueryId\":\"test-" + Guid.NewGuid().ToString() + "\",\"QueryType\":\"ping\"}";
                Console.WriteLine($"Sử dụng tin nhắn mặc định: {message}");
            }
            
            try
            {
                Console.WriteLine("Đang gửi tin nhắn...");
                await _webSocketService.SendMessageAsync(message);
                Console.WriteLine("\nĐã gửi tin nhắn thành công!");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"\nLỗi gửi tin nhắn: {ex.Message}");
            }
            
            Console.WriteLine("\nNhấn phím bất kỳ để quay lại...");
            Console.ReadKey();
        }

        private void RefreshConfig()
        {
            Console.Clear();
            ConsoleHelper.DisplayHeader("LÀM MỚI CẤU HÌNH");
            
            Console.WriteLine("Đang làm mới cấu hình từ Google Sheets...");
            
            try
            {
                // Lấy cấu hình hiện tại - sửa GetConfig thành GetConfigSync
                var config = _googleSheetsService.GetConfigSync();
                Console.WriteLine($"\nCấu hình hiện tại (Cập nhật lúc: {config.LastUpdated}):");
                foreach (var item in config.ConfigItems)
                {
                    Console.WriteLine($"{item.Key} = {item.Value}");
                }
                
                // Làm mới cấu hình
                _googleSheetsService.RefreshConfigSync();
                Console.WriteLine("\nĐã làm mới cấu hình thành công!");
                
                // Hiển thị cấu hình sau khi làm mới - sửa GetConfig thành GetConfigSync
                config = _googleSheetsService.GetConfigSync();
                Console.WriteLine($"\nCấu hình mới (Cập nhật lúc: {config.LastUpdated}):");
                foreach (var item in config.ConfigItems)
                {
                    Console.WriteLine($"{item.Key} = {item.Value}");
                }
                
                // Cập nhật WebSocket nếu cần
                _webSocketService.RefreshConfigSync();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"\nLỗi làm mới cấu hình: {ex.Message}");
            }
            
            Console.WriteLine("\nNhấn phím bất kỳ để quay lại...");
            Console.ReadKey();
        }
    }
} 