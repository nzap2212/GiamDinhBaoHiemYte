using adapter_BHYT.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Serilog;

namespace adapter_BHYT
{
    internal class Program
    {
        static async Task Main(string[] args)
        {
            // Cấu hình Serilog
            Log.Logger = new LoggerConfiguration()
                .MinimumLevel.Information()
                .WriteTo.Console()
                .WriteTo.File("logs/adapter.log", rollingInterval: RollingInterval.Day)
                .CreateLogger();

            try
            {
                // Tạo host
                using var host = CreateHostBuilder(args).Build();
                
                // Lấy ConsoleService từ DI container
                var consoleService = host.Services.GetRequiredService<ConsoleService>();
                
                // Chạy ứng dụng
                await consoleService.RunAsync();
            }
            catch (Exception ex)
            {
                Log.Fatal(ex, "Ứng dụng bị lỗi và dừng lại");
            }
            finally
            {
                Log.CloseAndFlush();
            }
        }

        static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureAppConfiguration((hostingContext, config) =>
                {
                    config.AddJsonFile("appsettings.json", optional: false, reloadOnChange: true);
                })
                .ConfigureServices((hostContext, services) =>
                {
                    // Đăng ký các service theo thứ tự phụ thuộc
                    services.AddSingleton<GoogleSheetsService>();
                    services.AddSingleton<DatabaseService>();
                    services.AddSingleton<MessageProcessor>();
                    services.AddSingleton<WebSocketService>();
                    services.AddSingleton<ConsoleService>();
                })
                .ConfigureLogging((hostingContext, logging) =>
                {
                    logging.ClearProviders();
                    logging.AddConsole();
                    logging.AddSerilog();
                })
                .UseSerilog();
    }
}
