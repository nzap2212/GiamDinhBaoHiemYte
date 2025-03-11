using System.ComponentModel;
using System.Configuration.Install;
using System.ServiceProcess;

namespace GĐBHYT_adapter
{
    [RunInstaller(true)]
    public class ProjectInstaller : Installer
    {
        private ServiceProcessInstaller processInstaller;
        private ServiceInstaller serviceInstaller;

        public ProjectInstaller()
        {
            // Cấu hình tài khoản chạy dịch vụ
            processInstaller = new ServiceProcessInstaller
            {
                Account = ServiceAccount.LocalSystem // Chạy với quyền hệ thống
            };

            // Cấu hình dịch vụ
            serviceInstaller = new ServiceInstaller
            {
                ServiceName = "GDBHYT_adapter", // Tên dịch vụ
                DisplayName = "GDBHYT Adapter Service", // Tên hiển thị trong services.msc
                StartType = ServiceStartMode.Automatic // Tự động khởi động khi bật máy
            };

            // Thêm vào danh sách cài đặt
            Installers.Add(processInstaller);
            Installers.Add(serviceInstaller);
        }
    }
}
