   M S B A M L   `   `   `  ����E  AGĐBHYT.UI, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null3clr-namespace:GĐBHYT.UI.PagesGĐBHYT.UI.Pages  5      '    !GĐBHYT.UI.Pages.TheoDoi130NoiTru   5      W SPresentationCore, Version=8.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35\ XPresentationFramework, Version=8.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35e aSystem.Windows.Controls.Ribbon, Version=8.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089R NWindowsBase, Version=8.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35F 9http://schemas.microsoft.com/winfx/2006/xaml/presentation     5      R NSystem.Xaml, Version=8.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089:x,http://schemas.microsoft.com/winfx/2006/xaml     5      Jmc;http://schemas.openxmlformats.org/markup-compatibility/2006     5      @d2http://schemas.microsoft.com/expression/blend/2008     5      0localclr-namespace:GĐBHYT.UI.Pages     5      _ [MaterialDesignThemes.Wpf, Version=5.2.1.0, Culture=neutral, PublicKeyToken=df2a72020bd7962aFmaterialDesign1http://materialdesigninxaml.net/winfx/xaml/themes  5      .��5	      �   � RowDefinitions  5
   
   �� 5      $
��Auto �6   �� 5      $
��Auto �6   �� 5      $��* �6   .+�5   
   � $��0��6   ���#0078D7 � ColumnDefinitions 5      �� 5      $��* �6#   �� 5      $
��Auto �6#   .+�5      �� $'��!Theo dõi bệnh nhân nội trú��6   $��18(�5      $
��Bold"�5      
�������$��
10,10,0,10q�5      �� 5      $��1��6    �� Orientation$ 
Horizontal=�6)   .+�5      �� $��Trang chủ��6   
�������$��Center=�5       $��0,0,5,0q�5!      �� 5"      $��>��6   
�������$��Center=�5$      $��0,0,5,0q�5%      �� 5&      $'��!Theo dõi bệnh nhân nội trú��6   
�������$��Center=�5(      $��0,0,10,0q�5)      5*      5+      � 5.   
   $��1��6   $��10q�6    5/      �� 50      $	��120 �6#   �� 51      $��* �6#   �� 52      $	��120 �6#   �� 53      $��* �6#     55      �� 56      $
��Auto �6    �� 57      $
��Auto �6    .+�5;      �� $��0��6   $��0��6%   $��
Từ ngày��5<      $��Right=�5=      $��Center=�5>      $��0,0,10,0q�5?      (  "System.Windows.Controls.DatePicker  5A      $��0��6   $��1��6&   $��0,0,10,0q�5B      �� 5D      $��0��6   $��2��6%   $
��Khoa��5E      $��Right=�5F      $��Center=�5G      $��0,0,10,0q�5H      �� 5J      $��0��6   $��3��6$   .@�5K      �� $��
Tất cả��6   �� 5L      $��Nội��6   �� 5M      $��Ngoại��6   �� 5N      $��Sản��6   �� 5O      $	��Nhi��6   �� 5P      $��Cấp cứu��6   5Q      �� 5T      $��1��6   $��0��6%   $��Đến ngày��5U      $��Right=�5V      $��Center=�5W      $��	0,10,10,0q�5X        5Z      $��1��6   $��1��6&   $��	0,10,10,0q�5[      �� 5]      $��1��6   $��2��6%   $��Tìm kiếm��5^      $��Right=�5_      $��Center=�5`      $��	0,10,10,0q�5a      � 5c      $��1��6   $��3��6    $��0,10,0,0q�60    5d      �� 5e      $��* �6'   �� 5f      $
��Auto �6'   .+�5i      �� $��0��6   )  #MaterialDesignThemes.Wpf.HintAssist   Hint$( "Nhập tên hoặc số bệnh án��5j      �� 5l      $��1��6   ���#2093d1
�������$��10,0,0,0q�5o      .��5p      �� $ 
Horizontal=�6!   .+�5q      '  !MaterialDesignThemes.Wpf.PackIcon     Kind$ Filter=�62   $��0,0,5,0q�6@   �� 5r      $��Lọc��6$   5s      5t      5u      5v      � 5y   
   $��2��6   $��
10,0,10,10q�6     5z      �� 5{      $
��Auto �6    �� 5|      $��* �6    .+�5�      � $��0��6    5�      �� 5�      $��* �6'   �� 5�      $
��Auto �6'   .+�5�      �� $��0��6   $(��"Danh sách bệnh nhân nội trú��5�      $��16(�5�      $��SemiBold"�5�      $��Center=�5�      �� 5�      $��1��6   $ 
Horizontal=�6-   .+�5�      �� ���#4CAF50
�������$��0,0,10,0q�5�       � ToolTip$ Xuất Excel��5�      .��5�      �� $ 
Horizontal=�6%   .+�5�        $ 	FileExcel=�66   $��0,0,5,0q�6G   �� 5�      $��Xuất Excel��6(   5�      5�      �� 5�      ���#FF9800
�������$ In danh sách��5�      .��5�      �� $ 
Horizontal=�6%   .+�5�        $ Printer=�66   $��0,0,5,0q�6E   �� 5�      $��In danh sách��6(   5�      5�      5�      5�      &   System.Windows.Controls.DataGrid  5�      -   5          Name$ dataGrid��5�      $��1��5�      $��0,10,0,0q�5�         AutoGenerateColumns$ False��5�         
IsReadOnly$
 True��5�      	   CanUserAddRows$	 False��5�      
   CanUserDeleteRows$
 False��5�         CanUserReorderColumns$ False��5�         CanUserResizeRows$ False��5�         CanUserSortColumns$
 True��5�         AlternatingRowBackground �#F5F5F5$��1q�5�      ���#E0E0E0   GridLinesVisibility$	 All=�5�         Columns 5�      0  *System.Windows.Controls.DataGridTextColumn  5�      ,  &System.Windows.Controls.DataGridColumn   Header$ Số bệnh án��6)      Width5  /System.Windows.Controls.DataGridLengthConverter$	 120 6Z   1  +System.Windows.Controls.DataGridBoundColumn   Binding 6=   �� *
SoBenhAn+6Z     5�      $ Tên bệnh nhân��6)   $	 200 6`    6@   �� *TenBenhNhan+6`     5�      $ Giới tính��6)   $ 80 6Y    6<   �� *
GioiTinh+6Y     5�      $ 
Ngày vào��6)   $	 120 6W    6;   �� *	NgayVao+6W     5�      $ Thời gian vào��6)   $	 120 6`    6@   �� *ThoiGianVao+6`     5�      $ Lý do vào��6)   $	 200 6X    6<   �� *	LyDoVao+6X     5�      $ 	Khoa vào��6)   $	 150 6W    6;   �� *	KhoaVao+6W     5�      $ ICD vào��6)   $	 100 6U    6:   �� *ICDVao+6U   4	  .System.Windows.Controls.DataGridTemplateColumn	  5�      $ 	Thao tác��6-   $	 120 6?    	  CellTemplate 5�      �� 5�      .R�5�   "   �� $ 
Horizontal=�6-   .+�5�   &   ��    MaterialDesignIconButton#��[  6-   $ Xem chi tiết��5�   -   $��0,0,5,0q�5�   -   .��5�   *     $	 Eye=�6B   5�   '   �� 5�   &   #��[  6-   $ Chỉnh sửa��5�   -   $��0,0,5,0q�5�   -   .��5�   *     $ Pencil=�6B   5�   '   �� 5�   &   #��[  6-   $ In bệnh án��5�   -   .��5�   *     $ Printer=�6B   5�   '   5�   #   5�      5�      5�      5�      5�      5�      