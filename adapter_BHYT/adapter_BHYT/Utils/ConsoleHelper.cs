using adapter_BHYT.Models;
using adapter_BHYT.Services;
using System.Text;

namespace adapter_BHYT.Utils
{
    /// <summary>
    /// Các tiện ích hỗ trợ hiển thị trong Console
    /// </summary>
    public static class ConsoleHelper
    {
        /// <summary>
        /// Cấu hình Console để hiển thị tiếng Việt
        /// </summary>
        public static void ConfigureConsoleForVietnamese()
        {
            // Đặt mã hóa đầu ra của Console thành UTF-8
            Console.OutputEncoding = Encoding.UTF8;
            
            // Đặt mã hóa đầu vào của Console thành UTF-8
            Console.InputEncoding = Encoding.UTF8;
            
            // Đặt tiêu đề cho cửa sổ Console
            Console.Title = "Adapter BHYT - Hỗ trợ tiếng Việt";
        }

        /// <summary>
        /// Hiển thị thông tin dưới dạng bảng trong Console
        /// </summary>
        /// <param name="title">Tiêu đề bảng</param>
        /// <param name="data">Dữ liệu dạng Dictionary</param>
        public static void DisplayTable(string title, Dictionary<string, string> data)
        {
            if (data == null || data.Count == 0)
            {
                Console.WriteLine("Không có dữ liệu để hiển thị.");
                return;
            }

            // Tìm độ dài lớn nhất của key và value
            int maxKeyLength = data.Keys.Max(k => k.Length);
            int maxValueLength = data.Values.Max(v => v?.Length ?? 0);

            // Đảm bảo độ dài tối thiểu
            maxKeyLength = Math.Max(maxKeyLength, 10);
            maxValueLength = Math.Max(maxValueLength, 10);

            // Tính toán độ rộng của bảng
            int tableWidth = maxKeyLength + maxValueLength + 7; // 7 là độ rộng của các ký tự phân cách

            // Hiển thị tiêu đề
            Console.WriteLine(new string('=', tableWidth));
            Console.WriteLine($"║ {title.PadRight(tableWidth - 4)} ║");
            Console.WriteLine(new string('=', tableWidth));

            // Hiển thị header
            Console.WriteLine($"║ {"Khóa".PadRight(maxKeyLength)} ║ {"Giá trị".PadRight(maxValueLength)} ║");
            Console.WriteLine(new string('-', tableWidth));

            // Hiển thị dữ liệu
            foreach (var item in data)
            {
                string key = item.Key.Length > maxKeyLength ? item.Key.Substring(0, maxKeyLength - 3) + "..." : item.Key;
                string value = item.Value?.Length > maxValueLength ? item.Value.Substring(0, maxValueLength - 3) + "..." : item.Value ?? "";
                
                Console.WriteLine($"║ {key.PadRight(maxKeyLength)} ║ {value.PadRight(maxValueLength)} ║");
            }

            // Hiển thị footer
            Console.WriteLine(new string('=', tableWidth));
        }

        /// <summary>
        /// Hiển thị thông báo với màu sắc
        /// </summary>
        /// <param name="message">Nội dung thông báo</param>
        /// <param name="color">Màu chữ</param>
        public static void ColoredMessage(string message, ConsoleColor color)
        {
            Console.ForegroundColor = color;
            Console.WriteLine(message);
            Console.ResetColor();
        }

        /// <summary>
        /// Hiển thị tiêu đề lớn
        /// </summary>
        /// <param name="title">Nội dung tiêu đề</param>
        public static void DisplayHeader(string title)
        {
            int width = Console.WindowWidth - 4;
            string line = new string('=', width);
            
            Console.WriteLine();
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine(line);
            Console.WriteLine($"  {title}");
            Console.WriteLine(line);
            Console.ResetColor();
            Console.WriteLine();
        }

        /// <summary>
        /// Hiển thị menu và trả về lựa chọn của người dùng
        /// </summary>
        /// <param name="title">Tiêu đề menu</param>
        /// <param name="options">Danh sách các tùy chọn</param>
        /// <returns>Chỉ số của tùy chọn được chọn</returns>
        public static int ShowMenu(string title, string[] options)
        {
            int selectedIndex = 0;
            ConsoleKey key;

            do
            {
                Console.Clear();
                DisplayHeader(title);

                for (int i = 0; i < options.Length; i++)
                {
                    if (i == selectedIndex)
                    {
                        Console.BackgroundColor = ConsoleColor.Cyan;
                        Console.ForegroundColor = ConsoleColor.Black;
                        Console.WriteLine($" >> {options[i]}");
                    }
                    else
                    {
                        Console.ResetColor();
                        Console.WriteLine($"    {options[i]}");
                    }
                }

                Console.ResetColor();
                Console.WriteLine("\nSử dụng phím mũi tên để di chuyển và Enter để chọn");

                key = Console.ReadKey(true).Key;

                if (key == ConsoleKey.UpArrow && selectedIndex > 0)
                {
                    selectedIndex--;
                }
                else if (key == ConsoleKey.DownArrow && selectedIndex < options.Length - 1)
                {
                    selectedIndex++;
                }

            } while (key != ConsoleKey.Enter);

            return selectedIndex;
        }

        /// <summary>
        /// Hiển thị thanh tiến trình
        /// </summary>
        /// <param name="percent">Phần trăm hoàn thành (0-100)</param>
        /// <param name="barSize">Kích thước thanh tiến trình</param>
        public static void ProgressBar(int percent, int barSize = 40)
        {
            Console.CursorLeft = 0;
            Console.Write("[");
            
            int position = barSize * percent / 100;
            
            for (int i = 0; i < barSize; i++)
            {
                if (i < position)
                    Console.Write("=");
                else if (i == position)
                    Console.Write(">");
                else
                    Console.Write(" ");
            }
            
            Console.Write("] " + percent + "%");
        }

        /// <summary>
        /// Hiển thị thông tin trạng thái kết nối WebSocket
        /// </summary>
        /// <param name="status">Thông tin trạng thái</param>
        public static void DisplayWebSocketStatus(WebSocketStatusInfo status)
        {
            Console.Clear();
            DisplayHeader("TRẠNG THÁI KẾT NỐI WEBSOCKET");
            
            Console.WriteLine($"URL máy chủ: {status.ServerUrl}");
            Console.WriteLine();
            
            Console.Write("Trạng thái kết nối: ");
            switch (status.ConnectionStatus)
            {
                case WebSocketConnectionStatus.Connected:
                    ColoredMessage("ĐÃ KẾT NỐI", ConsoleColor.Green);
                    break;
                case WebSocketConnectionStatus.Connecting:
                    ColoredMessage("ĐANG KẾT NỐI", ConsoleColor.Yellow);
                    break;
                case WebSocketConnectionStatus.Disconnected:
                    ColoredMessage("NGẮT KẾT NỐI", ConsoleColor.Red);
                    break;
                case WebSocketConnectionStatus.Error:
                    ColoredMessage("LỖI", ConsoleColor.Red);
                    break;
            }
            
            if (status.LastConnectedTime != DateTime.MinValue)
            {
                Console.WriteLine($"Thời gian kết nối gần nhất: {status.LastConnectedTime}");
            }
            
            if (status.LastDisconnectedTime != DateTime.MinValue)
            {
                Console.WriteLine($"Thời gian ngắt kết nối gần nhất: {status.LastDisconnectedTime}");
            }
            
            Console.WriteLine($"Số lần thử kết nối lại: {status.ReconnectAttempts}");
            Console.WriteLine($"Số tin nhắn đã nhận: {status.MessagesReceived}");
            Console.WriteLine($"Số tin nhắn đã gửi: {status.MessagesSent}");
            
            if (!string.IsNullOrEmpty(status.LastErrorMessage))
            {
                Console.WriteLine();
                Console.WriteLine("Lỗi gần nhất:");
                ColoredMessage(status.LastErrorMessage, ConsoleColor.Red);
            }
            
            Console.WriteLine();
            if (status.IsConnected)
            {
                TimeSpan uptime = DateTime.Now - status.LastConnectedTime;
                Console.WriteLine($"Thời gian hoạt động: {uptime.Days} ngày, {uptime.Hours} giờ, {uptime.Minutes} phút, {uptime.Seconds} giây");
            }
            
            Console.WriteLine("\nNhấn phím bất kỳ để quay lại...");
            Console.ReadKey();
        }
    }
} 