using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using adapter_BHYT.Models;

namespace adapter_BHYT.Services
{
    /// <summary>
    /// Service xử lý việc lấy cấu hình từ Google Sheets
    /// </summary>
    public class GoogleSheetsService : IDisposable
    {
        private readonly ILogger<GoogleSheetsService> _logger;
        private readonly IConfiguration _configuration;
        private readonly HttpClient _httpClient;
        private readonly string _apiUrl;
        
        // Cache cho cấu hình API
        private Dictionary<string, string> _apiConfigCache = new Dictionary<string, string>();
        private DateTime _lastConfigUpdate = DateTime.MinValue;
        private readonly TimeSpan _cacheExpiration = TimeSpan.FromMinutes(5);
        private readonly object _lockObject = new object();
        private Timer? _refreshTimer;

        /// <summary>
        /// Khởi tạo GoogleSheetsService
        /// </summary>
        /// <param name="configuration">Cấu hình ứng dụng</param>
        /// <param name="logger">Logger</param>
        public GoogleSheetsService(IConfiguration configuration, ILogger<GoogleSheetsService> logger)
        {
            _logger = logger;
            _configuration = configuration;
            _httpClient = new HttpClient(); // Tạo HttpClient trực tiếp
            
            // Lấy URL API từ cấu hình
            string spreadsheetId = _configuration["GoogleSheets:SpreadsheetId"] ?? "133jgLYeYdIeRf4ynqoI9uwxBhvQq6p4bUwuad_H26LU";
            string sheetName = _configuration["GoogleSheets:ApiConfigSheet"] ?? "manage_api";
            string apiKey = _configuration["GoogleSheets:ApiKey"] ?? "AIzaSyDuHpXoR-1YP3zEHWTEVtBUTl6YSSToBGQ";
            
            _apiUrl = $"https://sheets.googleapis.com/v4/spreadsheets/{spreadsheetId}/values/{sheetName}!A1:B100?key={apiKey}";
            
            // Thiết lập timer để làm mới cấu hình định kỳ
            int refreshIntervalMinutes = _configuration.GetValue<int>("GoogleSheets:RefreshIntervalMinutes", 30);
            _refreshTimer = new Timer(async _ => await RefreshConfigAsync(), null, 
                TimeSpan.Zero, TimeSpan.FromMinutes(refreshIntervalMinutes));
        }

        /// <summary>
        /// Làm mới cấu hình từ Google Sheets
        /// </summary>
        public async Task RefreshConfigAsync()
        {
            try
            {
                _logger.LogInformation("Đang làm mới cấu hình từ Google Sheets...");
                await GetApiConfigAsync(true);
                _logger.LogInformation("Đã làm mới cấu hình từ Google Sheets thành công");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi làm mới cấu hình từ Google Sheets: {Error}", ex.Message);
            }
        }

        /// <summary>
        /// Lấy cấu hình API từ Google Sheets
        /// </summary>
        public async Task<Dictionary<string, string>> GetApiConfigAsync(bool forceRefresh = false)
        {
            // Kiểm tra cache
            if (!forceRefresh && _apiConfigCache.Count > 0 && 
                (DateTime.Now - _lastConfigUpdate) < _cacheExpiration)
            {
                return _apiConfigCache;
            }

            lock (_lockObject)
            {
                // Kiểm tra lại sau khi lock để tránh race condition
                if (!forceRefresh && _apiConfigCache.Count > 0 && 
                    (DateTime.Now - _lastConfigUpdate) < _cacheExpiration)
                {
                    return _apiConfigCache;
                }

                try
                {
                    _logger.LogInformation("Đang tải cấu hình API từ Google Sheets...");
                    
                    // Thực hiện HTTP request
                    var response = _httpClient.GetAsync(_apiUrl).Result;
                    response.EnsureSuccessStatusCode();
                    
                    var content = response.Content.ReadAsStringAsync().Result;
                    _logger.LogDebug("Nhận được phản hồi: {Content}", content);
                    
                    // Parse JSON
                    using var document = JsonDocument.Parse(content);
                    var root = document.RootElement;
                    
                    if (!root.TryGetProperty("values", out var valuesElement))
                    {
                        _logger.LogWarning("Không tìm thấy dữ liệu 'values' trong phản hồi");
                        return new Dictionary<string, string>();
                    }
                    
                    // Xử lý dữ liệu
                    var config = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                    foreach (var row in valuesElement.EnumerateArray())
                    {
                        if (row.GetArrayLength() >= 2)
                        {
                            string key = row[0].GetString() ?? "";
                            string value = row[1].GetString() ?? "";
                            
                            if (!string.IsNullOrEmpty(key))
                            {
                                config[key] = value;
                                _logger.LogDebug("Đã tải cấu hình: {Key} = {Value}", key, value);
                            }
                        }
                    }
                    
                    // Cập nhật cache
                    _apiConfigCache = config;
                    _lastConfigUpdate = DateTime.Now;
                    
                    _logger.LogInformation("Đã tải {Count} cấu hình API từ Google Sheets", config.Count);
                    return config;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Lỗi khi tải cấu hình API từ Google Sheets: {Error}", ex.Message);
                    
                    // Trả về cache cũ nếu có
                    if (_apiConfigCache.Count > 0)
                    {
                        _logger.LogWarning("Sử dụng cấu hình API từ cache");
                        return _apiConfigCache;
                    }
                    
                    return new Dictionary<string, string>();
                }
            }
        }

        /// <summary>
        /// Lấy giá trị cấu hình API theo key
        /// </summary>
        public async Task<string> GetApiConfigValueAsync(string key, string defaultValue = "")
        {
            var config = await GetApiConfigAsync();
            return config.TryGetValue(key, out var value) ? value : defaultValue;
        }

        /// <summary>
        /// Lấy cấu hình API (phiên bản đồng bộ)
        /// </summary>
        public ConfigResult GetConfigSync()
        {
            try
            {
                var config = GetApiConfigAsync(false).GetAwaiter().GetResult();
                return new ConfigResult
                {
                    ConfigItems = config,
                    LastUpdated = _lastConfigUpdate
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi lấy cấu hình: {Error}", ex.Message);
                return new ConfigResult
                {
                    ConfigItems = _apiConfigCache,
                    LastUpdated = _lastConfigUpdate
                };
            }
        }

        /// <summary>
        /// Lấy cấu hình API (phiên bản đồng bộ) - tên thay thế cho GetConfigSync
        /// </summary>
        public ConfigResult GetConfig()
        {
            return GetConfigSync();
        }

        /// <summary>
        /// Làm mới cấu hình API (phiên bản đồng bộ)
        /// </summary>
        public void RefreshConfigSync()
        {
            try
            {
                RefreshConfigAsync().GetAwaiter().GetResult();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi làm mới cấu hình: {Error}", ex.Message);
            }
        }

        /// <summary>
        /// Bắt đầu làm mới cấu hình tự động
        /// </summary>
        public void StartConfigRefresh()
        {
            int refreshIntervalMinutes = _configuration.GetValue<int>("GoogleSheets:RefreshIntervalMinutes", 30);
            _refreshTimer?.Dispose();
            _refreshTimer = new Timer(async _ => await RefreshConfigAsync(), null, 
                TimeSpan.Zero, TimeSpan.FromMinutes(refreshIntervalMinutes));
            _logger.LogInformation("Đã bắt đầu làm mới cấu hình tự động mỗi {Interval} phút", refreshIntervalMinutes);
        }

        /// <summary>
        /// Dừng làm mới cấu hình tự động
        /// </summary>
        public void StopConfigRefresh()
        {
            _refreshTimer?.Dispose();
            _refreshTimer = null;
            _logger.LogInformation("Đã dừng làm mới cấu hình tự động");
        }

        public void Dispose()
        {
            _refreshTimer?.Dispose();
            _httpClient.Dispose(); // Dispose HttpClient khi service bị dispose
        }
    }
} 