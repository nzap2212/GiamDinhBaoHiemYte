   M S B A M L   `   `   `  ����E  AGĐBHYT.UI, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null=#clr-namespace:GĐBHYT.UI.ComponentsGĐBHYT.UI.Components  5      $    GĐBHYT.UI.Components.SlideBar   5      W SPresentationCore, Version=8.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35\ XPresentationFramework, Version=8.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35e aSystem.Windows.Controls.Ribbon, Version=8.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089R NWindowsBase, Version=8.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35F 9http://schemas.microsoft.com/winfx/2006/xaml/presentation     5      R NSystem.Xaml, Version=8.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089:x,http://schemas.microsoft.com/winfx/2006/xaml     5      Jmc;http://schemas.openxmlformats.org/markup-compatibility/2006     5      @d2http://schemas.microsoft.com/expression/blend/2008     5      5local#clr-namespace:GĐBHYT.UI.Components     5      _ [MaterialDesignThemes.Wpf, Version=5.2.1.0, Culture=neutral, PublicKeyToken=df2a72020bd7962aFmaterialDesign1http://materialdesigninxaml.net/winfx/xaml/themes  5      .��5
      �   � RowDefinitions  5   
   �� 5      $��* �6   �� 5      $
��auto �6   .+�5   
   �� $��0��6   $
��Auto=�5      .��5      #  MaterialDesignThemes.Wpf.Card     MaterialDesignBackground#���   6"   $��0��5      .��5      �� .+�5      9� $��Stretch=�6   ���#fff��5      �� 5       �� Orientation$ 
Horizontal=�6%   .+�5      '  !MaterialDesignThemes.Wpf.PackIcon     Kind$ HospitalBuilding=�66   $��Center=�5   6   �� 5       �� Padding$ 5 0 0 0q�6(   $��16(�5   (   Giám định 1305      5      .��5       �� $ Vertical=�6!   $��50 0 0 0q�5!   !   .+�5"      �� -   5         ��Name$ btnQuanLyHoSo130��5"   %   $ 
Horizontal=�5#   %   
������ 
 � Tag$ QuanLyHoSo130��5&   %     NavItemStyle#��[ 5'   %   .+�5(        $ ArrowRightDropCircle=�66   $��Center=�5)   6   �� 5*      ���#fff$ 10q�5+   (   $��14(�5,   (   $��Quản lý hồ sơ 130��5-   (   5.      �� 5/      -   5        $ btnCapNhatHoSo130��5/   %   $ 
Horizontal=�50   %   
������ $ CapNhatHoSo130��53   %   #��[ 54   %   .+�55        $ ArrowRightDropCircle=�66   $��Center=�56   6   �� 57      ���#fff$ 10q�58   (   $��14(�59   (   $��Cập nhật hồ sơ 130��5:   (   5;      �� 5<      -   5        $ btnTheoDoi130NoiTru��5<   %   $ 
Horizontal=�5=   %   
������ $ TheoDoi130NoiTru��5@   %   #��[ 5A   %   .+�5B        $ ArrowRightDropCircle=�66   $��Center=�5C   6   �� 5D      ���#fff$ 10q�5E   (   $��14(�5F   (   $'��!Theo dõi bệnh nhân nội trú��5G   (   5H      5I      5J      9� 5L      $��Stretch=�6   ���#fff��5N      �� 5O      $ 
Horizontal=�6%   .+�5P        $ ViewList=�66   $��Center=�5Q   6   �� 5R      $ 5 0 0 0q�6(   $��16(�5S   (   
Danh mục5U      5V      .��5X      �� $ Vertical=�6!   $��50 0 0 0q�5Y   !   .+�5Z      �� $ 
Horizontal=�6%   .+�5[        $ ArrowRightDropCircle=�66   $��Center=�5\   6   �� 5]      ���#fff$ 10q�5^   (   $��14(�5_   (   $��Thuốc��5`   (   5a      �� 5b      $ 
Horizontal=�6%   .+�5c        $ ArrowRightDropCircle=�66   $��Center=�5d   6   �� 5e      ���#fff$ 10q�5f   (   $��14(�5g   (   $��Vật tư y tế��5h   (   5i      �� 5j      $ 
Horizontal=�6%   .+�5k        $ ArrowRightDropCircle=�66   $��Center=�5l   6   �� 5m      ���#fff$ 10q�5n   (   $��14(�5o   (   $��Dịch vụ��5p   (   5q      �� 5r      $ 
Horizontal=�6%   .+�5s        $ ArrowRightDropCircle=�66   $��Center=�5t   6   �� 5u      ���#fff$ 10q�5v   (   $��14(�5w   (   $��Dịch vụ thủ công��5x   (   5y      �� 5z      $ 
Horizontal=�6%   .+�5{        $ ArrowRightDropCircle=�66   $��Center=�5|   6   �� 5}      ���#fff$ 10q�5~   (   $��14(�5   (   $��Trang thiết bị��5�   (   5�      �� 5�      $ 
Horizontal=�6%   .+�5�        $ ArrowRightDropCircle=�66   $��Center=�5�   6   �� 5�      ���#fff$ 10q�5�   (   $��14(�5�   (   $��Danh mục nhân viên��5�   (   5�      �� 5�      $ 
Horizontal=�6%   .+�5�        $ ArrowRightDropCircle=�66   $��Center=�5�   6   �� 5�      ���#fff$ 10q�5�   (   $��14(�5�   (   $��Danh mục lỗi��5�   (   5�      �� 5�      $ 
Horizontal=�6%   .+�5�        $ ArrowRightDropCircle=�66   $��Center=�5�   6   �� 5�      ���#fff$ 10q�5�   (   $��14(�5�   (   $��Danh mục khoa��5�   (   5�      5�      5�      9� 5�      $��Stretch=�6   ���#fff��5�      �� 5�      $ 
Horizontal=�6%   .+�5�        $ SettingsOutline=�66   $��Center=�5�   6   �� 5�      $ 5 0 0 0q�6(   $��16(�5�   (   Quy trình kỹ thuật5�      5�      .��5�      �� $ Vertical=�6!   $��50 0 0 0q�5�   !   .+�5�      �� $ 
Horizontal=�6%   .+�5�        $ ArrowRightDropCircle=�66   $��Center=�5�   6   �� 5�      ���#fff$ 10q�5�   (   $��14(�5�   (   $(��"Hướng dẫn sử dụng thuốc��5�   (   5�      �� 5�      $ 
Horizontal=�6%   .+�5�        $ ArrowRightDropCircle=�66   $��Center=�5�   6   �� 5�      ���#fff$ 10q�5�   (   $��14(�5�   (   $,��&Hướng dẫn sử dụng dịch vụ��5�   (   5�      5�      5�      9� 5�      $��Stretch=�6   ���#fff��5�      �� 5�      $ 
Horizontal=�6%   .+�5�        $ 	UserGroup=�66   $��Center=�5�   6   �� 5�      $ 5 0 0 0q�6(   $��16(�5�   (   Quản trị hệ thống5�      5�      .��5�      �� $ Vertical=�6!   $��50 0 0 0q�5�   !   .+�5�      �� $ 
Horizontal=�6%   .+�5�        $ ArrowRightDropCircle=�66   $��Center=�5�   6   �� 5�      ���#fff$��14(�5�   (   $ 10q�5�   (   $��Quản lý người dùng��5�   (   5�      �� 5�      $ 
Horizontal=�6%   .+�5�        $ ArrowRightDropCircle=�66   $��Center=�5�   6   �� 5�      ���#fff$��14(�5�   (   $ 10q�5�   (   $��Quản lý bệnh viện��5�   (   5�      5�      5�      �� 5�        MaterialDesignFlatButton#���  6   $��50��5�      
�������$��Normal"�5�      $
��Left=�5�      $
��24,0q�5�      ��5�      �� 5�      $ 
Horizontal=�6%   .+�5�        $ 	ChartLine=�66   �� 5�      $ 5 0 0 0q�6(   $��15(�5�   (   $"Thống kê hồ sơ bệnh viện5�      5�      5�      �� 5�      #���  6   $��50��5�      
�������$��Normal"�5�      $
��Left=�5�      $
��24,0q�5�      ��5�      �� 5�      $ 
Horizontal=�6%   .+�5�        $ 	ChartLine=�66   �� 5�      $ 5 0 0 0q�6(   $��15(�5�   (   Báo cáo thông kê5�      5�      5      5     5     5     �� 5  
   $��1��6   $��Center=�5     
�������$��12(�5	     $��10,20,10,10q�5
     $,��&© 2025 ZigiSoft. All rights reserved.��5     5     5     