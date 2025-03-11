using GĐBHYT_adapter.Services;
using System;
using System.ServiceProcess;


namespace GĐBHYT_adapter
{
    public partial class Service1: ServiceBase
    {
        public Service1()
        {
            InitializeComponent();
        }

        protected override async void OnStart(string[] args)
        {
            Console.WriteLine("🔵 Windows Service Đang Chạy...");

            var webSocketClient = new WebSocketClient("ws://127.0.0.1:3000");
            await webSocketClient.ConnectAsync();
        }
 
        protected override void OnStop()
        {

        }
    }
}
