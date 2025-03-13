using adapter_BHYT.Models;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Polly;
using System.Data;

namespace adapter_BHYT.Services
{
    /// <summary>
    /// Service xử lý các thao tác với cơ sở dữ liệu
    /// </summary>
    public class DatabaseService
    {
        private readonly string _connectionString;
        private readonly ILogger<DatabaseService> _logger;
        private readonly IAsyncPolicy _retryPolicy;
        private readonly IConfiguration _configuration;

        /// <summary>
        /// Khởi tạo DatabaseService
        /// </summary>
        /// <param name="configuration">Cấu hình ứng dụng</param>
        /// <param name="logger">Logger</param>
        public DatabaseService(IConfiguration configuration, ILogger<DatabaseService> logger)
        {
            _configuration = configuration;
            _connectionString = configuration.GetConnectionString("DefaultConnection") 
                ?? "Server=192.168.1.2;Database=eHospital_ThuyDienUB;User Id=DEV_BV;Password=DEVBV@123#@!;TrustServerCertificate=True;";
            _logger = logger;

            // Tạo chính sách thử lại khi gặp lỗi kết nối
            _retryPolicy = Policy
                .Handle<SqlException>(ex => ex.Number == -2 || ex.Number == 53 || ex.Number == 40613) // Lỗi kết nối
                .Or<TimeoutException>()
                .WaitAndRetryAsync(
                    3, // Số lần thử lại
                    retryAttempt => TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)), // Thời gian chờ tăng dần
                    (exception, timeSpan, retryCount, context) =>
                    {
                        _logger.LogWarning("Lần thử lại {RetryCount} kết nối đến cơ sở dữ liệu sau {RetryTime}s. Lỗi: {Error}",
                            retryCount, timeSpan.TotalSeconds, exception.Message);
                    }
                );
        }

        /// <summary>
        /// Tạo chuỗi kết nối dựa trên cấu hình
        /// </summary>
        /// <returns>Chuỗi kết nối SQL</returns>
        private string GetConnectionString()
        {
            // Kiểm tra xem có sử dụng SQL Authentication hay không
            bool useSqlAuth = _configuration.GetValue<bool>("Database:UseSqlAuthentication", false);
            
            if (useSqlAuth)
            {
                string server = _configuration["Database:Server"] ?? "localhost";
                string database = _configuration["Database:Database"] ?? "";
                string userId = _configuration["Database:UserId"] ?? "";
                string password = _configuration["Database:Password"] ?? "";
                
                return $"Server={server};Database={database};User Id={userId};Password={password};TrustServerCertificate=True;";
            }
            
            // Sử dụng chuỗi kết nối từ ConnectionStrings
            return _connectionString;
        }

        /// <summary>
        /// Thực thi truy vấn SQL dựa trên yêu cầu
        /// </summary>
        /// <param name="request">Yêu cầu truy vấn</param>
        /// <returns>Kết quả truy vấn</returns>
        public async Task<QueryResponse> ExecuteQueryAsync(QueryRequest request)
        {
            var response = new QueryResponse
            {
                QueryId = request.QueryId,
                Success = false,
                ResponseTime = DateTime.Now
            };

            try
            {
                _logger.LogInformation("Thực hiện truy vấn: {QueryType} - {QueryId}", request.QueryType, request.QueryId);
                
                if (string.IsNullOrEmpty(request.SqlQuery))
                {
                    response.Message = "Câu truy vấn SQL không được để trống";
                    return response;
                }

                // Xử lý câu truy vấn SQL
                string sqlQuery = request.SqlQuery;
                
                // Xử lý LIMIT cho SQL Server (chuyển LIMIT thành TOP)
                if (sqlQuery.Contains("LIMIT") && request.Parameters?.ContainsKey("Limit") == true)
                {
                    int limit = Convert.ToInt32(request.Parameters["Limit"]);
                    sqlQuery = sqlQuery.Replace($"LIMIT {limit}", "");
                    
                    // Thêm TOP vào câu SELECT
                    if (sqlQuery.StartsWith("SELECT", StringComparison.OrdinalIgnoreCase))
                    {
                        sqlQuery = sqlQuery.Replace("SELECT", $"SELECT TOP {limit}");
                    }
                }

                using (var connection = new SqlConnection(_connectionString))
                {
                    await connection.OpenAsync();
                    
                    // Xử lý theo loại truy vấn
                    switch (request.QueryType?.ToLower())
                    {
                        case "select":
                            var result = await ExecuteSelectQueryAsync(connection, sqlQuery, request.Parameters);
                            response.Data = result;
                            response.Success = true;
                            response.Message = $"Truy vấn thành công. Số bản ghi: {(result as List<Dictionary<string, object>>)?.Count ?? 0}";
                            break;
                            
                        case "insert":
                        case "update":
                        case "delete":
                            int rowsAffected = await ExecuteNonQueryAsync(connection, sqlQuery, request.Parameters);
                            response.Data = new { RowsAffected = rowsAffected };
                            response.Success = true;
                            response.Message = $"Thực thi thành công. Số bản ghi bị ảnh hưởng: {rowsAffected}";
                            break;
                            
                        default:
                            response.Message = $"Loại truy vấn không hỗ trợ: {request.QueryType}";
                            break;
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi thực hiện truy vấn: {Error}", ex.Message);
                response.Message = $"Lỗi: {ex.Message}";
                response.Data = new { Error = ex.ToString() };
            }

            return response;
        }

        private async Task<List<Dictionary<string, object>>> ExecuteSelectQueryAsync(
            SqlConnection connection, 
            string sqlQuery, 
            Dictionary<string, object>? parameters)
        {
            var result = new List<Dictionary<string, object>>();
            
            using (var command = new SqlCommand(sqlQuery, connection))
            {
                // Thêm parameters nếu có
                if (parameters != null)
                {
                    foreach (var param in parameters)
                    {
                        if (!sqlQuery.Contains($"@{param.Key}"))
                            continue;
                            
                        command.Parameters.AddWithValue($"@{param.Key}", param.Value);
                    }
                }
                
                using (var reader = await command.ExecuteReaderAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        var row = new Dictionary<string, object>();
                        
                        for (int i = 0; i < reader.FieldCount; i++)
                        {
                            string columnName = reader.GetName(i);
                            object value = reader.IsDBNull(i) ? null : reader.GetValue(i);
                            row[columnName] = value;
                        }
                        
                        result.Add(row);
                    }
                }
            }
            
            return result;
        }

        private async Task<int> ExecuteNonQueryAsync(
            SqlConnection connection, 
            string sqlQuery, 
            Dictionary<string, object>? parameters)
        {
            using (var command = new SqlCommand(sqlQuery, connection))
            {
                // Thêm parameters nếu có
                if (parameters != null)
                {
                    foreach (var param in parameters)
                    {
                        if (!sqlQuery.Contains($"@{param.Key}"))
                            continue;
                            
                        command.Parameters.AddWithValue($"@{param.Key}", param.Value);
                    }
                }
                
                return await command.ExecuteNonQueryAsync();
            }
        }

        /// <summary>
        /// Kiểm tra kết nối đến cơ sở dữ liệu
        /// </summary>
        /// <returns>True nếu kết nối thành công, ngược lại là False</returns>
        public async Task<bool> TestConnectionAsync()
        {
            try
            {
                using (var connection = new SqlConnection(GetConnectionString()))
                {
                    await connection.OpenAsync();
                    _logger.LogInformation("Kết nối đến cơ sở dữ liệu thành công");
                    return true;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Không thể kết nối đến cơ sở dữ liệu: {Error}", ex.Message);
                return false;
            }
        }
    }
} 