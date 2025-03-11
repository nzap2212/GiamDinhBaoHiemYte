USE [eHospital_ThuyDienUB]
GO
/****** Object:  StoredProcedure [dbo].[sp_XuatXML_BangKe01_130]    Script Date: 03/04/2025 3:48:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER  PROCEDURE [dbo].[sp_XuatXML_BangKe01_130]
(
	@TiepNhan_Id int = null ,
	@BenhAn_Id int = null
)
AS

BEGIN

DECLARE @Ma_Lk VARCHAR(50)
DECLARE @ChanDoan_NT NVARCHAR(1000)
SELECT @Ma_Lk = convert(varchar (50),SoTiepNhan ) FROM TiepNhan WHERE TiepNhan_Id = @TiepNhan_Id
DECLARE @ICDCapCuu VARCHAR(20)
DECLARE @ICD_NT NVARCHAR(1000)
DECLARE @ICD_NTGopBenh NVARCHAR(1000)
DECLARE @ICD_phu NVARCHAR(1000)
DECLARE @Ma_PTTT_QT varchar(250)
declare @ChanDoan_RV  NVARCHAR(1000)



SET @Ma_PTTT_QT = [dbo].[Get_PTTT_QT_ByBenhAn_Id] (NULL, @TiepNhan_Id)

if @BenhAn_Id is null 

set @BenhAn_Id  = (select BenhAn_Id from BenhAn where TiepNhan_Id = @TiepNhan_Id)

if @BenhAn_Id is not null
	begin
		SELECT	@ChanDoan_NT = isnull(ba.ChanDoanVaoKhoa, isnull(icd.TenICD, isnull( cc.ChanDoanNhapVien,icd_cc.TenICD) ) )
			, @ICDCapCuu = isnull(icd.MaICD, icd_cc.MaICD)
			, @ICD_NT = icd.MaICD
			, @ICD_NTGopBenh = [dbo].[Get_MaICDByTiepNhan_ID_gopbenhPHCN] (@Tiepnhan_id)
			, @ICD_phu = icd_k.MaICD + ';' + [dbo].[Get_MaICD_ByBenhAn_Id] (@BenhAn_Id,'M')--, @SoBenhAn = ba.SoBenhAn,
			--, @Ma_Lk =  REPLACE(ba.SoBenhAn,'/','_')
			, @ChanDoan_RV = isnull(ba.ChanDoanRaVien,icd.TenICD)+ ', ' + isnull(isnull(ba.chandoanphuravien,icd_k.tenicd),'')
		FROM	(
					SELECT	*
					FROM	dbo.BenhAn
					WHERE	BenhAn_Id = @BenhAn_Id
				) ba
		INNER JOIN TiepNhan tn  (nolock)  ON ba.TiepNhan_ID= tn.TiepNhan_ID
		LEFT JOIN DM_ICD icd  (nolock) ON icd.ICD_Id = ba.ICD_BenhChinh
		left join ThongTinCapCuu cc (nolock)  on ba.BenhAn_ID = cc.BenhAn_Id 
		left join DM_ICD icd_cc (nolock)  on isnull(cc.ICD_BenhChinh, cc.ICD_BenhPhu) = icd_cc.ICD_Id
		LEFT JOIN DM_ICD icd_k (nolock)  ON ba.ICD_BenhPhu  = icd_k.ICD_Id	

		SET @Ma_PTTT_QT = [dbo].[Get_PTTT_QT_ByBenhAn_Id] (@BenhAn_Id, NULL)
	end

DELETE FROM [XML130].[dbo].[TT_01_TONGHOP] WHERE MA_LK = @Ma_Lk
DELETE FROM [XML130].[dbo].[TT_02_THUOC] WHERE MA_LK = @Ma_Lk
DELETE FROM [XML130].[dbo].[TT_03_DVKT_VTYT] WHERE MA_LK = @Ma_Lk
DELETE FROM [XML130].[dbo].[TT_04_CLS] WHERE MA_LK = @Ma_Lk
DELETE FROM [XML130].[dbo].[TT_05_LAMSANG] WHERE MA_LK = @Ma_Lk
DELETE FROM [XML130].[dbo].[TT_06_HIV] WHERE MA_LK = @Ma_Lk
DELETE FROM [XML130].[dbo].[TT_07_GIAY_RAVIEN] WHERE MA_LK = @Ma_Lk
DELETE FROM [XML130].[dbo].[TT_08_HSBA] WHERE MA_LK = @Ma_Lk
DELETE FROM [XML130].[dbo].[TT_09_CHUNGSINH] WHERE MA_LK = @Ma_Lk
DELETE FROM [XML130].[dbo].[TT_10_DUONGTHAI] WHERE MA_LK = @Ma_Lk
DELETE FROM [XML130].[dbo].[TT_11_NGHI_BHXH] WHERE MA_LK = @Ma_Lk
--DELETE FROM [XML130].[dbo].[TT_12_GDYK] WHERE ma_lk = @Ma_Lk
DELETE FROM [XML130].[dbo].[TT_13_GIAYCHUYENTUYEN] WHERE MA_LK = @Ma_Lk
DELETE FROM [XML130].[dbo].[TT_14_GIAYHENKHAMLAI] WHERE MA_LK = @Ma_Lk
DELETE FROM [XML130].[dbo].[TT_15_DIEUTRILAO] WHERE MA_LK = @Ma_Lk







SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
BEGIN TRAN
	BEGIN TRY
	DECLARE @MaCSKCB  NVARCHAR(1000)
	
	DECLARE @ChanDoan_PK NVARCHAR(1000)
	DECLARE @ICD_PK NVARCHAR(1000)
	DECLARE @ICDKB NVARCHAR(1000)
	DECLARE @ICD_PHUPK NVARCHAR(1000)
	
	DECLARE @ICD_PNT NVARCHAR(1000)
	
	DECLARE @ICD_PKBenhChinh NVARCHAR(1000)
	DECLARE @ICD_PKGopBenh NVARCHAR(1000)
	DECLARE	@ThoiGianKham DATETIME
	
	DECLARE @ChanDoanCapCuu NVARCHAR(1000)
	
	declare @CapCuu bit
	
	DECLARE @KhamBenh_Id int
	Declare @Khoa NVARCHAR(200)
	declare @ICD_Khac NVARCHAR(1000)
	declare @SoBenhAn varchar(25)

	
	DECLARE @TT_01_TONGHOP_ID int = null
	DECLARE @NGAY_VAO DATETIME
	
	set @CapCuu = 0
	----Phòng Khám
	set @ICD_PK = [dbo].[Get_MaICDPhuByTiepNhan_ID](@TiepNhan_Id)
	set @ChanDoan_PK = [dbo].[Get_DSChanDoanKB_ByTiepNhan_ID](@TiepNhan_Id)
	set @ICD_PHUPK = [dbo].[Get_MaICD_ByTiepNhan_ID](@TiepNhan_Id)
	set @ICD_PKBenhChinh = [dbo].[Get_MaICDByTiepNhan_ID_benhchinh](@TiepNhan_Id)
	set @ICD_PKGopBenh = [dbo].[Get_MaICDByTiepNhan_ID_gopbenh](@TiepNhan_Id)
	----end Phòng Khám
	---Bệnh án Ngoại trú--
	set @ICD_PNT = [dbo].[Get_MaICD_Phu_ByBenhAn_Id] (@BenhAn_Id,'M') --- icd bệnh phụ


	select @MaCSKCB=Value 
	from Sys_AppSettings  where Code = N'MaBenhVien_BHYT'

	-- Dùng để test
	--SET @MaCSKCB = '80005'

	Declare @LuongToiThieu Decimal(18,2) = 208500.00
	SELECT @LuongToiThieu = VALUE from sys_appsettings where code = 'LuongToiThieu'

	

	--lấy chẩn đoán của bệnh án ngoại trú
	select @ChanDoanCapCuu = icd.TenICD ,@ICDCapCuu = icd.MaICD, @CapCuu = 1			
	from BenhAn ba
	left join DM_ICD icd   (Nolock)  on icd.ICD_Id = ba.ICD_BenhChinh
	where TiepNhan_Id = @TiepNhan_Id
	and ba.SoCapCuu is not null

	--lấy mã bệnh chính của phòng khám đầu tiên
	SELECT @ICDKB = icd.MaICD	
	FROM TiepNhan tn (nolock)
	join	KhamBenh kb (nolock) ON tn.TiepNhan_Id = kb.TiepNhan_Id
	and kb.ThoiGianKham IN (SELECT min(ThoiGianKham) FROM KhamBenh k1 WHERE k1.TiepNhan_Id = kb.TiepNhan_Id )
	LEFT JOIN	DM_ICD icd  (Nolock)  ON  icd.ICD_Id = kb.ChanDoanICD_Id
	where tn.tiepnhan_id = @TiepNhan_Id
	
	------------------
	
	------DungDV11
	
	
	------End
	SET @BenhAn_Id = NULL   --Tránh trường hợp bệnh án ngoại trú vẫn có benhan_id
-- DUNGDV Tinh TOng Tien Thuoc
	Declare @Tong_Tien_Thuoc Decimal(18, 2) = 0
	Declare @Tong_Chi decimal(18,2) = 0
	Declare @XacNhanChiPhi_ID int = null
	Declare @T_BHTT decimal(18,2) = 0
	Declare @T_BNCCT decimal(18,2) = 0
	Declare @T_BNTT decimal(18,2) = 0
	Declare @T_NguonKhac decimal(18,2) = 0
	Declare @Tong_Chi_BH decimal(18,2) = 0

	--SET @T_BHTT = dbo.Tong_t_bhtt_ngoaitru (@TiepNhan_Id)

	SELECT 
		@Tong_Chi = T_TongChi,
		@T_BHTT = T_BHTT,
		@T_BNCCT = T_BNCCT,
		@Tong_Tien_Thuoc = T_Tong_Tien_Thuoc,
		@T_BNTT=T_BNTT,
		@T_NguonKhac=T_NguonKhac,
		@Tong_Chi_BH = T_TONGCHI_BH
	FROM dbo.Tong_Tien_XML_BangKe01_130 (@TiepNhan_Id)



declare @SoChuyenVien nvarchar (50) = null
SELECT		
			@SoChuyenVien = left (SoPhieu,6)  
			--GIAY_CHUYEN_TUYEN = right(SoPhieu,8)--tùy chỉnh theo dự án
	FROM ( select * from  TiepNhan where TiepNhan_Id = @TiepNhan_id and XacNhanChiPhi_Id is not null ) TN
		JOIN DM_BenhNhan (nolock) ON tn.BenhNhan_Id = DM_BenhNhan.BenhNhan_Id
		left join DM_BenhVien (nolock)  td on td.benhvien_id = tn.NoiGioiThieu_Id
		join ChuyenVien cv ( nolock ) on cv.TiepNhan_Id = tn.TiepNhan_Id

if @BenhAn_Id is null 
Begin 

Select	@XacNhanChiPhi_ID = min(XacNhanChiPhi_ID) From	XacNhanChiPhi Where	TiepNhan_Id = @TiepNhan_Id And SoXacNhan IS NOT NULL

DELETE FROM [XML130].[dbo].[TT_XML130_DANHSACH] WHERE MA_LK = @Ma_Lk

--DELETE FROM [XML130].[dbo].[TT_01_TONGHOP] WHERE MA_LK = @Ma_Lk

-- ADD BẢNG 1 TT_01_TONGHOP			
INSERT INTO [XML130].[dbo].[TT_01_TONGHOP]([MA_LK],[STT],[MA_BN],[HO_TEN],[SO_CCCD],[NGAY_SINH],[GIOI_TINH],[MA_QUOCTICH],[MA_DANTOC],[MA_NGHE_NGHIEP],[DIA_CHI]
,[MATINH_CU_TRU],[MAHUYEN_CU_TRU],[MAXA_CU_TRU],[DIEN_THOAI],[MA_THE_BHYT],[MA_DKBD],[GT_THE_TU],[GT_THE_DEN],[NGAY_MIEN_CCT],[LY_DO_VV]
,[LY_DO_VNT],[MA_LY_DO_VNT],[CHAN_DOAN_VAO],[CHAN_DOAN_RV],[MA_BENH_CHINH],[MA_BENH_KT],[MA_BENH_YHCT],[MA_PTTT_QT],[MA_DOITUONG_KCB],[MA_NOI_DI]
,[MA_NOI_DEN],[MA_TAI_NAN],[NGAY_VAO],[NGAY_VAO_NOI_TRU],[NGAY_RA],[GIAY_CHUYEN_TUYEN],[SO_NGAY_DTRI],[PP_DIEU_TRI],[KET_QUA_DTRI],[MA_LOAI_RV],[GHI_CHU]
,[NGAY_TTOAN],[T_THUOC],[T_VTYT],[T_TONGCHI_BV],[T_TONGCHI_BH],[T_BNTT],[T_BNCCT],[T_BHTT],[T_NGUONKHAC],[T_BHTT_GDV]
,[NAM_QT],[THANG_QT],[MA_LOAI_KCB],[MA_KHOA],[MA_CSKCB],[MA_KHUVUC],[CAN_NANG],[CAN_NANG_CON],[NAM_NAM_LIEN_TUC],[NGAY_TAI_KHAM],[MA_HSBA],[MA_TTDV],[DU_PHONG],[NHOM_MAU] )
select	
	MA_LK = @Ma_Lk
	, STT = 1
	, Ma_Bn = bn.SoVaoVien
	, HoTen	=	bn.TenBenhNhan
	, SO_CCCD = CASE 	WHEN len(bn.CMND)<10 or bn.CMND='000000000000' THEN ''	ELSE left (bn.CMND,12)  END  
	, Ngay_Sinh = CASE	WHEN bn.NgaySinh is null THEN convert(VARCHAR, bn.NamSinh) + '01010000'	
						WHEN bn.NgaySinh is not null THEN convert(VARCHAR, bn.NgaySinh, 112) +'0000' end --convert(VARCHAR,bn.GioPhut) END	
	, gioi_tinh = CASE WHEN bn.GioiTinh = 'T' THEN 1 WHEN bn.GioiTinh = 'G' THEN 2 END
	, MA_QUOCTICH =  quoctich.Dictionary_Code
	, MA_DANTOC = dantoc.Dictionary_Code 			
	, MA_NGHE_NGHIEP = nghenghiep.Dictionary_Name_En    
	, Dia_Chi = isnull(bn.diachi, TN.noilamviec)
	, MATINH_CU_TRU = tinh.madonvi				
	, MAHUYEN_CU_TRU = huyen.madonvi			
	, MAXA_CU_TRU = xa.madonvi				
	, DIEN_THOAI = left (bn.SoDienThoai,10)
	, MA_THE_BHYT = RTRIM(LTRIM(ISNULL((SELECT SoBH 
										FROM (SELECT TOP 1 UPPER(ISNULL(SUBSTRING (RTRIM(LTRIM(Attribute1)), 0, 16), '')) + ';'				
												FROM TiepNhan_DoiTuongThayDoi
												WHERE TiepNhan_Id = tn.TiepNhan_Id And ISNULL(Attribute1,'') <> '' and IS2The=1
												ORDER BY TiepNhan_DoiTuongThayDoi_Id DESC
												FOR XML PATH('')
												) BH(SoBH)), '')
						)) + UPPER(ISNULL(SUBSTRING (RTRIM(LTRIM(TN.SoBHYT)), 0, 16), ''))
	, [MA_DKBD] = RTRIM(LTRIM(ISNULL((SELECT SoBH 
											FROM (SELECT TOP 1 UPPER(ISNULL(SUBSTRING (RTRIM(LTRIM(Attribute1)), 16, 20), '')) + ';'				
													FROM TiepNhan_DoiTuongThayDoi
													WHERE TiepNhan_Id = tn.TiepNhan_Id And ISNULL(Attribute1,'') <> '' AND IS2The=1
													ORDER BY TiepNhan_DoiTuongThayDoi_Id DESC
													FOR XML PATH('')
													) BH(SoBH)), '')
							)) + UPPER(ISNULL(SUBSTRING (RTRIM(LTRIM(TN.SoBHYT)), 16, 20), ''))
	, [GT_THE_TU] = RTRIM(LTRIM(ISNULL((SELECT TuNgay 
											FROM (SELECT TOP 1 convert(VARCHAR, Attribute5, 112) + ';'				
													FROM TiepNhan_DoiTuongThayDoi
													WHERE TiepNhan_Id = tn.TiepNhan_Id And ISNULL(Attribute5,'') <> '' AND IS2The=1
													ORDER BY TiepNhan_DoiTuongThayDoi_Id DESC
													FOR XML PATH('')
													) BH(TuNgay)), '')
							)) + convert(VARCHAR, tn.BHYTTuNgay, 112)
	, [GT_THE_DEN] = RTRIM(LTRIM(ISNULL((SELECT DenNgay 
											FROM (SELECT TOP 1 convert(VARCHAR, Attribute6, 112) + ';'				
													FROM TiepNhan_DoiTuongThayDoi
													WHERE TiepNhan_Id = tn.TiepNhan_Id And ISNULL(Attribute6,'') <> '' AND IS2The=1
													ORDER BY TiepNhan_DoiTuongThayDoi_Id DESC
													FOR XML PATH('')
													) BH(DenNgay)), '')
							)) + convert(VARCHAR, tn.BHYTDenNgay, 112)
	, [NGAY_MIEN_CCT] = CONVERT(Varchar, tn.NgayHuongMienCT, 112)
	, [LY_DO_VV] = isnull(tn.LyDoVaoVien,N'Khám chữa bệnh')
	--, [LY_DO_VV] = CASE  when tn.lydotiepnhan_id = 9113	then N'Khám Bệnh Trái tuyến'
	--															when tn.lydotiepnhan_id in(6939,6989,6990,6991,6992,7001,7002,557) then N'Bệnh Nhân Vào Cấp cứu'
	--															when tn.lydotiepnhan_id = 11242 then N'Khám Bệnh Có Giấy Hẹn'
	--															when tn.lydotiepnhan_id = 558 then N'Nhập viện'
	--										 ELSE  	N'Khám bệnh'		END   
	, LY_DO_VNT = kbvv.LyDoVaoVien    
	, MA_LY_DO_VNT = NULL
	, CHAN_DOAN_VAO = isnull(@ChanDoan_NT,@ChanDoan_PK)
	, CHAN_DOAN_RV = isnull(@ChanDoan_NT,@ChanDoan_PK)
	, MA_BENH_CHINH = isnull(@ICD_NT,@ICDKB)
	, MA_BENH_KT =  case when  @ICD_PNT='' then @ICD_PK else @ICD_PNT end
	,[MA_BENH_YHCT] = null
	,[MA_PTTT_QT] = @MA_PTTT_QT  
	,[MA_DOITUONG_KCB] =    CASE WHEN lst1.Dictionary_Code = '2' and kcbbd.TenBenhVien_En <> @MaCSKCB THEN 2 -- Cap Cuu
											   WHEN (lst1.Dictionary_Code <> '2' or kcbbd.TenBenhVien_En = @MaCSKCB) AND lst.Dictionary_Code = 'TuyenKhamChuaBenh_TrongTuyen' THEN 1 -- Dung Tuyen
											   ELSE 3 END 


	,[MA_NOI_DI] = ngt.TenBenhVien_En
	,[MA_NOI_DEN] = bvChuyenDi.TenBenhVien_En
	,[MA_TAI_NAN] = CASE  WHEN tain.nguyennhan_id ='479' THEN 1
											  WHEN tain.nguyennhan_id ='480' THEN 2
												WHEN tain.nguyennhan_id ='481' THEN 4
												WHEN tain.nguyennhan_id ='482' THEN 5
												WHEN tain.nguyennhan_id ='483' THEN 3
												WHEN tain.nguyennhan_id ='484' THEN 6
												WHEN tain.nguyennhan_id ='485' THEN 7
												WHEN tain.nguyennhan_id ='8733' THEN 8
												ELSE '' END  
	,[NGAY_VAO] = replace(convert(varchar , tn.ThoiGianTiepNhan, 112)+convert(varchar(5), tn.ThoiGianTiepNhan, 108), ':','') 
	,[NGAY_VAO_NOI_TRU] = null
	,[NGAY_RA] = CASE WHEN xn.Loai = 'NoiTru' THEN replace(convert(varchar , ba.thoigianravien, 112)+convert(varchar(5), ba.thoigianravien, 108), ':','')
						ELSE 
							replace(convert(varchar , xn.ThoiGianXacNhan, 112)+convert(varchar(5), xn.ThoiGianXacNhan, 108), ':','')								--	ngay_ra
						END

	,[GIAY_CHUYEN_TUYEN] = @SoChuyenVien--tn.sochuyenvien 
	,[SO_NGAY_DTRI] = 0
						--case when ba.BenhAn_Id is not null then DATEDIFF(day,ba.NgayVaoVien, ba.NgayRaVien) + 1 
						--	when @DtriNgoaiTru = 1 and @CoDungThuoc = 1 then @NgayDungThuoc
						--	when @DtriNgoaiTru = 1 and @CoDungThuoc_TaiPKTichNgoaiTru = 1 AND @CoDungDV = 1 then @NgayDungThuoc
						--	else  0 end
	,[PP_DIEU_TRI] = null
	,[KET_QUA_DTRI] = CASE WHEN ketquadieutri.Dictionary_Code = 'Khoi' THEN 1
							      WHEN ketquadieutri.Dictionary_Code = 'Giam' THEN 2
								  WHEN ketquadieutri.Dictionary_Code = 'KhongThayDoi' THEN 3
								  WHEN ketquadieutri.Dictionary_Code in ( 'NXV','nanghon','HHXV' ) THEN 4
								  WHEN ketquadieutri.Dictionary_Code in ( 'TuVong','TuVong24','TuVongCD','TuVongTL','TuVong7' ) THEN 5
							 ELSE 1 END
	,[MA_LOAI_RV] = case when kb.HuongGiaiQuyet_Id=458 then 2 
						when @BenhAn_Id is not null then 
							( CASE WHEN lydoxuatvien.Dictionary_Code = 'RV' THEN 1
							WHEN lydoxuatvien.Dictionary_Code = 'CV' THEN 2      
							WHEN lydoxuatvien.Dictionary_Code = 'BV' THEN 3
							WHEN lydoxuatvien.Dictionary_Code in ( 'XV','TV','TV24','CCRV','DV','N' ) THEN 4
					ELSE 1 END )
					else 1 end   
	,[GHI_CHU] = null

	,[NGAY_TTOAN] = replace(convert(varchar , xn.ThoiGianXacNhan, 112)+convert(varchar(5), xn.ThoiGianXacNhan, 108), ':','')
	--,[NGAY_TTOAN] = replace(convert(varchar , xn.ThoiGianDuyetKiemTra, 112)+convert(varchar(5), xn.ThoiGianDuyetKiemTra, 108), ':','')
	,[T_THUOC] = @Tong_Tien_Thuoc 
	,[T_VTYT] = ROUND(sum(case	when (
																(li.PhanNhom in ('DU','DI','VH','VT') and ld.LoaiVatTu_Id = 'V'
																and isnull(ld.MaLoaiDuoc,'') not in ('OXY', 'OXY1','LD0143','VTYT003') And isnull(d.BHYT,0) = 1
																)
															 Or (isnull(map.TenField, ''))  = 'VTYT')
												 then (xnct.DonGiaHoTro*xnct.SoLuong) else 0  end),0)
	,[T_TONGCHI_BV] = @Tong_Chi
	,[T_TONGCHI_BH] = @Tong_Chi_BH
	,[T_BNTT] = @T_BNTT
	,[T_BNCCT] = @T_BNCCT
	,[T_BHTT] = @T_BHTT
	,[T_NGUONKHAC] = CAST(@T_NguonKhac as decimal (18,2))
	,[T_BHTT_GDV] = 0
	,[NAM_QT] = YEAR(xn.ThoiGianDuyetKiemTra) 
	,[THANG_QT] = MONTH(xn.ThoiGianDuyetKiemTra)

	,[MA_LOAI_KCB] = case when ba.BenhAn_Id is not null then '02'  --Điều trị ngoại trú YHCT, RĂNG HÀM MẶT, PHCN NGOẠI TRÚ
							--when @DtriNgoaiTru = 1 and @CoDungThuoc = 1 then '05' --có nút tích điều trị ngoại trú màn hình kham bệnh + chỉ có kê thuốc BHYT tại cùng đợt khám 
							--when @DtriNgoaiTru = 1 and @CoDungThuoc_TaiPKTichNgoaiTru = 1 AND @CoDungDV = 1 then '08' --8: có nút tích điều trị ngoại trú màn hình khám bệnh + có kê thuốc bhyt tại phòng khám tích ngoại trú đó + có sử dụng dịch vụ kỹ thuật
			else '01' end

	,[MA_KHOA] = case when ba.BenhAn_Id is null then pbkb.MaTheoQuiDinh else kr.MaTheoQuiDinh	end
	,[MA_CSKCB] = @MaCSKCB
	,[MA_KHUVUC] = ISNULL(nss.Dictionary_Code,'')
	,[CAN_NANG] =  isnull(kb.CanNang,20) --test để null cân nặng thì lấy 20 
	,[CAN_NANG_CON] = NULL
	,[NAM_NAM_LIEN_TUC] = NULL
	,[NGAY_TAI_KHAM] = ISNULL(convert(varchar , ba.ngayhentaikham, 112),dbo.Get_SoNgayHenTaiKham_XML130(@TIEPNHAN_ID))
	,[MA_HSBA] = @Ma_Lk
	,[MA_TTDV] = '2096091139'
	,[DU_PHONG] = NULL 
	, Nhom_mau = nhommau.Dictionary_Name
	

	From	(
				Select	*
				From	XacNhanChiPhi  (nolock) 
				Where	TiepNhan_Id = @TiepNhan_Id
					And SoXacNhan IS NOT NULL
				--AND		Loai = 'NgoaiTru'
			) xn
	Join	XacNhanChiPhiChiTiet xnct On xnct.XacNhanChiPhi_Id = xn.XacNhanChiPhi_Id
				left JOIN	dbo.VienPhiNoiTru_Loai_IDRef LI ON LI.Loai_IDRef = xnct.Loai_IDRef
				LEFT JOIN	(
							SELECT	dndv.DichVu_Id, mbc.MoTa, mbc.ID,				
								CASE 
											 WHEN mbc.TenField in ('CK','CongKham','KB','TienKham') THEN '01'
											 WHEN mbc.TenField in( 'XN','XetNghiem','XNHH') THEN '03'
											 WHEN mbc.TenField in ('Thuoc','OXY') THEN '16'
											 WHEN mbc.TenField in( 'TTPT','TT','TT_PT') THEN '06'
											 WHEN mbc.TenField in('DVKT_Cao', 'KTC') THEN '07'
											 WHEN mbc.TenField = 'VC' THEN '11'
											 WHEN mbc.TenField in  ('MCPM','Mau','DT','LayMau','DTMD') THEN '08'	
											 WHEN mbc.TenField in ('CDHA','CDHA_TDCN') THEN '04'
											 WHEN mbc.TenField = 'TDCN' THEN '05'
											 WHEN mbc.TenField = 'K' THEN 'Khac'
											 WHEN mbc.TenField in  ('NGCK','Giuong','GB') THEN '12'
											 WHEN mbc.TenField = 'VTYT' THEN '10'
										ELSE mbc.TenField
								END  as TenField
								,mbc.Ma 
								FROM	dbo.DM_MauBaoCao mbc
								JOIN	dbo.DM_DinhNghiaDichVu dndv ON dndv.NhomBaoCao_Id = mbc.ID
								WHERE	MauBC = 'BCVP_097'	) map ON map.DichVu_Id = xnct.NoiDung_Id  
	LEFT JOIN	DM_Duoc d ON d.Duoc_Id = xnct.NoiDung_Id AND li.PhanNhom = 'DU' And ISNULL(D.BHYT,0) = 1
	LEFT JOIN	dbo.DM_LoaiDuoc ld ON ld.LoaiDuoc_Id = d.LoaiDuoc_Id
	

	left JOIN	dbo.TiepNhan tn (nolock)  ON tn.TiepNhan_Id = xn.TiepNhan_Id
	left join	dbo.DM_DoiTuong (nolock)  dtg on dtg.DoiTuong_Id=tn.DoiTuong_Id
	left JOIN	dbo.DM_BenhNhan (nolock)  bn ON bn.BenhNhan_Id = tn.BenhNhan_Id
	LEFT JOIN Lst_Dictionary quoctich (nolock)  ON quoctich.Dictionary_Id = bn.QuocTich_Id
	LEFT JOIN Lst_Dictionary dantoc (nolock)  ON dantoc.Dictionary_Id = bn.DanToc_Id
	LEFT JOIN DM_DonViHanhChinh tinh (nolock) ON tinh.DonViHanhChinh_Id = bn.tinhthanh_id 
	LEFT JOIN DM_DonViHanhChinh huyen (nolock) ON huyen.DonViHanhChinh_Id = bn.quanhuyen_id
	LEFT JOIN DM_DonViHanhChinh xa (nolock) ON xa.DonViHanhChinh_Id = bn.XaPhuong_Id
	LEFT JOIN Lst_Dictionary nghenghiep (nolock)  ON nghenghiep.Dictionary_Id = bn.NgheNghiep_Id
	LEFT JOIN TaiNan tain (nolock) on tain.tiepnhan_id = tn.tiepnhan_id 
	left JOIN	DM_DoiTuong dt (nolock)  on dt.DoiTuong_Id = tn.DoiTuong_Id
	left join	dbo.Lst_Dictionary ndt  (Nolock) on ndt.Dictionary_Id=dt.NhomDoiTuong_Id	--and ndt.Dictionary_Code='BHYT'
	LEFT JOIN	dbo.Lst_Dictionary (nolock)  lst ON lst.Dictionary_Id = tn.TuyenKhamBenh_Id
	LEFT JOIN	dbo.DM_BenhVien ngt (nolock)  ON ngt.BenhVien_Id = tn.NoiGioiThieu_Id
	left JOIN	KhamBenh kb (nolock) ON xn.TiepNhan_Id = kb.TiepNhan_Id
				and kb.KetThucKham IN (SELECT MAX(KetThucKham) FROM KhamBenh k1
									WHERE k1.TiepNhan_Id = kb.TiepNhan_Id )
	left join DM_ICD bc (nolock) on BC.ICD_ID=kb.ChanDoanICD_Id
	left join DM_ICD bp (nolock) on Bp.ICD_ID=kb.ChanDoanPhuICD_Id
	left join chuyenvien cv (nolock) on cv.TiepNhan_Id = xn.TiepNhan_Id 
	
	left join DM_BenhVien kcbbd (nolock)on tn.BenhVien_KCB_id = kcbbd.BenhVien_Id
	left join Lst_Dictionary LST1 (nolock) on LST1.Dictionary_Id = TN.LyDoTiepNhan_Id
	LEFT JOIN Lst_Dictionary nss (nolock) ON tn.NoiSinhSong_ID = nss.Dictionary_Id And nss.Dictionary_Type_Code = 'NoiSinhSong'
	LEFT JOIN BenhAn ba (nolock) on xn.BenhAn_Id = ba.BenhAn_Id
	left join DM_ICD icd_nt on icd_nt.ICD_Id=ba.ICD_BenhChinh
	--datpt29
	left join DM_PhongBan kr (nolock)  on kr.PhongBan_Id = ba.KhoaRa_Id
	left join DM_PhongBan pbkb (nolock)  on pbkb.PhongBan_Id = kb.PhongBan_Id
	left join dm_phongban pb1 on xn.tenphongkham=pb1.tenphongban
	left join DM_PhongBan pb on ba.KhoaRa_Id=pb.PhongBan_Id
	--end datpt29
	left join lst_dictionary lydoxuatvien on ba.lydoxuatvien_id=lydoxuatvien.dictionary_id
	left join lst_dictionary nhommau on nhommau.Dictionary_Id = bn.NhomMau_Id
	LEFT JOIN KhamBenh_VaoVien kbvv (nolock) on kbvv.tiepnhan_id  = ba.tiepnhan_id and KhamBenhVaoVien_Id = (select max(KhamBenhVaoVien_Id) from KhamBenh_VaoVien where TiepNhan_Id = @TiepNhan_Id)
	LEFT JOIN DM_BenhVien bvChuyenDi (nolock) on bvChuyenDi.BenhVien_Id = isnull(cv.BenhVien_Id,ba.ChuyenDenBenhVien_Id) and bvChuyenDi.TamNgung = 0
	--thanhnn
	LEFT JOIN Lst_Dictionary  ketquadieutri  (nolock)  ON ketquadieutri.Dictionary_Id = isnull(ba.KetQuaDieuTri_Id,kb.KetQuaKhamBenh_ID)

	WHERE	xnct.DonGiaHoTroChiTra > 0	
			SUM(xnct.DonGiaHoTrochitra * xnct.SoLuong) <> 0
				
	GROUP BY	
							tn.SoTiepNhan
							,bn.SoVaoVien, lydoxuatvien.dictionary_code
							,CASE   when tn.lydotiepnhan_id = 9113	then 3 
								when tn.lydotiepnhan_id in(6939,6989,6990,6991,6992,7001,7002,557) then 2
						ELSE 1 	END
							, bn.TenBenhNhan
							, bn.NgaySinh
							, bn.GioiTinh
							, bn.NamSinh
							, isnull(bn.diachi, TN.noilamviec)
						, bvChuyenDi.TenBenhVien_En
							, tn.SoBHYT
							, tn.BHYTTuNgay
							, tn.BHYTDenNgay,bc.TenICD
							, tn.NgayHuongMienCT
							, tn.sochuyenvien 
							, ngt.TenBenhVien_En
							, lst.Dictionary_Code
							, case when ba.BenhAn_Id is null then '1' else 2 end 
							, bn.NamSinh
							, bn.SoDienThoai
							, dt.TyLe_2
							,tn.NoiTiepNhan_Id
							, tn.TiepNhan_Id
							, ba.ngayhentaikham
							, dtg.TyLe_2
							, tn.ThoiGianTiepNhan
							, tn.LyDoVaoVien
							, CASE  WHEN tain.nguyennhan_id ='479' THEN 1
											  WHEN tain.nguyennhan_id ='480' THEN 2
												WHEN tain.nguyennhan_id ='481' THEN 4
												WHEN tain.nguyennhan_id ='482' THEN 5
												WHEN tain.nguyennhan_id ='483' THEN 3
												WHEN tain.nguyennhan_id ='484' THEN 6
												WHEN tain.nguyennhan_id ='485' THEN 7
												WHEN tain.nguyennhan_id ='8733' THEN 8
												ELSE '' END
							,bc.MaICD
							, case when ba.BenhAn_Id is null then pbkb.MaTheoQuiDinh else kr.MaTheoQuiDinh	end
							,bp.MaICD
							--, xn.BenhAn_Id
							--,bn.MaBenhVien
							,nss.Dictionary_Code
							,kb.CanNang
							--,kcbbd.MaBenhVien
							, kcbbd.TenBenhVien_En
							--,xn.XacNhanChiPhi_ID
							, lst1.Dictionary_Code
							--,LI.PhanNhom 
							--,ld.LoaiVatTu_Id
							, xn.ThoiGianXacNhan
							, kbvv.LyDoVaoVien
							, xn.ThoiGianDuyetKiemTra
							, ba.thoigianravien, bc.NgoaiDinhXuat, icd_nt.NgoaiDinhXuat
							, xn.Loai, pb.matheoquidinh
							, kb.HuongGiaiQuyet_Id
							,CASE WHEN ketquadieutri.Dictionary_Code = 'Khoi' THEN 1
							      WHEN ketquadieutri.Dictionary_Code = 'Giam' THEN 2
								  WHEN ketquadieutri.Dictionary_Code = 'KhongThayDoi' THEN 3
								  WHEN ketquadieutri.Dictionary_Code in ( 'NXV','nanghon','HHXV' ) THEN 4
								  WHEN ketquadieutri.Dictionary_Code in ( 'TuVong','TuVong24','TuVongCD','TuVongTL','TuVong7' ) THEN 5
							 ELSE 1 END
							,CASE 	WHEN len(bn.CMND)<10 or bn.CMND='000000000000' THEN ''	ELSE left (bn.CMND,12)  END 
							, case when kb.HuongGiaiQuyet_Id=458 then 2 when @BenhAn_Id is not null then ( CASE WHEN lydoxuatvien.Dictionary_Code = 'RV' THEN 1
							WHEN lydoxuatvien.Dictionary_Code = 'CV' THEN 2
							WHEN lydoxuatvien.Dictionary_Code = 'BV' THEN 3
							WHEN lydoxuatvien.Dictionary_Code in ( 'XV','TV','TV24','CCRV','DV','N' ) THEN 4
						ELSE 1 END )
						else 1 end   
						, quoctich.Dictionary_Code   
				, dantoc.Dictionary_Code 			
				,  nghenghiep.Dictionary_Name_En
				, case when tn.NoiLamViec is null or tn.NoiLamViec = '' then '' else tn.NoiLamViec + '; ' end	  + bn.diachi
				, tinh.madonvi				
				,huyen.madonvi			
				, xa.madonvi
				, nhommau.Dictionary_Name
				, case when ba.BenhAn_Id is not null then '02'  --Điều trị ngoại trú YHCT, RĂNG HÀM MẶT, PHCN NGOẠI TRÚ
							--when @DtriNgoaiTru = 1 and @CoDungThuoc = 1 then '05' --có nút tích điều trị ngoại trú màn hình kham bệnh + chỉ có kê thuốc BHYT tại cùng đợt khám 
							--when @DtriNgoaiTru = 1 and @CoDungThuoc_TaiPKTichNgoaiTru = 1 AND @CoDungDV = 1 then '08' --8: có nút tích điều trị ngoại trú màn hình khám bệnh + có kê thuốc bhyt tại phòng khám tích ngoại trú đó + có sử dụng dịch vụ kỹ thuật
						else '01' end
				, CASE when tn.lydotiepnhan_id = 558 then N'Nhập viện'
								ELSE   ''  END   
				, CASE  when tn.lydotiepnhan_id = 9113	then N'Khám Bệnh Trái tuyến'
																when tn.lydotiepnhan_id in(6939,6989,6990,6991,6992,7001,7002,557) then N'Bệnh Nhân Vào Cấp cứu'
																when tn.lydotiepnhan_id = 11242 then N'Khám Bệnh Có Giấy Hẹn'
																when tn.lydotiepnhan_id = 558 then N'Nhập viện'
											 ELSE  	N'Khám bệnh'		END   
	having SUM(xnct.DonGiaHoTrochitra * xnct.SoLuong) <> 0
			

SET @TT_01_TONGHOP_ID = @@identity
INSERT INTO [XML130].[dbo].[TT_XML130_DANHSACH] VALUES(@Ma_Lk, @TT_01_TONGHOP_ID, @NGAY_VAO, @NGAY_VAO, getdate(), 0)
-- END ADD BẢNG 1 TT_01_TONGHOP

-- BEGIN ADD BẢNG 2
--	DELETE FROM [XML130].[dbo].[TT_02_THUOC] WHERE MA_LK = @Ma_Lk
	INSERT INTO [XML130].[dbo].[TT_02_THUOC](
	[MA_LK]
      ,[STT]
      ,[MA_THUOC]
      ,[MA_PP_CHEBIEN]
      ,[MA_CSKCB_THUOC]
      ,[MA_NHOM]
      ,[TEN_THUOC]
      ,[DON_VI_TINH]
      ,[HAM_LUONG]
      ,[DUONG_DUNG]
      ,[DANG_BAO_CHE]
      ,[LIEU_DUNG]
      ,[CACH_DUNG]
      ,[SO_DANG_KY]
      ,[TT_THAU]
      ,[PHAM_VI]
      ,[TYLE_TT_BH]
      ,[SO_LUONG]
      ,[DON_GIA]
      ,[THANH_TIEN_BV]
      ,[THANH_TIEN_BH]
      ,[T_NGUONKHAC_NSNN]
      ,[T_NGUONKHAC_VTNN]
      ,[T_NGUONKHAC_VTTN]
      ,[T_NGUONKHAC_CL]
      ,[T_NGUONKHAC]
      ,[MUC_HUONG]
      ,[T_BNTT]
      ,[T_BNCCT]
      ,[T_BHTT]
      ,[MA_KHOA]
      ,[MA_BAC_SI]
      ,[MA_DICH_VU]
      ,[NGAY_YL]
      ,[MA_PTTT]
      ,[NGUON_CTRA]
      ,[VET_THUONG_TP]
      ,[DU_PHONG]
	  ,[NGAY_TH_YL]
	  )
	-- RESULT 2
	SELECT [MA_LK] = @Ma_Lk
      ,[STT] = row_number () OVER (ORDER BY (SELECT 1))
      ,[MA_THUOC] = xml2.Ma_Thuoc
      ,[MA_PP_CHEBIEN] = xml2.ma_pp_chebien
      ,[MA_CSKCB_THUOC] = null
      ,[MA_NHOM] = xml2.ma_nhom
      ,[TEN_THUOC] = xml2.Ten_Thuoc
      ,[DON_VI_TINH] = xml2.don_vi_tinh
      ,[HAM_LUONG] = xml2.ham_luong
      ,[DUONG_DUNG] = xml2.duong_dung
      ,[DANG_BAO_CHE] = XML2.Dang_BaoChe
      ,[LIEU_DUNG] = xml2.LIEU_DUNG
      ,[CACH_DUNG] = xml2.Cach_Dung
      ,[SO_DANG_KY] = xml2.so_dang_ky
      ,[TT_THAU] = xml2.TT_THAU
      ,[PHAM_VI] = xml2.PHAM_VI
      ,[TYLE_TT_BH] = xml2.TyLe_TT
      ,[SO_LUONG] = xml2.So_Luong
      ,[DON_GIA] = xml2.DON_GIA
      ,[THANH_TIEN_BV] = xml2.THANH_TIEN_BV
      ,[THANH_TIEN_BH] = xml2.Thanh_Tien
      ,[T_NGUONKHAC_NSNN] = 0
      ,[T_NGUONKHAC_VTNN] = 0
      ,[T_NGUONKHAC_VTTN] = 0
      ,[T_NGUONKHAC_CL] = 0
      ,[T_NGUONKHAC] = xml2.T_NguonKhac
      ,[MUC_HUONG] = xml2.MUC_HUONG
      ,[T_BNTT] = xml2.T_BNTT
      ,[T_BNCCT] = xml2.T_BNCCT
      ,[T_BHTT] = xml2.T_BHTT
      ,[MA_KHOA] = xml2.Ma_Khoa
      ,[MA_BAC_SI] = xml2.Ma_Bac_Si
      ,[MA_DICH_VU] = xml2.MADICHVU
      ,[NGAY_YL] = xml2.Ngay_YL
      ,[MA_PTTT] = xml2.ma_pttt
      ,[NGUON_CTRA] = XML2.NGUON_CTRA
      ,[VET_THUONG_TP] = null
      ,[DU_PHONG] = null
	 ,[NGAY_TH_YL] =  xml2.Ngay_YL
	FROM (
	SELECT *, t_bntt = CASE WHEN ThuocVG = 1  THEN CAST(0 as decimal(18,2)) ELSE THANH_TIEN_BV - (t_bhtt + t_bncct) END FROM (
			SELECT		 MA_LK = @Ma_Lk	
						, STT = row_number () over (order by (select 1))--xnct.XacNhanChiPhiChiTiet_Id
						, Ma_Thuoc = case when li.PhanNhom = 'DV' then  ISNULL(DV.MaQuiDinh, dv.InputCode)
										  when li.PhanNhom in ('DU','DI','VH','VT') AND LTRIM(RTRIM(d.MaHoatChat)) <> '' AND d.MaHoatChat IS NOT NULL 
											then ISNULL(d.MaHoatChat, d.MaDuoc)
										  WHEN li.PhanNhom IN ('DU') And ld.LoaiVatTu_Id = 'V' And ld.MaLoaiDuoc IN ('VTYT003') 
											THEN ISNULL(d.MaHoatChat, d.Attribute_2)									
										else d.MaDuoc
									end
						, Ma_Thuoc_Cs =case when li.PhanNhom = 'DV' then ISNULL(DV.MaQuiDinh, dv.InputCode)
											when li.PhanNhom in ('DU','DI','VH','VT') AND LTRIM(RTRIM(d.MaHoatChat)) <> '' AND d.MaHoatChat IS NOT NULL 
												then ISNULL(d.MaHoatChat, d.MaDuoc)
											WHEN li.PhanNhom IN ('DU') And ld.LoaiVatTu_Id = 'V' And ld.MaLoaiDuoc IN ('VTYT003') 
												THEN ISNULL(d.MaHoatChat, d.Attribute_2)
											else d.MaDuoc
										end
						, MA_NHOM = CASE -- Ma_Nhom
											--datpt29 thêm mã nhóm = 6 với thuốc tỷ lệ 16062020
										when LI.PhanNhom = 'DU' AND (d.BHYT = 1 and xbn.TyLeDieuKien is not null and xnct.DonGiaHoTroChiTra>0 ) 
															and ld.LoaiVatTu_Id <> ('V') then '4' --'6' QĐ 5937
										--end datpt29
										WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 or (xnct.DonGiaHoTroChiTra>0)) and ld.LoaiVatTu_Id <> ('V') 
													and ld.MaLoaiDuoc NOT IN ('LD0143') OR  map.TenField in ('16','Thuoc') 
													or ld.MaLoaiDuoc in ('OXY', 'OXY1') THEN '4'
										WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 or (xnct.DonGiaHoTroChiTra>0)) and ld.LoaiVatTu_Id = ('V')  
													And ld.MaLoaiDuoc <> 'VTYT003' OR  map.TenField in ('10','VTYT') 
													or ld.MaLoaiDuoc not in ('OXY', 'OXY1','LD0143','VTYT003') THEN '10' 
										WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 or (xnct.DonGiaHoTroChiTra>0)) and ld.LoaiVatTu_Id <> ('V') 
													And ld.MaLoaiDuoc in ('LD0143') THEN '7'
										WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 or (xnct.DonGiaHoTroChiTra>0)) and ld.LoaiVatTu_Id = ('V') 
													And ld.MaLoaiDuoc in ('VTYT003') THEN '7'
									ELSE
										CASE
										WHEN map.TenField = '01' THEN '13' 
										WHEN map.TenField = '02' THEN '14' 
										WHEN map.TenField = '03' THEN '1' 
										WHEN map.TenField = '04' THEN '2' 
										WHEN map.TenField = '05' THEN '3' 
										WHEN map.TenField = '06' THEN '8' 
										WHEN map.TenField = '07' THEN '10' 
										WHEN map.TenField = '08' THEN '7' 
										WHEN map.TenField = '11' THEN '12' 
										WHEN map.TenField = '12' THEN '15' 
										WHEN map.TenField = '07' THEN '9' 
										when map.TenField  = '18' then '18'
										WHEN ISNULL(map.TenField, '') = '' THEN '12'
										END
									END
						
						, Ten_Thuoc = ISNULL(ISNULL(DV.TenDichVu_En,DV.TenDichvU), ISNULL(d.Ten_VTYT_917, REPLACE(D.TenHang, CHAR(0x1F), '')))  
						, DON_VI_TINH = isnull(dvt.TenDonViTinh,N'Lần')								
						, HAM_LUONG = d.HamLuong												
						, ma_pp_chebien = '' --PPCB.Dictionary_Name_En
						, Dang_BaoChe =  '' --dangbc.Dictionary_Name_En
						, DUONG_DUNG = dd.Dictionary_Code
						, Cach_Dung = isnull(nttt.GhiChu, thuoc.GhiChu)
						, LIEU_DUNG =  isnull(dbo.Get_SoLuongThuocTrongNgay(thuoc.toathuoc_id),N'Test')
						
									--isnull(convert (nvarchar(500), CAST(SUM(xnct.SoLuong)  - isnull((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18,0)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id),0) as Decimal(18, 0))
									--	) + isnull( '/' + nttt.GhiChu,'/'+thuoc.GhiChu),convert (nvarchar(500), CAST(SUM(xnct.SoLuong)  - isnull((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18,0)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id),0) as Decimal(18, 0))
									--	))
									
						, SO_DANG_KY	=ISNULL(d.Attribute_3, '')--lo.GPDK								--	so_dang_ky
						, TT_Thau = ISNULL(isnull(d.ThongTinThau,d.MaGoiThau), '')										-- TT_Thau
						--, Pham_Vi =  case when ltt.Dictionary_Code = 'VIENGAN_B' then 2 else 1 end
						, Pham_Vi =1-- phamvi.Dictionary_Code
						, So_Luong = CAST(SUM(xnct.SoLuong)  - isnull((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id),0) as Decimal(18, 3))
				
						, DON_GIA = xnct.DonGiaDoanhThu --CASE WHEN ISNULL(tyle.TyLe,0) = 0 THEN CAST(isnull(xnct.DonGiaHoTro,0) as decimal(18,3))
										--ELSE CAST(isnull(xnct.DonGiaHoTro,0)/tyle.TyLe*100 as decimal(18,3)) END
						
						, TYLE_TT = CAST(isnull((xbn.TyLeDieuKien*100),100)  as decimal(18,0))

						, THANH_TIEN = CAST(
											CASE WHEN xbn.TyLeDieuKien is not null THEN
												CASE WHEN (xnct.DonGiaDoanhThu*xbn.TyLeDieuKien *CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaDoanhThu*xbn.TyLeDieuKien), 0)		< 0 Then 0
												ELSE (xnct.DonGiaDoanhThu*xbn.TyLeDieuKien*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaDoanhThu*xbn.TyLeDieuKien), 0) END			-- t_tongchi		
											ELSE  
												CASE WHEN (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0)		< 0 Then 0
												ELSE (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0) END			-- t_tongchi		
										
												END
										as decimal(18,2))

						, THANH_TIEN_BV = CAST( CASE WHEN (xnct.DonGiaDoanhThu*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaDoanhThu), 0)		< 0 Then 0
												ELSE (xnct.DonGiaDoanhThu*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaDoanhThu), 0) END			-- t_tongchi		
										as decimal(18,2))

						, muc_huong = xnct.muc_huong*100 --CASE WHEN ISNULL(@Tong_Chi,0) < @MaxCPKB THEN 100 ELSE dt.TyLe_2*100 END
						
						, t_bhtt =  CAST(
										CASE WHEN xbn.DuocDieuKien_Id is null THEN
												CASE WHEN (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0)		< 0 Then 0
												ELSE (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0) END			-- t_tongchi		
											ELSE 
												CASE WHEN (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0)		< 0 Then 0
												ELSE (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0) END			-- t_tongchi		
											END
										*CASE WHEN ISNULL(@Tong_Chi,0) < @LuongToiThieu THEN 100 ELSE Muc_Huong*100 END
										/100
										as decimal(18,2))
						, t_bncct = 
						--, t_bncct = 
						CAST(CASE WHEN xbn.DuocDieuKien_Id is null THEN
												CASE WHEN (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0)		< 0 Then 0
												ELSE (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0) END			-- t_tongchi		
											ELSE 
												CASE WHEN (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0)		< 0 Then 0
												ELSE (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0) END			-- t_tongchi		
											END 
										as decimal(18,2))
									-
									CAST(
										CASE WHEN xbn.DuocDieuKien_Id is null THEN
												CASE WHEN (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0)		< 0 Then 0
												ELSE (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0) END			-- t_tongchi		
											ELSE 
												CASE WHEN (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0)		< 0 Then 0
												ELSE (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0) END			-- t_tongchi		
											END
										*CASE WHEN ISNULL(@Tong_Chi,0) < @LuongToiThieu THEN 100 ELSE Muc_Huong*100 END
										/100
										as decimal(18,2))
					, t_nguonkhac = 
										case
											when (mg.LyDo_ID in (9692)) then 0  -- 0 -- t_nguonkhac --thanhnn them -- Lý do giảm là ngoại giao thì không gửi XML
											else ISNULL(xbn.GiaTriMienGiam,0)
										end
						, t_ngoaids = case when isnull(bc.ngoaidinhxuat,0)=1 or isnull(icd_nt.NgoaiDinhXuat,0)=1 then
										CAST(
										CASE WHEN xbn.DuocDieuKien_Id is null THEN
												CASE WHEN (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0)		< 0 Then 0
												ELSE (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0) END			-- t_tongchi		
											ELSE 
												CASE WHEN (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0)		< 0 Then 0
												ELSE (xnct.DonGiaHoTro*CAST(SUM(xnct.SoLuong) as Decimal(18, 3))) - ISNULL(((SELECT CAST(SUM(ISNULL(SoLuong, 0)) as Decimal(18, 3)) From NoiTru_TraThuocChiTiet where ToaThuoc_Id = nttt.toathuoc_id) * xnct.DonGiaHoTro), 0) END			-- t_tongchi		
											END
										*CASE WHEN ISNULL(@Tong_Chi,0) < @LuongToiThieu THEN 100 ELSE Muc_Huong*100 END
										/100
										as decimal(18,2))
										else 0 end	

						--,	MA_KHOA='K01' -- mặc định bằng kê 01 khoa khám bệnh là 01
						,	MA_KHOA =  COALESCE(pbkb1.MaTheoQuiDinh,pbcdinh.MaTheoQuiDinh,pbthuoc.MaTheoQuiDinh,'K01')
						,	MA_BAC_SI = COALESCE(BSHCVT.SoChungChiHanhNghe,bstt.SoChungChiHanhNghe,bspt.SoChungChiHanhNghe,bscls.SoChungChiHanhNghe,bskb.SoChungChiHanhNghe)								--	ma_bac_si
					
						, MA_BENH  =isnull(@ICD_NT,@ICD_PKGopBenh)
						, NGAY_YL = replace(convert(varchar , COALESCE(kb1.ThoiGianKham,ntkb.ThoiGianKham,bapt.ThoiGianBatDau,yc.ThoiGianYeuCau,kb.ketthucKham, ychc.thoigianyeucau), 112)+convert(varchar(5), COALESCE(kb1.ThoiGianKham,ntkb.ThoiGianKham,bapt.ThoiGianBatDau,yc.ThoiGianYeuCau,kb.KetThucKham,ychc.thoigianyeucau), 108), ':','') 
						, MA_PTTT = case when 
											 left(KB.SoBHYT,2) in ('QN','CA','CY')
											 then 2 else 1 end	
						, ThuocVG = 0 --- case when ltt.Dictionary_Code = 'VIENGAN_B' THEN 1 ELSE 0 END
						, MADICHVU = dbo.Get_Ma_DV_XML2(isnull(bapt.clsyeucau_id,YCHC.clsyeucau_id))
						, NGUON_CTRA = 1--NguonCT.Dictionary_Code
				From	(
							Select	
								xnct.XacNhanChiPhiChiTiet_Id,
								xnct.XacNhanChiPhi_Id,
								xnct.Loai_IDRef,
								xnct.IDRef,
								xnct.NoiDung_Id,
								xnct.NoiDung,
								xnct.SoLuong,
								xnct.DonGiaDoanhThu,
								DonGiaHoTro = CASE WHEN CHARINDEX( '.01', CAST(xnct.DonGiaHoTro as varchar(20))) > 0 
											THEN CAST(REPLACE(CAST(xnct.DonGiaHoTro as varchar(20)), '.01', '.00') as Decimal(18, 3))
									ELSE CAST(xnct.DonGiaHoTro as Decimal(18, 3)) END,
								xnct.DonGiaHoTroChiTra,
								xnct.DonGiaThanhToan,
								xnct.SoLuong_New,
								xnct.DonGiaHoTroChiTra_New,
								xnct.Loai,
								xnct.NgayCapNhat,
								xnct.NguoiCapNhat_Id,
								xnct.PhongBan_Id,
								xnct.NgoaiTru_ToaThuoc_ID,
								xnct.NoiTru_ToaThuoc_ID,
								xnct.TenDonViTinh,
								xnct.XN_DonGiaVon,
								xnct.XN_DonGiaMua,
								xnct.DonGiaHoTroChiTra_4210,
								xnct.Muc_Huong,
								xn.TiepNhan_Id
								, xn.BenhAn_Id
							--	xn.t_ngoaids
							From	XacNhanChiPhi xn (nolock) 
								JOIN XacNhanChiPhiChiTiet xnct (nolock)  On xnct.XacNhanChiPhi_Id = xn.XacNhanChiPhi_Id and xnct.DonGiaHoTroChiTra>0
							Where	xn.TiepNhan_Id = @TiepNhan_Id
								And xn.SoXacNhan IS NOT NULL
							--AND		Loai = 'NgoaiTru'
							--	and Ngayxacnhan is not null
						
						) xnct
					left JOIN	dbo.VienPhiNoiTru_Loai_IDRef LI ON LI.Loai_IDRef = xnct.Loai_IDRef
					LEFT JOIN	(
								SELECT	dndv.DichVu_Id, mbc.MoTa, mbc.ID,				
									CASE 
												 WHEN mbc.TenField in ('CK','CongKham','KB','TienKham') THEN '01'
												 WHEN mbc.TenField in( 'XN','XetNghiem','XNHH') THEN '03'
												 WHEN mbc.TenField in ('Thuoc','OXY') THEN '16'
												 WHEN mbc.TenField in( 'TTPT','TT','TT_PT') THEN '06'
												 WHEN mbc.TenField in( 'ThuThuat') THEN '18'
												 WHEN mbc.TenField in('DVKT_Cao', 'KTC') THEN '07'
												 WHEN mbc.TenField = 'VC' THEN '11'
												 WHEN mbc.TenField in  ('MCPM','Mau','DT','LayMau','DTMD') THEN '08'	
												 WHEN mbc.TenField in ('CDHA','CDHA_TDCN') THEN '04'
												 WHEN mbc.TenField = 'TDCN' THEN '05'
												 WHEN mbc.TenField = 'K' THEN 'Khac'
												 WHEN mbc.TenField in  ('NGCK','Giuong','GB') THEN '12'
												 WHEN mbc.TenField = 'VTYT' THEN '10'
											ELSE mbc.TenField
									END  as TenField
									,mbc.Ma 
									FROM	dbo.DM_MauBaoCao mbc
									JOIN	dbo.DM_DinhNghiaDichVu dndv ON dndv.NhomBaoCao_Id = mbc.ID
									WHERE	MauBC = 'BCVP_097'	) map ON map.DichVu_Id = xnct.NoiDung_Id  --AND li.PhanNhom = 'DU' 
					left JOIN	dbo.TiepNhan tn  (nolock) ON tn.TiepNhan_Id = xnct.TiepNhan_Id
					left join (
									select  PhongBan_Id = max(PhongBan_Id)
											, kb.TiepNhan_Id
											,kb.BacSiKham_Id
											, kb.Thoigiankham
											, kb.ChanDoanICD_Id, kb.ChanDoanPhuICD_Id
											, tn.SoBHYT
											, KetThucKham
									from KhamBenh kb (nolock) 
									left join TiepNhan tn (nolock)  on tn.TiepNhan_Id = kb.TiepNhan_Id 
									group by kb.BenhNhan_Id, kb.TiepNhan_Id, NgayKham,kb.BacSiKham_Id,  kb.Thoigiankham, kb.ChanDoanICD_Id, kb.ChanDoanPhuICD_Id, tn.SoBHYT,KetThucKham
								   ) KB on 	kb.TiepNhan_Id = xnct.TiepNhan_Id	and kb.ThoiGianKham IN (SELECT TOP 1 ThoigianKham FROM KhamBenh k1
																									WHERE k1.TiepNhan_Id = kb.TiepNhan_Id )		
					left join DM_ICD i (nolock)  on i.ICD_Id = kb.ChanDoanICD_Id
					left join DM_ICD icd (nolock)  on icd.ICD_Id = kb.ChanDoanPhuICD_Id		
					left join dm_phongban pb (nolock)  on pb.PhongBan_Id = kb.PhongBan_Id
					left JOIN	dbo.DM_BenhNhan (nolock)  bn ON bn.BenhNhan_Id = tn.BenhNhan_Id
					left JOIN	DM_DoiTuong dt (nolock)  on dt.DoiTuong_Id = tn.DoiTuong_Id
					left join dbo.Lst_Dictionary  ndt  (Nolock) on ndt.Dictionary_Id=dt.NhomDoiTuong_Id	--and ndt.Dictionary_Code='BHYT'
					--LEFT JOIN	dbo.DM_BenhVien bv ON bv.BenhVien_Id = tn.BenhVien_KCB_Id
					LEFT JOIN	dbo.Lst_Dictionary  (nolock) lst ON lst.Dictionary_Id = tn.TuyenKhamBenh_Id
					LEFT JOIN	dbo.DM_BenhVien (nolock)  ngt ON ngt.BenhVien_Id = tn.NoiGioiThieu_Id
					LEFT JOIN	DM_Duoc (nolock)  d ON d.Duoc_Id = xnct.NoiDung_Id AND li.PhanNhom = 'DU' And ISNULL(D.BHYT,0) = 1
					--left join Lst_Dictionary (nolock) PPCB ON PPCB.Dictionary_Id = d.phuongphapchebien_id
				--	left join Lst_Dictionary (nolock) dangbc ON dangbc.Dictionary_Id = d.DangBaoChe_Id
					LEFT JOIN	DM_Duoc_HoatChat hc (nolock) on hc.HoatChat_Id = d.HoatChat_Id
					LEFT JOIN	dbo.DM_LoaiDuoc (nolock)  ld ON ld.LoaiDuoc_Id = d.LoaiDuoc_Id
					LEFT JOIN	dbo.DM_DonViTinh  (nolock) dvt ON dvt.DonViTinh_Id = d.DonViTinh_Id
					left join dbo.DM_DichVu  (nolock) dv on dv.DichVu_Id = xnct.NoiDung_Id AND li.PhanNhom = 'DV'
					left join dbo.Lst_Dictionary (nolock)  dd ON dd.Dictionary_Id = d.DuongDung_Id
					left join DM_BenhVien kcbbd (nolock)on tn.BenhVien_KCB_id = kcbbd.BenhVien_Id
					left join ChungTuXuatBenhNhan  (nolock) xbn on (xnct.IDRef = xbn.ChungTuXuatBN_Id and xnct.Loai_IDRef = 'I')
					left join ChungTuSoLoNhap (nolock)  lo on xbn.SoLoNhap_Id = lo.SoLoNhap_Id
					--left join DM_Duoc  (nolock) e on (LI.PhanNhom = 'DU' And e.Duoc_Id = xnct.NoiDung_Id)
					left join DM_LoaiDuoc  (nolock) f on f.LoaiDuoc_Id = D.LoaiDuoc_Id

					--LEFT JOIN Lst_Dictionary NguonCT on Nguonct.Dictionary_Id = d.DanhMucNguon_Id
					---- Thuốc ty lệ
					--left join DM_DoiTuong_GiaDuoc_TyLe  (nolock) tyle on tyle.DoiTuong_Id = dt.DoiTuong_Id and tyle.Duoc_Id = d.Duoc_Id
					---- end
					--Lấy ra ngày y lệnh
					left join ToaThuoc thuoc (nolock) on thuoc.ToaThuoc_Id = xbn.ToaThuocNgoaiTru_id
					left join NoiTru_ToaThuoc (nolock)  nttt on xbn.ToaThuoc_Id = nttt.ToaThuoc_Id
					left join NoiTru_KhamBenh (nolock)  ntkb on nttt.khambenh_id = ntkb.khambenh_id
					left join BenhAnPhauThuat_VTYT (nolock)  PTVT on xbn.BenhAnPhauThuat_VTYT_ID = PTVT.BenhAnPhauThuat_VTYT_Id
					left join BenhAnPhauThuat BAPT (nolock)  on PTVT.BenhAnPhauThuat_Id = BAPT.BenhAnPhauThuat_Id
					left join KhamBenh_VTYT kbvt (nolock)  on xnct.IDRef = kbvt.KhamBenh_VTYT_Id and li.PhanNhom = 'DU' and kbvt.Duoc_Id = d.Duoc_Id
					left join KhamBenh kb1 (nolock)  on kbvt.KhamBenh_Id = kb1.KhamBenh_Id				
					left join  (SELECT yctt.YeuCauChiTiet_Id, yc.NoiYeuCau_Id, yc.BacSiChiDinh_Id, yc.NgayYeuCau, yc.ThoiGianYeuCau 
										FROM CLSYeuCauChiTiet yctt 
										JOIN CLSYeuCau yc on yc.CLSYeuCau_Id = yctt.CLSYeuCau_Id
										where yc.TiepNhan_Id = @TiepNhan_Id) yc on yc.YeuCauChiTiet_Id=xnct.IDRef and xnct.Loai_IDRef = 'A'
					---datpt29 lấy ra mã khoa chỉ định thuốc
					left join NoiTru_LuuTru ltru (nolock)  on ltru.LuuTru_Id = ntkb.LuuTru_Id
					left join DM_PhongBan pbthuoc (nolock)  on pbthuoc.PhongBan_Id = ltru.PhongBan_Id
					left join DM_PhongBan pbcdinh (nolock)  on pbcdinh.PhongBan_Id = yc.NoiYeuCau_Id
					left join DM_PhongBan pbkb1  (nolock) on pbkb1.PhongBan_Id = kb1.PhongBan_Id
					--end datpt29

					--Lấy ra Ma_Bac_Si
					--left join vw_NhanVien bspt (nolock) on bspt.NhanVien_Id = bapt.
					left join vw_NhanVien bstt (nolock) on bstt.NhanVien_Id=ntkb.BasSiKham_Id
					LEFT JOIN vw_NhanVien bskb (nolock)  on bskb.NhanVien_Id=kb.BacSiKham_Id
					left join vw_NhanVien   bscls (nolock) on bscls.NhanVien_Id=yc.BacSiChiDinh_Id
					left join Sys_Users  (nolock) us on BAPT.NguoiTao_Id = us.User_Id
					left join NhanVien_User_Mapping (nolock)  usmap on us.User_Id = usmap.User_Id
					left join vw_NhanVien bspt (nolock)  on usmap.NhanVien_Id = bspt.NhanVien_Id
					left join CLSGhiNhanHoaChat_VTYT HCVT (nolock) on xbn.CLSHoaChat_VTYT_Id = HCVT.Id
					
					left join CLSYeuCau YCHC (nolock) on HCVT.CLSYeuCau_Id = YCHC.CLSYeuCau_Id 
					
					left join vw_NhanVien BSHCVT (nolock) on YCHC.BacSiChiDinh_Id = BSHCVT.NhanVien_Id
					--left join Lst_Dictionary ltt (nolock)  on ltt.Dictionary_Id = d.NhomThuocViemGan and ltt.Dictionary_Type_Code = 'NhomThuocViemGan'
					--left join Lst_Dictionary (nolock) phamvi on phamvi.Dictionary_Id = d.PhamVi_Id
					left join MienGiam mg on mg.TiepNhan_Id = tn.TiepNhan_Id
					left join DM_ICD bc on BC.ICD_ID=kb.ChanDoanICD_Id
				LEFT JOIN BenhAn ba (nolock) on xnct.BenhAn_Id = ba.BenhAn_Id
				left join DM_ICD icd_nt on icd_nt.ICD_Id=ba.ICD_BenhChinh
				WHERE	xnct.DonGiaHoTroChiTra > 0
					AND (xnct.DonGiaHoTro * xnct.SoLuong) <> 0
					AND ((LI.PhanNhom = 'DU' AND  ld.LoaiVatTu_Id IN ('T', 'H')) OR  map.TenField = '08' OR  map.TenField = '16' or map.TenField = 'OXY'
						or ld.MaLoaiDuoc in ('OXY', 'OXY1','LD0143','VTYT003')
					)
	
					AND ISNULL(xbn.toathanhpho, 0) = 0
			
			GROUP BY nttt.ToaThuoc_Id, li.PhanNhom, dv.MaQuiDinh, dv.InputCode, d.MaHoatChat, d.MaDuoc, d.BHYT
				, xnct.DonGiaHoTroChiTra, ld.LoaiVatTu_Id, map.TenField, ISNULL(DV.TenDichVu_En,DV.TenDichvU), d.Ten_VTYT_917, d.TenDuocDayDu
				, isnull(dvt.TenDonViTinh,N'Lần'), d.HamLuong, d.MaDuongDung, d.Attribute_3, d.Attribute_2, xnct.DonGiaHoTro, pb.MaTheoQuiDinh
				, ntkb.NgayKham, yc.ngayyeucau, ld.MaLoaiDuoc
				, D.TenHang, D.ThoiGianHopDong,dt.TyLe_2,d.ThongTinThau,d.MaGoiThau, pbcdinh.MaTheoQuiDinh, pbthuoc.MaTheoQuiDinh, pbkb1.MaTheoQuiDinh
				, dd.Dictionary_Code,
				replace(convert(varchar , COALESCE(kb1.ThoiGianKham,ntkb.ThoiGianKham,bapt.ThoiGianBatDau,yc.ThoiGianYeuCau,kb.ketthucKham, ychc.thoigianyeucau), 112)+convert(varchar(5), COALESCE(kb1.ThoiGianKham,ntkb.ThoiGianKham,bapt.ThoiGianBatDau,yc.ThoiGianYeuCau,kb.KetThucKham,ychc.thoigianyeucau), 108), ':','') 
				, tn.TuyenKhamBenh_Id,COALESCE(BSHCVT.SoChungChiHanhNghe,bstt.SoChungChiHanhNghe,bspt.SoChungChiHanhNghe,bscls.SoChungChiHanhNghe,bskb.SoChungChiHanhNghe)
					, I.ngoaidinhxuat,icd.ngoaidinhxuat	, kb.SoBHYT
				--,ltt.Dictionary_Code
			, xnct.muc_huong,isnull( '/' + nttt.GhiChu,'/'+thuoc.GhiChu)
				--, PPCB.Dictionary_Name_En, dangbc.Dictionary_Name_En
				--, phamvi.Dictionary_Code
				, bapt.CLSYeuCau_Id, YCHC.CLSYeuCau_Id
				--,NguonCT.Dictionary_Code
				,isnull(nttt.GhiChu, thuoc.GhiChu)
				, thuoc.toathuoc_id
				, xbn.DuocDieuKien_Id
				, xbn.GiaTriMienGiam, mg.LyDo_ID
				, bc.NgoaiDinhXuat, icd_nt.NgoaiDinhXuat
				, xnct.DonGiaDoanhThu
				, xbn.TyLeDieuKien
				) xml2 WHERE SO_LUONG > 0
		) xml2
-- END ADD BẢNG 2

---- BEGIN ADD BẢNG 3
	--DELETE FROM [XML130].[dbo].[TT_03_DVKT_VTYT] WHERE MA_LK = @Ma_Lk
	INSERT INTO [XML130].[dbo].[TT_03_DVKT_VTYT](	
	[MA_LK]
      ,[STT]
      ,[MA_DICH_VU]
      ,[MA_PTTT_QT]
      ,[MA_VAT_TU]
      ,[MA_NHOM]
      ,[GOI_VTYT]
      ,[TEN_VAT_TU]
      ,[TEN_DICH_VU]
      ,[MA_XANG_DAU]
      ,[DON_VI_TINH]
      ,[PHAM_VI]
      ,[SO_LUONG]
      ,[DON_GIA_BV]
      ,[DON_GIA_BH]
      ,[TT_THAU]
      ,[TYLE_TT_DV]
      ,[TYLE_TT_BH]
      ,[THANH_TIEN_BV]
      ,[THANH_TIEN_BH]
      ,[T_TRANTT]
      ,[MUC_HUONG]
      ,[T_NGUONKHAC_NSNN]
      ,[T_NGUONKHAC_VTNN]
      ,[T_NGUONKHAC_VTTN]
      ,[T_NGUONKHAC_CL]
      ,[T_NGUONKHAC]
      ,[T_BNTT]
      ,[T_BNCCT]
      ,[T_BHTT]
      ,[MA_KHOA]
      ,[MA_GIUONG]
      ,[MA_BAC_SI]
      ,[NGUOI_THUC_HIEN]
      ,[MA_BENH]
      ,[MA_BENH_YHCT]
      ,[NGAY_YL]
      ,[NGAY_TH_YL]
      ,[NGAY_KQ]
      ,[MA_PTTT]
      ,[VET_THUONG_TP]
      ,[PP_VO_CAM]
      ,[VI_TRI_TH_DVKT]
      ,[MA_MAY]
      ,[MA_HIEU_SP]
      ,[TAI_SU_DUNG]
      ,[DU_PHONG])
	-- RESULT 3
	SELECT 
	[MA_LK] = @Ma_Lk
      ,[STT] = row_number () OVER (ORDER BY (SELECT 1))
      ,[MA_DICH_VU] = XML3.ma_dich_vu
      ,[MA_PTTT_QT] = XML3.MA_PTTT_QT
      ,[MA_VAT_TU] = XML3.ma_vat_tu
      ,[MA_NHOM] = XML3.MA_NHOM
      ,[GOI_VTYT] = XML3.GOI_VTYT
      ,[TEN_VAT_TU] = XML3.TEN_VAT_TU
      ,[TEN_DICH_VU] = XML3.ten_dich_vu
      ,[MA_XANG_DAU] = NULL
      ,[DON_VI_TINH] = XML3.don_vi_tinh
      ,[PHAM_VI] = XML3.PHAM_VI
      ,[SO_LUONG] = XML3.SO_LUONG
      ,[DON_GIA_BV] = XML3.DON_GIA
      ,[DON_GIA_BH] = XML3.DON_GIA
      ,[TT_THAU] = XML3.TT_THAU
      ,[TYLE_TT_DV] = XML3.tyle_tt
      ,[TYLE_TT_BH] = 100  
      ,[THANH_TIEN_BV] = XML3.Thanh_Tien
      ,[THANH_TIEN_BH] = XML3.Thanh_Tien
      ,[T_TRANTT] = XML3.T_TRANTT
      ,[MUC_HUONG] = XML3.MUC_HUONG
      ,[T_NGUONKHAC_NSNN] = 0
      ,[T_NGUONKHAC_VTNN] = 0
      ,[T_NGUONKHAC_VTTN] = 0
      ,[T_NGUONKHAC_CL] = 0
      ,[T_NGUONKHAC] = 0
      ,[T_BNTT] = XML3.t_bntt
      ,[T_BNCCT] = XML3.[T_BNCCT]
      ,[T_BHTT] = XML3.[T_BHTT]
      ,[MA_KHOA] = XML3.[MA_KHOA]
      ,[MA_GIUONG] = XML3.[MA_GIUONG]
      ,[MA_BAC_SI] = XML3.[MA_BAC_SI]
      ,[NGUOI_THUC_HIEN] = Nguoi_TH
      ,[MA_BENH] = XML3.[MA_BENH]
      ,[MA_BENH_YHCT] = NULL
      ,[NGAY_YL] = XML3.[NGAY_YL]
      ,[NGAY_TH_YL] = XML3.[NGAY_THUCHIEN_YL]
      ,[NGAY_KQ] = XML3.[NGAY_KQ]
      ,[MA_PTTT] = XML3.[MA_PTTT]
      ,[VET_THUONG_TP] = NULL
      ,[PP_VO_CAM] = PPVC
      ,[VI_TRI_TH_DVKT] = VITRI
      ,[MA_MAY] = ma_may
      ,[MA_HIEU_SP] = XML3.MAHIEU
      ,[TAI_SU_DUNG] = XML3.TSD
      ,[DU_PHONG] = NULL
	   FROM (
			SELECT		 MA_LK = @Ma_Lk	
						, STT = row_number () over (order by (select 1))--xnct.XacNhanChiPhiChiTiet_Id
						,ma_dich_vu = case when li.PhanNhom = 'DV' and map.TenField != '10' And map.TenField != '11' then dv.MaQuiDinh --+ CASE WHEN ISNULL(clsyc.ViTri, '') <> '' THEN '.' + ISNULL(clsyc.ViTri, '') ELSE '' END
										   when LI.PhanNhom = 'DV' and map.TenField = '11' then 'VC.' + bvct.MaBenhVien
										   else null end
						,ma_dich_vu_cs = case when li.PhanNhom = 'DV' and map.TenField != '10' And map.TenField != '11' then dv.maquidinh-- + CASE WHEN ISNULL(clsyc.ViTri, '') <> '' THEN '.' + ISNULL(clsyc.ViTri, '') ELSE '' END
											  when li.PhanNhom = 'DV' And map.TenField = '11' then 'VC.' + bvct.MaBenhVien
											  else null 
										 end
						,ma_vat_tu =case when li.PhanNhom in ('DU','DI','VH','VT') or map.TenField = '10' then isnull(ISNULL(LTRIM(RTRIM(d.MaHoatChat)),ISNULL(d.Attribute_2, d.Attribute_3)), ISNULL(dv.maquidinh, dv.madichvu))  else null end
						,ma_vat_tu_cs  =case when li.PhanNhom in ('DU','DI','VH','VT') or map.TenField = '10' then	isnull(ISNULL(LTRIM(RTRIM(d.MaHoatChat)),ISNULL(d.Attribute_2, d.Attribute_3)), ISNULL(dv.maquidinh, dv.madichvu))  else null end
						, MA_NHOM = CASE -- Ma_Nhom
										WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 or (xnct.DonGiaHoTroChiTra>0)) and ld.LoaiVatTu_Id <> ('V') OR  map.TenField in ('16','Thuoc') THEN '4'
										WHEN LI.PhanNhom = 'DU' AND (d.BHYT = 1 or (xnct.DonGiaHoTroChiTra>0)) and ld.LoaiVatTu_Id = ('V')	 OR  map.TenField in ('10','VTYT')  THEN '10' 
									ELSE
										CASE
										WHEN map.TenField = '01' THEN '13' 
										WHEN map.TenField = '02' THEN '14' 
										WHEN map.TenField = '03' THEN '1' 
										WHEN map.TenField = '04' THEN '2' 
										WHEN map.TenField = '05' THEN '3' 
										WHEN map.TenField = '06' THEN '8' 
										WHEN map.TenField = '07' THEN '10' 
										WHEN map.TenField = '08' THEN '7' 
										WHEN map.TenField = '11' THEN '12' 
										WHEN map.TenField = '12' THEN '15' 
										when MAP.TenField = '18' then 18
										WHEN ISNULL(map.TenField, '') = '' THEN '12'
										END
									END
						, GOI_VTYT = ''
						, TEN_VAT_TU = CASE WHEN xnct.Loai_IDRef <> 'A' THEN  ISNULL(D.Ten_VTYT_917, d.TenHang)
											ELSE ''
									   END
						-- TrucTC	phân nhóm để tách thẻ thuốc & vật tư y tế
							--  map.TenField = '08' nếu map máu trong DM dịch vụ
						--, Phan_loai= CASE	WHEN (LI.PhanNhom = 'DU' AND  ld.LoaiVatTu_Id IN ('T', 'H')) OR  map.TenField = '08' OR  map.TenField = '16' THEN 'T' ELSE 'D' END
						--, TEN_DICH_VU = REPLACE(isnull(ISNULL(dv.TenDichVu_En, dv.TenDichVu),''), CHAR(0x1F), '') 
						, TEN_DICH_VU = case when tn.NgayTiepNhan <= '20241215' then REPLACE(isnull(ISNULL(isnull(dv.Attribute3,dv.TenDichVu_En), dv.TenDichVu),''), CHAR(0x1F), '')
						else REPLACE(isnull(ISNULL(dv.TenDichVu_En, dv.TenDichVu),''), CHAR(0x1F), '') 	
						end
						-- ten_thuoc
						, DON_VI_TINH = isnull(dvt.TenDonViTinh,N'Lần')								 --	Don_Vi_Tinh
						, PHAM_VI = 1 --isnull(phamvi.Dictionary_Code,1) --fix tạm test với dv vì dv chưa map
						--, SO_LUONG  = CAST((xnct.SoLuong) as decimal(18, 2))												--	so_luong
						, SO_LUONG = CAST(CASE WHEN map.TenField = '12' And clsyc.PT50 = 1 THEN 0.5		--Nếu dịch vụ thuộc nhóm ngày giường và được tích PT50, SO_LUONG = 0.5
										ELSE CAST((xnct.SoLuong) as decimal(18, 2))
									 END
									 - 
									 ISNULL((SELECT SUM(SOLUONG) FROM NoiTru_TraThuocChiTiet where ToaThuoc_Id = xnct.NoiTru_ToaThuoc_Id), 0)
									 as decimal(18,2))
						--, DON_GIA = CAST(isnull(xnct.DonGiaHoTro,0) as decimal(18,3))					--don_gia
						, DON_GIA = case when clsyc.TyLeThanhToan is not null							--don_gia
											then CAST((isnull(xnct.DonGiaHoTro,0)/clsyc.TyLeThanhToan)* CASE WHEN (clsyc.PT80 = 1 or clsyc.PT50 = 1) THEN isnull(clsyc.TyleThanhToan,1) ELSE 1 END as decimal(18,2)) 
										else CAST(isnull(xnct.DonGiaHoTro,0) as decimal(18,2)) 
									end	
						--, DON_GIA = case when clsyc.TyLeThanhToan is not null then CAST(isnull(xnct.DonGiaHoTro,0)/clsyc.TyLeThanhToan as decimal(18,3)) else CAST(isnull(xnct.DonGiaHoTro,0) as decimal(18,3)) end					--don_gia
						, TT_Thau = case when d.Duoc_Id is not null  then isnull(d.ThongTinThau,d.MaGoiThau)	 else   ISNULL(dv.ReportCode,'') end
						--, TYLE_TT = case when clsyc.TyLeThanhToan is not null then clsyc.TyLeThanhToan*100 else 100 end --case when dt.TyLe_2 is null then 0 else dt.TyLe_2 * 100 end										--	muc_huong
						, TYLE_TT = CASE WHEN clsyc.TyLeThanhToan IS NOT NULL										--Trường hợp có tỷ lệ thanh toán trong clsyeucauchitiet
												THEN CASE WHEN map.TenField = '01' THEN clsyc.TyLeThanhToan*100         --Nếu dịch vụ là công khám
														  WHEN map.TenField IN ('06', '18') And clsyc.PT80 = 1 THEN 80			--Nếu dịch vụ thuộc nhóm PTTT và được tích PT80
														  WHEN map.TenField IN ('06', '18') And clsyc.PT50 = 1 THEN 50			--Nếu dịch vụ thuộc nhóm PTTT và được tích PT50
														  WHEN map.TenField = '12' And clsyc.PT50 = 1 THEN 100			--Nếu dịch vụ thuộc nhóm ngày giường và được tích PT50, SO_LUONG = 0.5
														  WHEN map.TenField = '12' And clsyc.Ghep2 = 1 THEN 50			--Nếu dịch vụ thuộc nhóm ngày giường và được tích nằm ghép 2
														  WHEN map.TenField = '12' And clsyc.Ghep3 = 1 THEN 30			--Nếu dịch vụ thuộc nhóm ngày giường và được tích nằm ghép 3
														  ELSE clsyc.TyLeThanhToan*100									--Ngoài các trường hợp trên
													 END
										 ELSE 100																	--Không có tỷ lệnh thanh toán trong clsyeucauchitiet
									END
						
						----, THANH_TIEN = CAST((xnct.DonGiaHoTro*xnct.SoLuong) as decimal(18,2))-- t_TongChi	
						, THANH_TIEN = CAST(
										CAST((CASE WHEN ISNULL(tyle.TyLe,0) = 0 THEN CAST(isnull(xnct.DonGiaHoTro,0) as decimal(18,3))
										ELSE CAST(isnull(xnct.DonGiaHoTro,0)/tyle.TyLe*100 as decimal(18,3)) END)
										*CAST(xnct.SoLuong as decimal(18,2)) as decimal(18,2))	
										-
										CAST((xnct.DonGiaHoTro
											  *
											  ISNULL((SELECT SUM(SOLUONG) 
													  FROM NoiTru_TraThuocChiTiet 
													  where ToaThuoc_Id = xnct.NoiTru_ToaThuoc_Id
													 ), 0)
											 ) as Decimal(18, 2))
										as decimal(18,2))		
										
																													
						, T_TRANTT = NULL
						, muc_huong = CASE WHEN ISNULL(@Tong_Chi,0) < @LuongToiThieu THEN 100 ELSE Muc_Huong*100 END
						, t_bhtt = CAST(
										(CAST((CASE WHEN ISNULL(tyle.TyLe,0) = 0 THEN CAST(isnull(xnct.DonGiaHoTro,0) as decimal(18,3))
										ELSE CAST(isnull(xnct.DonGiaHoTro,0)/tyle.TyLe*100 as decimal(18,3)) END)
										*CAST(xnct.SoLuong as decimal(18,2)) as decimal(18,2))	
										-
										CAST((xnct.DonGiaHoTro
											  *
											  ISNULL((SELECT SUM(SOLUONG) 
													  FROM NoiTru_TraThuocChiTiet 
													  where ToaThuoc_Id = xnct.NoiTru_ToaThuoc_Id
													 ), 0)
											 ) as Decimal(18, 2)))
										 *
										 CASE WHEN ISNULL(@Tong_Chi,0) < @LuongToiThieu THEN 100 ELSE Muc_Huong*100 END
										 /
										 100
										as decimal(18,2))
						, t_bntt= 0 
						, t_bncct = CAST(CAST((CASE WHEN ISNULL(tyle.TyLe,0) = 0 THEN CAST(isnull(xnct.DonGiaHoTro,0) as decimal(18,3))
										ELSE CAST(isnull(xnct.DonGiaHoTro,0)/tyle.TyLe*100 as decimal(18,3)) END)
										*CAST(xnct.SoLuong as decimal(18,2)) as decimal(18,2))	
										-
										CAST((xnct.DonGiaHoTro
											  *
											  ISNULL((SELECT SUM(SOLUONG) 
													  FROM NoiTru_TraThuocChiTiet 
													  where ToaThuoc_Id = xnct.NoiTru_ToaThuoc_Id
													 ), 0)
											 ) as Decimal(18, 2)) as decimal(18,2))
									-
									CAST(
										(CAST((CASE WHEN ISNULL(tyle.TyLe,0) = 0 THEN CAST(isnull(xnct.DonGiaHoTro,0) as decimal(18,3))
										ELSE CAST(isnull(xnct.DonGiaHoTro,0)/tyle.TyLe*100 as decimal(18,3)) END)
										*CAST(xnct.SoLuong as decimal(18,2)) as decimal(18,2))	
										-
										CAST((xnct.DonGiaHoTro
											  *
											  ISNULL((SELECT SUM(SOLUONG) 
													  FROM NoiTru_TraThuocChiTiet 
													  where ToaThuoc_Id = xnct.NoiTru_ToaThuoc_Id
													 ), 0)
											 ) as Decimal(18, 2)))
										 *
										 CASE WHEN ISNULL(@Tong_Chi,0) < @LuongToiThieu THEN 100 ELSE Muc_Huong*100 END
										 /
										 100
										as decimal(18,2))
						, t_nguonkhac = 0 

						, t_ngoaids = case when isnull(bc.ngoaidinhxuat,0)=1 or isnull(icd_nt.NgoaiDinhXuat,0)=1 then
												CAST(
										(CAST((CASE WHEN ISNULL(tyle.TyLe,0) = 0 THEN CAST(isnull(xnct.DonGiaHoTro,0) as decimal(18,3))
										ELSE CAST(isnull(xnct.DonGiaHoTro,0)/tyle.TyLe*100 as decimal(18,3)) END)
										*CAST(xnct.SoLuong as decimal(18,2)) as decimal(18,2))	
										-
										CAST((xnct.DonGiaHoTro
											  *
											  ISNULL((SELECT SUM(SOLUONG) 
													  FROM NoiTru_TraThuocChiTiet 
													  where ToaThuoc_Id = xnct.NoiTru_ToaThuoc_Id
													 ), 0)
											 ) as Decimal(18, 2)))
										 *
										 CASE WHEN ISNULL(@Tong_Chi,0) < @LuongToiThieu THEN 100 ELSE Muc_Huong*100 END
										 /
										 100
										as decimal(18,2))
										else 0 end	
						, MA_KHOA = CASE WHEN ba.BenhAn_Id IS NULL THEN 'K01' --'K01' -- mặc định bằng kê 01 khoa khám bệnh là 01
									ELSE ISNULL(pbsd.MaTheoQuiDinh, pbRa.MaTheoQuiDinh) END
						, MA_GIUONG =''
	

						--, Ma_Bac_Si = case when li.PhanNhom = 'DV' and map.TenField = '01'  then bskb.SoChungChiHanhNghe
						--		when li.PhanNhom = 'DV' and map.TenField <> '01' and ptyc.BenhAnPhauThuat_YeuCau_Id is null then  bscls.SoChungChiHanhNghe + isnull(';' + bskq.SoChungChiHanhNghe,'')
						--		when li.PhanNhom = 'DV' and ptyc.BenhAnPhauThuat_YeuCau_Id is not null then  bscls.SoChungChiHanhNghe + (dbo.Get_MaBacSi_XML3_By_BenhAnPhauThuat_Id(ptyc.BenhAnPhauThuat_YeuCau_Id))
						--		else COALESCE(bstt.SoChungChiHanhNghe,bspt.SoChungChiHanhNghe,bskb.SoChungChiHanhNghe)  end
						
						, Ma_Bac_Si = case when li.PhanNhom = 'DV' and clsyc.YeuCauChiTiet_Id is not null and map.TenField <> '01' then bscls.SoChungChiHanhNghe
											when li.PhanNhom = 'DV' and clsyc.YeuCauChiTiet_Id is not null  and map.TenField = '01' then isnull(bskb.SoChungChiHanhNghe,bscls.SoChungChiHanhNghe)
											when li.PhanNhom <> 'DV' and ntkb.KhamBenh_Id is not null then bstt.SoChungChiHanhNghe
											when li.PhanNhom <> 'DV' and kbvt.KhamBenh_Id is not null then bskb_vt.SoChungChiHanhNghe
											when li.PhanNhom <> 'DV' and PTVT.BenhAnPhauThuat_VTYT_Id is not null then bspt_vt.SoChungChiHanhNghe
										else null end
								
						, MA_BENH  = isnull(@ICD_NTGopBenh,@ICD_PKGopBenh)
					    , NGAY_YL =  case when xnct.Loai_IDRef = 'A' then format( yc.ThoiGianYeuCau,'yyyyMMddHHmm')
										when xnct.Loai_IDRef <> 'A' and  xbn.ToaThuoc_Id is not null then format( ntkb.ThoiGianKham,'yyyyMMddHHmm')
										when xnct.Loai_IDRef <> 'A' and  xbn.BenhAnPhauThuat_VTYT_ID is not null then  format( ptvt.NgayTao,'yyyyMMddHHmm')
										when xnct.Loai_IDRef <> 'A' and kbvt.KhamBenh_VTYT_Id is not null then format( kbvt.NgayTao,'yyyyMMddHHmm')
									else NULL
									end
						, NGAY_THUCHIEN_YL = CASE WHEN ndv.MaNhomDichVu = '04' THEN REPLACE(CONVERT(varchar, COALESCE(kb.ThoiGianKham, yc.ThoiGianYeuCau), 112) + CONVERT(varchar(5), COALESCE(kb.ThoiGianKham, yc.ThoiGianYeuCau), 108), ':','')
										WHEN ndv.MaNhomDichVu IN ('0101', '0102', '0103', '0105', '0110', '0104', '0121', '0120') --Xét nghiệm
											THEN REPLACE(CONVERT(varchar, COALESCE(lab.SIDIssueDateTime,kq.NgayKhoaDuLieu, case when kq.NgayTao>kq.ThoiGianThucHien then kq.NgayTao else  kq.ThoiGianThucHien end, yc.ThoiGianYeuCau), 112) + CONVERT(varchar(5), COALESCE(lab.SIDIssueDateTime,kq.NgayKhoaDuLieu, case when kq.NgayTao>kq.ThoiGianThucHien then kq.NgayTao else  kq.ThoiGianThucHien end, yc.ThoiGianYeuCau), 108), ':','')
										WHEN ndv.MaNhomDichVu IN ('0201','0204','0203','0206','0209','0302','0303','0107','0307') --CĐHA
											THEN REPLACE(CONVERT(varchar, COALESCE(kq.ThoiGianBatDauThucHien,kq.NgayKhoaDuLieu, case when kq.NgayTao>kq.ThoiGianThucHien then kq.NgayTao else  kq.ThoiGianThucHien end, yc.ThoiGianYeuCau), 112) + CONVERT(varchar(5), COALESCE(kq.ThoiGianBatDauThucHien,kq.NgayKhoaDuLieu, case when kq.NgayTao>kq.ThoiGianThucHien then kq.NgayTao else  kq.ThoiGianThucHien end, yc.ThoiGianYeuCau), 108), ':','')
									ELSE
										replace(convert(varchar , COALESCE(kb1.ThoiGianKham,ntkb.ThoiGianKham,bapt.ThoiGianBatDau,yc.ThoiGianYeuCau,kb.ThoiGianKham), 112)+convert(varchar(5), COALESCE(kb1.ThoiGianKham,ntkb.ThoiGianKham,bapt.ThoiGianBatDau,yc.ThoiGianYeuCau,kb.ThoiGianKham), 108), ':','')  				-- ngay_yl	
									END
							-- datpt29
						--, NGAY_THUCHIEN_YL = case when  xnct.Loai_IDRef = 'A' and kq.CLSKetQua_Id is not null then format( kq.ThoiGianBatDauThucHien,'yyyyMMddHHmm')
						--						when xnct.Loai_IDRef <> 'A' and  xbn.ToaThuoc_Id is not null then format( ntkb.ThoiGianKham,'yyyyMMddHHmm')
						--						when xnct.Loai_IDRef <> 'A' and  xbn.BenhAnPhauThuat_VTYT_ID is not null then format( PTVT.NgayTao,'yyyyMMddHHmm')
						--						when xnct.Loai_IDRef <> 'A' and kbvt.KhamBenh_VTYT_Id is not null then format( kbvt.NgayTao,'yyyyMMddHHmm')
						--					else NULL
						--					end 
						
						--, NGAY_KQ =   case when  xnct.Loai_IDRef = 'A' and kq.CLSKetQua_Id is not null then format( kq.ThoiGianThucHien,'yyyyMMddHHmm')
						--				else NULL
						--					end 
						----end 
						, NGAY_KQ = case when li.PhanNhom = 'DV' and clsyc.YeuCauChiTiet_Id is not null  and map.TenField = '01' then 
											REPLACE(CONVERT(varchar, KB.KetThucKham, 112) + CONVERT(varchar(5), KB.KetThucKham, 108),  ':','')
										else
							
								REPLACE(CONVERT(varchar, COALESCE(kq.NgayKhoaDuLieu, case when kq.NgayTao>kq.ThoiGianThucHien then kq.NgayTao else  kq.ThoiGianThucHien end, bapt.ThoiGianKetThuc), 112) + CONVERT(varchar(5), COALESCE(kq.NgayKhoaDuLieu, case when kq.NgayTao>kq.ThoiGianThucHien then kq.NgayTao else  kq.ThoiGianThucHien end, bapt.ThoiGianKetThuc), 108),  ':','')
									end
						, MA_PTTT =  1 
				
						, MA_PTTT_QT = case when  li.PhanNhom = 'DV' and ptyc.BenhAnPhauThuat_YeuCau_Id is not null then icd9.MaICD9_CM else null end
						, MAHIEU = D.mahieusp
						, TSD = null--case when d.TaiSuDung = 1 then '1' else '' end
						, PPVC = case 
								WHEN map.TenField in ('06','18') THEN isnull(isnull(ppvc.Dictionary_Name_en,ppvc.Dictionary_Code),'4') 
								else isnull(ppvc.Dictionary_Name_en,ppvc.Dictionary_Code) end
						--isnull(ppvc.Dictionary_Name_en,ppvc.Dictionary_Code)
						, VITRI = ''--left(clsyc.VITRI,3)
						, ma_may = case when ndv.CapTren_Id = 1 then  isnull(kqct.MaMay_Lis,'')
											when mamay.Dictionary_Code = 'KXD' Then null
									else mamay.Dictionary_Code end
						, Nguoi_TH = -- a Thanh VNTD IT YC null người TH lấy người chỉ định 01/07/2024
									isnull(case when li.PhanNhom = 'DV' and map.TenField = '01'  then bskb.SoChungChiHanhNghe
											when li.PhanNhom = 'DV' and ptyc.BenhAnPhauThuat_YeuCau_Id is not null then dbo.Get_MaBacSi_XML3_By_BenhAnPhauThuat_Id(bapt.BenhAnPhauThuat_Id)
											when li.PhanNhom = 'DV' and kq.CLSKetQua_Id is not null then bskq.SoChungChiHanhNghe
											else NULL end
											,
											case when li.PhanNhom = 'DV' and clsyc.YeuCauChiTiet_Id is not null then bscls.SoChungChiHanhNghe
											when li.PhanNhom <> 'DV' and ntkb.KhamBenh_Id is not null then bstt.SoChungChiHanhNghe
											when li.PhanNhom <> 'DV' and kbvt.KhamBenh_Id is not null then bskb_vt.SoChungChiHanhNghe
											when li.PhanNhom <> 'DV' and PTVT.BenhAnPhauThuat_VTYT_Id is not null then bspt_vt.SoChungChiHanhNghe
										else null end
										)
				From	(
							Select	
								xnct.XacNhanChiPhiChiTiet_Id,
								xnct.XacNhanChiPhi_Id,
								xnct.Loai_IDRef,
								xnct.IDRef,
								xnct.NoiDung_Id,
								xnct.NoiDung,
								xnct.SoLuong,
								xnct.DonGiaDoanhThu,
								DonGiaHoTro = CASE WHEN CHARINDEX( '.01', CAST(xnct.DonGiaHoTro as varchar(20))) > 0 
											THEN CAST(REPLACE(CAST(xnct.DonGiaHoTro as varchar(20)), '.01', '.00') as Decimal(18, 3))
									ELSE CAST(xnct.DonGiaHoTro as Decimal(18, 3)) END,
								xnct.DonGiaHoTroChiTra,
								xnct.DonGiaThanhToan,
								xnct.SoLuong_New,
								xnct.DonGiaHoTroChiTra_New,
								xnct.Loai,
								xnct.NgayCapNhat,
								xnct.NguoiCapNhat_Id,
								xnct.PhongBan_Id,
								xnct.NgoaiTru_ToaThuoc_ID,
								xnct.NoiTru_ToaThuoc_ID,
								xnct.TenDonViTinh,
								xnct.XN_DonGiaVon,
								xnct.XN_DonGiaMua,
								xnct.DonGiaHoTroChiTra_4210,
								xnct.Muc_Huong,
								xn.TiepNhan_Id, xn.BenhAn_Id

							From	XacNhanChiPhi xn (nolock) 
								JOIN XacNhanChiPhiChiTiet  (nolock) xnct On xnct.XacNhanChiPhi_Id = xn.XacNhanChiPhi_Id and xnct.DonGiaHoTroChiTra>0
							Where	TiepNhan_Id = @TiepNhan_Id
								And SoXacNhan IS NOT NULL		
						
						) xnct
				left JOIN	dbo.VienPhiNoiTru_Loai_IDRef LI (nolock)  ON LI.Loai_IDRef = xnct.Loai_IDRef and xnct.DonGiaHoTroChiTra>0
				LEFT JOIN	(	SELECT	dndv.DichVu_Id, mbc.MoTa, mbc.ID,				
										CASE 
											 WHEN mbc.TenField in ('CK','CongKham','KB','TienKham') THEN '01'
											 WHEN mbc.TenField in( 'XN','XetNghiem','XNHH') THEN '03'
											 WHEN mbc.TenField in ('Thuoc','OXY') THEN '16'
											 --WHEN mbc.TenField in( 'TTPT','TT','TT_PT') THEN '06'
											 WHEN mbc.TenField in( 'TTPT','TT','TT_PT') AND (ldv.MaLoaiDichVu = 'ThuThuat' Or ndv.MaNhomDichVu IN ('0307', '0304', '2101') or dndv.DichVu_Id in (19601,19618,19619,20531,21998,28915)) THEN '18' --Thủ thuật
											 WHEN mbc.TenField in( 'TTPT','TT','TT_PT') AND ldv.MaLoaiDichVu <> 'ThuThuat' And ndv.MaNhomDichVu NOT IN ('0307', '0304', '2101') and dndv.DichVu_Id not in (19601,19618,19619,20531,21998,28915) THEN '06' --Phẫu thuật
											 WHEN mbc.TenField in('DVKT_Cao', 'KTC') THEN '07'
											 WHEN mbc.TenField = 'VC' THEN '11'
											 WHEN mbc.TenField in  ('MCPM','Mau','DT','LayMau','DTMD') THEN '08'	--Máu
											 WHEN mbc.TenField in  ('CPMau') THEN '09'	--Chế phẩm máu
											 WHEN mbc.TenField in ('CDHA','CDHA_TDCN') THEN '04'
											 WHEN mbc.TenField = 'TDCN' THEN '05'
											 WHEN mbc.TenField = 'K' THEN 'Khac'
											 WHEN mbc.TenField in  ('NGCK','Giuong','GB') THEN '12'
											 WHEN mbc.TenField = 'VTYT' THEN '10'
										ELSE mbc.TenField
								END  as TenField
								,mbc.Ma 
								FROM	dbo.DM_MauBaoCao mbc
								JOIN	dbo.DM_DinhNghiaDichVu dndv ON dndv.NhomBaoCao_Id = mbc.ID
								LEFT JOIN DM_DichVu dv on dndv.DichVu_Id = dv.DichVu_Id
								LEFT JOIN DM_NhomDichVu ndv on dv.NhomDichVu_Id = ndv.NhomDichVu_Id
								LEFT JOIN DM_LoaiDichVu ldv on ndv.LoaiDichVu_Id = ldv.LoaiDichVu_Id
								WHERE	mbc.MauBC = 'BCVP_097'	) map ON map.DichVu_Id = xnct.NoiDung_Id 
				left JOIN	dbo.TiepNhan (nolock)  tn ON tn.TiepNhan_Id = xnct.TiepNhan_Id
				left join CLSYeuCauChiTiet (nolock)  clsyc on clsyc.YeuCauChiTiet_Id=xnct.IDRef and xnct.Loai_IDRef='A'
				left join ChungTuXuatBenhNhan  (nolock) xbn on ( xnct.IDRef = xbn.ChungTuXuatBN_Id and xnct.Loai_IDRef = 'I')
				LEFT JOIN (SELECT CLSYeuCauChiTiet_Id, SIDIssueDateTime = MAX(SIDIssueDateTime) 
							FROM Lab_SIDStatus (nolock)
							GROUP BY CLSYeuCauChiTiet_Id) lab  on clsyc.YeuCauChiTiet_Id = lab.CLSYeuCauChiTiet_Id
				LEFT JOIN BenhAn ba (nolock) on xnct.BenhAn_Id = ba.BenhAn_Id
				left join DM_ICD icd_nt on icd_nt.ICD_Id=ba.ICD_BenhChinh
				left join KhamBenh kb on kb.YeuCauChiTiet_Id = clsyc.YeuCauChiTiet_Id
				left join DM_ICD bc on BC.ICD_ID=kb.ChanDoanICD_Id
				left join DM_BenhVien bvct (Nolock) on kb.ChuyenDenBenhVien_Id = bvct.BenhVien_Id						   			
				left join dm_phongban (nolock)  pb on pb.PhongBan_Id = kb.PhongBan_Id
				LEFT JOIN	dbo.Lst_Dictionary (nolock)  lst ON lst.Dictionary_Id = tn.TuyenKhamBenh_Id
				LEFT JOIN	dbo.DM_BenhVien (nolock)  ngt ON ngt.BenhVien_Id = tn.NoiGioiThieu_Id
				LEFT JOIN	DM_Duoc (nolock)  d ON d.Duoc_Id = xnct.NoiDung_Id AND li.PhanNhom = 'DU' And ISNULL(D.BHYT,0) = 1
				LEFT JOIN	dbo.DM_LoaiDuoc (nolock)  ld ON ld.LoaiDuoc_Id = d.LoaiDuoc_Id
				LEFT JOIN	dbo.DM_DonViTinh (nolock)  dvt ON dvt.DonViTinh_Id = d.DonViTinh_Id
				left join dbo.DM_DichVu (nolock)  dv on dv.DichVu_Id = xnct.NoiDung_Id AND li.PhanNhom = 'DV'
				left join dbo.Lst_Dictionary (nolock)  dd ON dd.Dictionary_Id = d.DuongDung_Id
				left join CLSYeuCau yc (nolock)  on yc.CLSYeuCau_Id=clsyc.CLSYeuCau_Id
				left join CLSKetQua kq (Nolock) on kq.CLSYeuCau_Id=yc.CLSYeuCau_Id
				left join CLSKetQuaChiTiet kqct(nolock) on kq.CLSKetQua_Id=kqct.CLSKetQua_Id 
													and kqct.CLSKetQuaChiTiet_Id=(select max(CLSKetQuaChiTiet_Id) from CLSKetQuaChiTiet cc where cc.CLSKetQua_Id=kq.CLSKetQua_Id)
				left join BenhAnPhauThuat_YeuCau ptyc (nolock) on ptyc.CLSYeuCauChiTiet_Id = clsyc.YeuCauChiTiet_Id
				left join BenhAnPhauThuat_VTYT  (nolock) PTVT on xbn.BenhAnPhauThuat_VTYT_ID = PTVT.BenhAnPhauThuat_VTYT_Id
				left join BenhAnPhauThuat bapt (nolock) on bapt.BenhAnPhauThuat_Id = isNULL(PTVT.BenhAnPhauThuat_Id	,PTYC.BenhAnPhauThuat_Id)				
				--left join ToaThuoc tthuoc on tthuoc.ToaThuoc_Id = xbn.ToaThuocNgoaiTru_id
				--left join KhamBenh_ToaThuoc kbtt on kbtt.KhamBenh_ToaThuoc_Id = tthuoc.KhamBenh_ToaThuoc_Id
				left join KhamBenh_VTYT kbvt (nolock)  on  xnct.IDRef = kbvt.KhamBenh_VTYT_Id and li.PhanNhom = 'DU' and kbvt.Duoc_Id = d.Duoc_Id
				left join KhamBenh kb1  (nolock) on  kb1.KhamBenh_Id = kbvt.KhamBenh_Id

				---- Thuốc ty lệ 
				left join DM_DoiTuong_GiaDuoc_TyLe (nolock)  tyle on tyle.DoiTuong_Id = XBN.DoiTuong_Id and tyle.Duoc_Id = d.Duoc_Id
				--Lấy ra ngày y lệnh
				left join NoiTru_ToaThuoc nttt (nolock)  on xbn.ToaThuoc_Id = nttt.ToaThuoc_Id
				left join NoiTru_KhamBenh ntkb  (nolock) on nttt.khambenh_id = ntkb.khambenh_id
			-- ngày kê VTTT
				
				
				-----datpt29 lấy ra mã khoa chỉ định
				--left join NoiTru_LuuTru ltru1 (nolock)  on ltru1.LuuTru_Id = ntkb.LuuTru_Id
				--left join DM_PhongBan (nolock)  PBYLENH on PBYLENH.PhongBan_Id = ltru1.PhongBan_Id--YLENH
				--left join DM_PhongBan (nolock)  PBCD on PBCD.PhongBan_Id = yc.NoiYeuCau_Id--CD DICH VU
				--left join DM_PhongBan  (nolock) PBKB_DUOC on PBKB_DUOC.PhongBan_Id = kb1.PhongBan_Id -- TOA THUỐc & KBVT
				--end datpt29
				
				--Lấy ra Ma_Bac_Si
				left join vw_NhanVien bstt (nolock) on bstt.NhanVien_Id=ntkb.BasSiKham_Id
				LEFT JOIN vw_NhanVien  (nolock) bskb on bskb.NhanVien_Id=kb.BacSiKham_Id
				LEFT JOIN vw_NhanVien  (nolock) bskb_vt on bskb_vt.NhanVien_Id=kb1.BacSiKham_Id
				left join vw_NhanVien bscls (nolock) on bscls.NhanVien_Id=yc.BacSiChiDinh_Id
				left join vw_NhanVien  (nolock) bskq on bskq.nhanvien_Id = kq.BacSiKetLuan_Id	
				left join NhanVien_User_Mapping (nolock)  usmap on PTVT.NguoiTao_Id = usmap.User_Id
				left join vw_NhanVien bspt_VT (nolock)  on usmap.NhanVien_Id = bspt_VT.NhanVien_Id
				left join DM_ICD9_CM icd9 on icd9.ICD9_CM_Id = dv.ICD9_CM_Id
				left join Lst_Dictionary ppvc on ppvc.Dictionary_Id = bapt.PhuongPhapVoCam_Id 
				left join Lst_Dictionary mamay on mamay.Dictionary_Id = isnull(kq.ThietBi_Id,0)
				
				LEFT JOIN DM_NhomDichVu ndv (nolock) on yc.NhomDichVu_Id = ndv.NhomDichVu_Id

				LEFT JOIN DM_PhongBan pbsd (Nolock) on xnct.PhongBan_Id = pbsd.PhongBan_Id
				LEFT JOIN DM_PhongBan pbRa (Nolock) on ba.KhoaRa_Id = pbRa.PhongBan_Id
				WHERE	xnct.DonGiaHoTroChiTra > 0
			
				AND (		(LI.PhanNhom  in  ('DU') and  ld.LoaiVatTu_Id IN ('V'))
							or  ( isnull(map.TenField,'') not in  ('08' ,'16') and LI.PhanNhom  in  ('DV'))
					)
				and isnull(ld.MaLoaiDuoc,'') not in ('OXY', 'OXY1','LD0143','VTYT003')
	   ) XML3 where XML3.So_Luong > 0 
---- END ADD BẢNG 3


---- BEGIN ADD BẢNG 4
	--DELETE FROM [XML130].[dbo].[TT_04_CLS] WHERE MA_LK = @Ma_Lk
	INSERT INTO [XML130].[dbo].[TT_04_CLS](	
	[MA_LK]
      ,[STT]
      ,[MA_DICH_VU]
      ,[MA_CHI_SO]
      ,[TEN_CHI_SO]
      ,[GIA_TRI]
      ,[DON_VI_DO]
      ,[MO_TA]
      ,[KET_LUAN]
      ,[NGAY_KQ]
      ,[MA_BS_DOC_KQ]
      ,[DU_PHONG])
	SELECT	
	[MA_LK] = @Ma_Lk
    ,[STT] = row_number () over (order by (select 1))
    ,[MA_DICH_VU] = left (isnull(con.MaQuiDinh,dv.MaQuiDinh) ,15)
    ,[MA_CHI_SO] = isnull(isnull(con.MaChiSo,dv.MaChiSo),'0')
    ,[TEN_CHI_SO] = REPLACE(isnull(con.TenDichVu,dv.TenDichVu), CHAR(0x1F), '') 	
    ,[GIA_TRI] = REPLACE(REPLACE(REPLACE(REPLACE(isnull(ct.ketqua, ''), CHAR(0x1F), ''),'.','.'),'',''),'','')
    ,[DON_VI_DO] =  isnull(con.DonViTinh,dv.DonViTinh)
    ,[MO_TA] = MoTa_Text
    ,[KET_LUAN]= kq.ketluaN		
    ,[NGAY_KQ] = ISNULL(replace(convert(varchar , kq.ThoiGianThucHien, 112)+convert(varchar(5), kq.ThoiGianThucHien, 108), ':',''), replace(convert(varchar , yc.NgayGioYeuCau, 112)+convert(varchar(5), yc.NgayGioYeuCau, 108), ':',''))	
    ,[MA_BS_DOC_KQ] =  bsi.SoChungChiHanhNghe
    ,[DU_PHONG] = NULL
	From	(
				Select	*
				From	XacNhanChiPhi  (nolock) 
				Where	TiepNhan_Id = @TiepNhan_Id
					And SoXacNhan IS NOT NULL
				--AND		Loai = 'NgoaiTru'
				--	and Ngayxacnhan is not null
						
			) xn
	left Join	XacNhanChiPhiChiTiet (nolock)  xnct On xnct.XacNhanChiPhi_Id = xn.XacNhanChiPhi_Id and xnct.DonGiaHoTroChiTra>0
	left JOIN	dbo.VienPhiNoiTru_Loai_IDRef (nolock)  LI ON LI.Loai_IDRef = xnct.Loai_IDRef and xnct.DonGiaHoTroChiTra>0
	LEFT JOIN	(	SELECT	dndv.DichVu_Id, mbc.MoTa, mbc.ID,				
							CASE 
									WHEN mbc.TenField in ('CK','CongKham','KB','TienKham') THEN '01'
									WHEN mbc.TenField in( 'XN','XetNghiem','XNHH') THEN '03'
									WHEN mbc.TenField in ('Thuoc','OXY') THEN '16'
									WHEN mbc.TenField in( 'TTPT','TT','TT_PT') THEN '06'
									WHEN mbc.TenField in('DVKT_Cao', 'KTC') THEN '07'
									WHEN mbc.TenField = 'VC' THEN '11'
									WHEN mbc.TenField in  ('MCPM','Mau','DT','LayMau','DTMD') THEN '08'	
									WHEN mbc.TenField in ('CDHA','CDHA_TDCN') THEN '04'
									WHEN mbc.TenField = 'TDCN' THEN '05'
									WHEN mbc.TenField = 'K' THEN 'Khac'
									WHEN mbc.TenField in  ('NGCK','Giuong','GB') THEN '12'
									WHEN mbc.TenField = 'VTYT' THEN '10'
							ELSE mbc.TenField
					END  as TenField
					,mbc.Ma 
					FROM	dbo.DM_MauBaoCao mbc
					JOIN	dbo.DM_DinhNghiaDichVu dndv ON dndv.NhomBaoCao_Id = mbc.ID
					WHERE	mbc.MauBC = 'BCVP_097'	) map ON map.DichVu_Id = xnct.NoiDung_Id 
	left JOIN	dbo.TiepNhan (nolock)  tn ON tn.TiepNhan_Id = xn.TiepNhan_Id
	left join (
					select  PhongBan_Id = max(PhongBan_Id)
							, kb.TiepNhan_Id
							,kb.BacSiKham_Id
							, kb.ThoiGianKham
					from KhamBenh kb (nolock) 
					left join TiepNhan  (nolock) tn on tn.TiepNhan_Id = kb.TiepNhan_Id 
					group by kb.BenhNhan_Id, kb.TiepNhan_Id, NgayKham,kb.BacSiKham_Id,kb.ThoiGianKham
					) KB on 	kb.TiepNhan_Id = xn.TiepNhan_Id	 and kb.ThoiGianKham IN (SELECT TOP 1 ThoigianKham FROM KhamBenh k1
																					WHERE k1.TiepNhan_Id = kb.TiepNhan_Id )	
				   			
	left join dm_phongban  (nolock) pb on pb.PhongBan_Id = kb.PhongBan_Id
	left JOIN dbo.DM_BenhNhan (nolock)  bn ON bn.BenhNhan_Id = tn.BenhNhan_Id
	left JOIN DM_DoiTuong (nolock)  dt on dt.DoiTuong_Id = tn.DoiTuong_Id
	left join dbo.DM_DichVu  (nolock) dv on dv.DichVu_Id = xnct.NoiDung_Id AND li.PhanNhom = 'DV'
	left join DM_NhomDichVu  (nolock) ndv on ndv.NhomDichVu_Id = dv.NhomDichVu_Id
	left join DM_DIchVU (nolock)  con on con.CapTren_Id = dv.DichVu_ID
	left join CLSYeuCauChiTiet  (nolock) clsyc on clsyc.YeuCauChiTiet_Id=xnct.IDRef and xnct.Loai_IDRef='A'
	left join CLSYeuCau yc  (nolock) on yc.CLSYeuCau_Id=clsyc.CLSYeuCau_Id
	left join CLSKetQua kq (Nolock) on kq.CLSYeuCau_Id=yc.CLSYeuCau_Id
	left join clsketquachitiet ct (nolock) on ct.clsketqua_id = kq.clsketqua_id and ct.DichVU_Id = isnull(con.DichVU_ID,dv.DichVU_ID)
	left join Lst_Dictionary mm (nolock) on mm.Dictionary_Id = kq.ThietBi_Id and mm.Dictionary_Type_Code = 'NhomThietBi'
	left join vw_NhanVien bsi on bsi.NhanVien_Id = isnull(kq.BacSiKetLuan_Id,kq.BacSiThucHien_Id)
	WHERE xnct.DonGiaHoTroChiTra > 0 AND (xnct.DonGiaHoTro * xnct.SoLuong) <> 0 and ndv.LoaiDichVu_Id = 2
	and ct.ketqua is not null
	and bsi.SoChungChiHanhNghe is not null

---- END ADD BẢNG 4
---- BEGIN ADD BẢNG 5
	--DELETE FROM [XML130].[dbo].[TT_05_LAMSANG] WHERE MA_LK = @Ma_Lk
	INSERT INTO [XML130].[dbo].[TT_05_LAMSANG]
	(	[MA_LK]
      ,[STT]
      ,[DIEN_BIEN_LS]
      ,[GIAI_DOAN_BENH]
      ,[HOI_CHAN]
      ,[PHAU_THUAT]
      ,[THOI_DIEM_DBLS]
      ,[NGUOI_THUC_HIEN]
      ,[DU_PHONG])
	SELECT  
	[MA_LK] = @Ma_Lk	
      ,[STT] = row_number () over (order by (select 1))
      ,[DIEN_BIEN_LS] = dien_bien
      ,[GIAI_DOAN_BENH] = NULL
      ,[HOI_CHAN] = hoi_chan
      ,[PHAU_THUAT] = phau_thuat
      ,[THOI_DIEM_DBLS] = NGAY_YL
      ,[NGUOI_THUC_HIEN] = Ma_Bsi
      ,[DU_PHONG] = NULL
	  
	From 
	( 
		SELECT		DIEN_BIEN = isnull(pt.ICD_TruocPhauThuat_MoTa,isnull(yc.NoiDungChiTiet,YC.Chandoan) ) 
					, HOI_CHAN = null
					, PHAU_THUAT = isnull(pt.CanThiepPhauThuat,' ')	--+ isnull(pt.TrinhTuThucHien_Text,isnull(yc.NoiDungChiTiet,YC.Chandoan))
					, NGAY_YL = replace(convert(varchar , pt.ThoiGianKetThuc, 112)+convert(varchar(5), pt.ThoiGianKetThuc, 108), ':','')
					, Ma_Bsi = dbo.Get_MaBacSi_XML3_By_BenhAnPhauThuat_Id(pt.BenhAnPhauThuat_Id)
		From	(
					Select	*
					From	XacNhanChiPhi (nolock) 
					Where	TiepNhan_Id = @TiepNhan_Id
						And SoXacNhan IS NOT NULL
				) xn
		left Join	XacNhanChiPhiChiTiet (nolock)  xnct On xnct.XacNhanChiPhi_Id = xn.XacNhanChiPhi_Id and xnct.DonGiaHoTroChiTra>0
		left JOIN	dbo.VienPhiNoiTru_Loai_IDRef (nolock)  LI ON LI.Loai_IDRef = xnct.Loai_IDRef and xnct.DonGiaHoTroChiTra>0
		left JOIN	dbo.TiepNhan (nolock)  tn ON tn.TiepNhan_Id = xn.TiepNhan_Id
		left join dbo.DM_DichVu  (nolock) dv on dv.DichVu_Id = xnct.NoiDung_Id AND li.PhanNhom = 'DV'
		left join DM_NhomDichVu  (nolock) ndv on ndv.NhomDichVu_Id = dv.NhomDichVu_Id
		left join CLSYeuCauChiTiet (nolock)  clsyc on clsyc.YeuCauChiTiet_Id=xnct.IDRef and xnct.Loai_IDRef='A'
		left join CLSYeuCau yc (nolock)  on yc.CLSYeuCau_Id=clsyc.CLSYeuCau_Id
		join BenhAnPhauThuat  pt (Nolock) on pt.CLSYeuCau_Id=yc.CLSYeuCau_Id
		WHERE	xnct.DonGiaHoTroChiTra > 0
		AND (xnct.DonGiaHoTro * xnct.SoLuong) <> 0
		and ndv.LoaiDichVu_ID in (3,8)
		union all
		SELECT  
		dien_bien =  case when hc.HoiChan_Id is not null then isnull(hc.TomTat_TienSuBenh +', ','') + isnull(hc.TinhTrang +', ','') + isnull(TomTat_DienBienBenh,'')  else  '' end
		, hoi_chan =case when hc.HoiChan_Id is not null then isnull(hc.ChanDoan +', ','') + isnull(hc.HuongXuTri +', ','') + isnull(ChamSoc,'')   else '' end
		, phau_thuat = ''
		, ngay_yl = case when hc.HoiChan_Id is not null then replace(convert(varchar , hc.ThoiGianHoiChan, 112)+convert(varchar(5),  hc.ThoiGianHoiChan, 108), ':','')   else  '' end
		, Ma_Bsi = nv.SoChungChiHanhNghe
		From	(
					Select	*
					From	XacNhanChiPhi (nolock) 
					Where	TiepNhan_Id = @TiepNhan_Id
						And SoXacNhan IS NOT NULL
				) xn
		left join HoiChan hc (nolock) on hc.BenhAn_Id = xn.TiepNhan_Id
		left join vw_NhanVien nv on nv.NhanVien_Id = hc.BacSi_Id
		WHERE	hc.HoiChan_Id is not null
	) A
---- END ADD BẢNG 5

---- BEGIN ADD BẢNG 6
	DELETE FROM [XML130].[dbo].[TT_06_HIV] WHERE MA_LK = @Ma_Lk
	INSERT INTO [XML130].[dbo].[TT_06_HIV]
	(	
		[MA_LK]
		, [MA_THE_BHYT]
		, [SO_CCCD]
		, [NGAYKD_HIV]
		, [BDDT_ARV]
		, [MA_PHAC_DO_DIEU_TRI_BD]
		, [MA_BAC_PHAC_DO_BD]
		, [MA_LYDO_DTRI]
		, [LOAI_DTRI_LAO] 
		, [PHACDO_DTRI_LAO] 
		, [NGAYBD_DTRI_LAO]
		, [NGAYKT_DTRI_LAO]
		, [MA_LYDO_XNTL_VR]
		, [NGAY_XN_TLVR]
		, [KQ_XNTL_VR] 
		, [NGAY_KQ_XN_TLVR] 
		, [MA_LOAI_BN]
		, [MA_TINH_TRANG_DK] 
		, [LAN_XN_PCR] 
		, [NGAY_XN_PCR] 
		, [NGAY_KQ_XN_PCR]
		, [MA_KQ_XN_PCR]
		, [NGAY_NHAN_TT_MANG_THAI] 
		, [NGAY_BAT_DAU_DT_CTX] 
		, [MA_XU_TRI] 
		, [NGAY_BAT_DAU_XU_TRI] 
		, [NGAY_KET_THUC_XU_TRI]
		, [MA_PHAC_DO_DIEU_TRI]
		, [MA_BAC_PHAC_DO]
		, [SO_NGAY_CAP_THUOC_ARV] 
		, [DU_PHONG] 
		)
	SELECT	
		[MA_LK] = @Ma_Lk
		,	MA_THE_BHYT	 = ''
		,	SO_CCCD	 = ''
		,	NGAYKD_HIV	 = ''
		,	BDDT_ARV	 = ''
		,	MA_PHAC_DO_DIEU_TRI_BD	 = ''
		,	MA_BAC_PHAC_DO_BD	 = ''
		,	MA_LYDO_DTRI	 = ''
		,	LOAI_DTRI_LAO	 = ''
		,	PHACDO_DTRI_LAO	 = ''
		,	NGAYBD_DTRI_LAO	 = ''
		,	NGAYKT_DTRI_LAO	 = ''
		,	MA_LYDO_XNTL_VR	 = ''
		,	NGAY_XN_TLVR	 = ''
		,	KQ_XNTL_VR	 = ''
		,	NGAY_KQ_XN_TLVR	 = ''
		,	MA_LOAI_BN	 = ''
		,	MA_TINH_TRANG_DK	 = ''
		,	LAN_XN_PCR	 = ''
		,	NGAY_XN_PCR	 = ''
		,	NGAY_KQ_XN_PCR	 = ''
		,	MA_KQ_XN_PCR	 = ''
		,	NGAY_NHAN_TT_MANG_THAI	 = ''
		,	NGAY_BAT_DAU_DT_CTX	 = ''
		,	MA_XU_TRI	 = ''
		,	NGAY_BAT_DAU_XU_TRI	 = ''
		,	NGAY_KET_THUC_XU_TRI	 = ''
		,	MA_PHAC_DO_DIEU_TRI	 = ''
		,	MA_BAC_PHAC_DO	 = ''
		,	SO_NGAY_CAP_THUOC_ARV	 = ''
		,	DU_PHONG	 = ''
	
---- END ADD BẢNG 6

---- BEGIN ADD BẢNG 7
	--DELETE FROM [XML130].[dbo].[TT_07_GIAY_RAVIEN] WHERE MA_LK = @Ma_Lk
	INSERT INTO [XML130].[dbo].[TT_07_GIAY_RAVIEN]
	(	
		MA_LK
		, 	SO_LUU_TRU
		, 	MA_YTE
		, 	MA_KHOA_RV
		, 	NGAY_VAO
		, 	NGAY_RA
		, 	MA_DINH_CHI_THAI
		, 	NGUYENNHAN_DINHCHI
		, 	THOIGIAN_DINHCHI
		, 	TUOI_THAI
		, 	CHAN_DOAN_RV
		, 	PP_DIEUTRI
		, 	GHI_CHU
		, 	MA_TTDV
		, 	MA_BS
		, 	TEN_BS
		, 	NGAY_CT
		, 	MA_CHA
		, 	MA_ME
		, 	MA_THE_TAM
		, 	HO_TEN_CHA
		, 	HO_TEN_ME
		, 	SO_NGAY_NGHI
		, 	NGOAITRU_TUNGAY
		, 	NGOAITRU_DENNGAY
		, DU_PHONG

		)
	SELECT	
		[MA_LK] = @Ma_Lk
		, 	SO_LUU_TRU	= ba.SoLuuTru
		, 	MA_YTE	= bn.SoVaoVien
		, 	MA_KHOA_RV	= pb.MaTheoQuiDinh
		, 	NGAY_VAO	= FORMAT(ba.ThoiGianVaoVien,'yyyyMMddHHmm')
		, 	NGAY_RA	= FORMAT(ba.ThoiGianRaVien,'yyyyMMddHHmm')
		, 	MA_DINH_CHI_THAI	= 0
		, 	NGUYENNHAN_DINHCHI	= ''
		, 	THOIGIAN_DINHCHI	= ''
		, 	TUOI_THAI	= ''
		, 	CHAN_DOAN_RV	= ba.ChanDoanRaVien
		, 	PP_DIEUTRI	= bact.PPDT
		, 	GHI_CHU	= bact.LoiDanThayThuoc
		, 	MA_TTDV	= '2096091139'
		, 	MA_BS	= nv.SoBHXH
		, 	TEN_BS	=  nv.Ho  + ' ' + nv.Ten
		, 	NGAY_CT	= FORMAT(ba.ThoiGianRaVien,'yyyyMMdd')
		, 	MA_CHA	= ''
		, 	MA_ME	= ''
		, 	MA_THE_TAM	= ''
		, 	HO_TEN_CHA	= ''
		, 	HO_TEN_ME	= ''
		, 	SO_NGAY_NGHI	= DATEDIFF(DAY, ba.NgoaiTruNghiTu, ba.NgoaiTruNghiDen)
		, 	NGOAITRU_TUNGAY	= FORMAT(ba.NgoaiTruNghiTu,'yyyyMMdd')
		, 	NGOAITRU_DENNGAY = FORMAT(ba.NgoaiTruNghiDen,'yyyyMMdd')
		, NULL

	From	(
				Select	*
				From	XacNhanChiPhi (nolock) 
				Where	TiepNhan_Id = @TiepNhan_Id and BenhAn_Id is not null
			
			) xn
		join BenhAn  (nolock) ba on ba.BenhAn_Id = xn.BenhAn_Id
		join TiepNhan (nolock)  tn on tn.TiepNhan_Id = ba.TiepNhan_Id
		left join DM_BenhNhan (nolock)  bn on bn.BenhNhan_Id = ba.BenhNhan_Id
		left join Lst_Dictionary (nolock)  nghe on nghe.Dictionary_Id = bn.NgheNghiep_Id
		left join DM_PhongBan (nolock)  pb on pb.PhongBan_Id = ba.KhoaRa_Id
		left join Lst_Dictionary (nolock)  dtoc on dtoc.Dictionary_Id = bn.DanToc_Id
		left join BenhAnChiTiet (nolock)  bact on bact.BenhAn_Id = ba.BenhAn_Id
		left join eHospital_ThuyDienUB_NSTL..NS_NHANVIEN nv (nolock)  on nv.NhanVien_Id = ba.BacSiTruongKhoa_Id
		left join Lst_Dictionary (nolock)  lba on lba.Dictionary_Id = ba.LoaiBenhAn_Id
		where lba.Dictionary_Name_Ru = '01/BV'
	

---- END ADD BẢNG 7

------ BEGIN ADD BẢNG 8
	DELETE FROM [XML130].[dbo].[TT_08_HSBA] WHERE MA_LK = @Ma_Lk
	INSERT INTO [XML130].[dbo].[TT_08_HSBA]
	(	
		MA_LK
		, MA_LOAI_KCB
		, HO_TEN_CHA
		, HO_TEN_ME
		, NGUOI_GIAM_HO
		, DON_VI
		, NGAY_VAO
		, NGAY_RA
		, CHAN_DOAN_VAO
		, CHAN_DOAN_RV
		, QT_BENHLY
		, TOMTAT_KQ
		, PP_DIEUTRI
		, NGAY_SINHCON
		, NGAY_CONCHET
		, SO_CONCHET
		, KET_QUA_DTRI
		, GHI_CHU
		, MA_TTDV
		, NGAY_CT
		, MA_THE_TAM
		, DU_PHONG
		)
	SELECT	
		MA_LK = @Ma_Lk
		, MA_LOAI_KCB = ''--'03'
		, HO_TEN_CHA = ''
		, HO_TEN_ME = ''
		, NGUOI_GIAM_HO =''-- bn.NguoiLienHe
		, DON_VI = ''--tn.DiaChiLienHe
		, NGAY_VAO =''-- FORMAT(ba.ThoiGianVaoVien,'yyyymmddHHMM')
		, NGAY_RA =''-- FORMAT(ba.ThoiGianRaVien,'yyyymmddHHMM')
		, CHAN_DOAN_VAO = ''--ba.ChanDoanVaoKhoa
		, CHAN_DOAN_RV = ''-- ba.ChanDoanRaVien
		, QT_BENHLY =''-- bact.QuaTrinhBenhLyVaDienBienLamSang
		, TOMTAT_KQ = ''--isnull(bact.XNMau +'; ','') + isnull(bact.XNTeBao +'; ','') + isnull(bact.XNBLGP +'; ','') + isnull(bact.XNXQuang +'; ','') + isnull(bact.XNSieuAm +'; ','') + isnull(bact.CacXNKhac,'')
		, PP_DIEUTRI = ''--bact.PPDT
		, NGAY_SINHCON = ''
		, NGAY_CONCHET = ''
		, SO_CONCHET = ''
		, KET_QUA_DTRI = ''--case when kq.Dictionary_Code = 'Khoi' then '1'
								--when kq.Dictionary_Code = 'Giam' then '2'
								--when kq.Dictionary_Code = 'KhongThayDoi' then '3'
								--when kq.Dictionary_Code in ('nanghon')  then '4'
								--when kq.Dictionary_Code = 'TuVong' then '5'
								--when kq.Dictionary_Code in ('HHXV', 'NXV') then '6'
								---when kq.Dictionary_Code = 'Khoi' then '1'
						--else '7' end
		, GHI_CHU = ''--''
		, MA_TTDV = ''--N'2096008154'
		, NGAY_CT = ''-- FORMAT(ba.ThoiGianRaVien,'yyyymmdd')
		, MA_THE_TAM = ''
		, DU_PHONG = ''

	

------ END ADD BẢNG 8
-----------------------------------------------------

------ BEGIN ADD BẢNG 9
	DELETE FROM [XML130].[dbo].[TT_09_CHUNGSINH] WHERE MA_LK = @Ma_Lk
	INSERT INTO [XML130].[dbo].[TT_09_CHUNGSINH]
	(	
		MA_LK
		,	MA_BHXH_NND
		,	MA_THE_NND
		,	HO_TEN_NND
		,	NGAYSINH_NND
		,	MA_DANTOC_NND
		,	SO_CCCD_NND
		,	NGAYCAP_CCCD_NND
		,	NOICAP_CCCD_NND
		,	NOI_CU_TRU_NND
		,	MA_QUOCTICH
		,	MATINH_CU_TRU
		,	MAHUYEN_CU_TRU
		,	MAXA_CU_TRU
		,	HO_TEN_CHA
		,	MA_THE_TAM
		,	HO_TEN_CON
		,	GIOI_TINH_CON
		,	SO_CON
		,	LAN_SINH
		,	SO_CON_SONG
		,	CAN_NANG_CON
		,	NGAY_SINH_CON
		,	NOI_SINH_CON
		,	TINH_TRANG_CON
		,	SINHCON_PHAUTHUAT
		,	SINHCON_DUOI32TUAN
		,	GHI_CHU
		,	NGUOI_DO_DE
		,	NGUOI_GHI_PHIEU
		,	NGAY_CT
		,	SO
		,	QUYEN_SO
		,	MA_TTDV

		)
	SELECT	
		MA_LK = @Ma_Lk
		,	MA_BHXH_NND	= ''--	right(left (tn.SoBHYT,15),10)
		,	MA_THE_NND	= ''--	left (tn.SoBHYT,15)
		,	HO_TEN_NND	= ''--	bn.TenBenhNhan
		,	NGAYSINH_NND	= ''--	FORMAT(convert(datetime, bn.NgaySinh, 106)  , 'yyyyMMdd')
		,	MA_DANTOC_NND	= ''--	dtoc.Dictionary_Name_En
		,	SO_CCCD_NND	= ''--	isnull(te.Field_11,bn.CMND)
		,	NGAYCAP_CCCD_NND	=''--	 isnull(FORMAT(convert(datetime, bn.NgayCapCMND, 106)  , 'yyyyMMdd') ,FORMAT(convert(datetime, TE.NgayCap, 106)  , 'yyyyMMdd'))
		,	NOICAP_CCCD_NND	= ''--	isnull(bn.NoiCapCMND ,te.Field_21)
		,	NOI_CU_TRU_NND	= ''--	bn.DiaChi
		,	MA_QUOCTICH	= ''--	'000'
		,	MATINH_CU_TRU	= ''--	tinh.MaDonVi
		,	MAHUYEN_CU_TRU	= ''--	quan.MaDonVi
		,	MAXA_CU_TRU	= ''--	xa.MaDonVi
		,	HO_TEN_CHA	= ''--	cast(te.Field_4 as nvarchar(100)) 
		,	MA_THE_TAM = ''--	te.BHYTTam 
		,	HO_TEN_CON	= ''--	cast(te.Field_19 as nvarchar(100)) 
		,	GIOI_TINH_CON	= ''--	te.GioiTinh
		,	SO_CON	= ''--	te.SoConSinh
		,	LAN_SINH	= ''--	te.Field_13
		,	SO_CON_SONG = ''--	te.Field_14
		,	CAN_NANG_CON	= ''--	CAST( te.CanNang AS decimal(18,0) )
		,	NGAY_SINH_CON	= ''--	FORMAT(convert(datetime, te.field_12, 106)  , 'yyyyMMddHHmm')
		,	NOI_SINH_CON	= ''--	N'22:193:06694:Phố Tuệ Tĩnh,Phường Bạch Đằng,Thành phố Hạ Long,Tỉnh Quảng Ninh'
		,	TINH_TRANG_CON	= ''--	te.Field_18
		,	SINHCON_PHAUTHUAT	= ''--	case when te.SinhConPhauThuat = 1 then 1 else 0 end
		,	SINHCON_DUOI32TUAN	= ''--	case when SinhConPhauThuat = 1 then 1 else 0 end
		,	GHI_CHU	= ''--	te.Field_22
		,	NGUOI_DO_DE	= ''--	Ndd.TenNhanVien
		,	NGUOI_GHI_PHIEU	=''--	 NddR.TenNhanVien
		,	NGAY_CT	= ''--	FORMAT(convert(datetime, getdate() , 106)  , 'yyyyMMdd')
		,	SO	= ''--	'0' + right(te.SoPhieu , 4)
		,	QUYEN_SO	= ''--	'01'
		,	MA_TTDV	= ''--	N'2096008154'


---- end bảng 9

---- BEGIN ADD BẢNG 10
	DELETE FROM [XML130].[dbo].[TT_10_DUONGTHAI] WHERE MA_LK = @Ma_Lk
	INSERT INTO [XML130].[dbo].[TT_10_DUONGTHAI]
	(	
		MA_LK
		,	SO_SERI
		,	SO_CT
		,	SO_NGAY
		,	DON_VI
		,	CHAN_DOAN_RV
		,	TU_NGAY
		,	DEN_NGAY
		,	MA_TTDV
		,	TEN_BS
		,	MA_BS
		,	NGAY_CT


		)

	SELECT	

		MA_LK = @Ma_Lk
		,	SO_SERI	= kb.SoGiayNghiBHXH
		,	SO_CT	= kb.SoGiayNghiBHXH
		,	SO_NGAY	= DATEDIFF (dd,kb.BatDauGiayNghi,kb.KetThucGiayNghi) + 1
		,	DON_VI	= tn.NoiLamViec
		,	CHAN_DOAN_RV	= xn.ChanDoan
		,	TU_NGAY	= KB.BatDauGiayNghi
		,	DEN_NGAY	= KB.KetThucGiayNghi
		,	MA_TTDV	= '2096091139'
		,	TEN_BS	= bs.TenNhanVien
		,	MA_BS	= mabs.SoChungChiHanhNghe
		,	NGAY_CT	= KB.NgayKham

	From	(
				Select	*
				From	XacNhanChiPhi (nolock) 
				Where	TiepNhan_Id = @TiepNhan_Id and BenhAn_Id is null
			
			) xn
			JOIN  KhamBenh kb ON KB.TiepNhan_Id = xn.TiepNhan_Id
			join TiepNhan tn on tn.TiepNhan_Id=kb.TiepNhan_Id
			left join DM_BenhNhan bn on bn.BenhNhan_Id=tn.BenhNhan_Id
			left join vw_NhanVien bs on bs.NhanVien_Id=kb.BacSiKham_Id
			left join CLSYeuCauChiTiet ct on ct.YeuCauChiTiet_Id=kb.YeuCauChiTiet_Id
			left join CLSYeuCau yc on yc.CLSYeuCau_Id=ct.CLSYeuCau_Id
			left join eHospital_ThuyDienUB_NSTL..NS_NHANVIEN mabs on mabs.NhanVien_Id=bs.NhanVien_Id
			left join DM_PhongBan pb on pb.PhongBan_Id=kb.PhongBan_Id
where kb.SoGiayNghiDuongThai is not null and kb.BatDauGiayNghi is not null and kb.KetThucGiayNghi is not null
---- END ADD BẢNG 10

--------------------------------------------------

---- BEGIN ADD BẢNG 11
--	DELETE FROM [XML130].[dbo].[TT_11_NGHI_BHXH] WHERE MA_LK = @Ma_Lk
	INSERT INTO [XML130].[dbo].[TT_11_NGHI_BHXH]
	(	
		MA_LK
		,	SO_CT
		,	SO_SERI
		,	SO_KCB
		,	DON_VI
		,	MA_BHXH
		,	MA_THE_BHYT
		,	CHAN_DOAN_RV
		,	PP_DIEUTRI
		,	MA_DINH_CHI_THAI
		,	NGUYENNHAN_DINHCHI
		,	TUOI_THAI
		,	SO_NGAY_NGHI
		,	TU_NGAY
		,	DEN_NGAY
		,	HO_TEN_CHA
		,	HO_TEN_ME
		,	MA_TTDV
		,	MA_BS
		,	NGAY_CT
		,	MA_THE_TAM
		,	MAU_SO
		, DU_PHONG
		)
	SELECT	
		MA_LK = @Ma_Lk
		,	SO_CT	= kb.SoGiayNghiBHXH
		,	SO_SERI	= kb.SoGiayNghiBHXH
		,	SO_KCB	= pb.TenPhongBan_Ru + '.' + isnull(CONVERT(Nvarchar(20),yc.SoThuTu),'') + '/KCB'
		,	DON_VI	= isnull(tn.NoiLamViec, N'Không rõ')
		,	MA_BHXH	= SUBSTRING( CasT(tn.SoBHYT as VarCHAR(20)), 6, 10)
		,	MA_THE_BHYT	= SUBSTRING( CasT(tn.SoBHYT as VarCHAR(20)), 1, 15)
		,	CHAN_DOAN_RV	= xn.ChanDoan
		,	PP_DIEUTRI	= kb.ChanDoanKhoaKham + ',' + isnull(kb.PhuongPhapDieuTriGiayNghi,'')
		,	MA_DINH_CHI_THAI	= 0
		,	NGUYENNHAN_DINHCHI	= ''
		,	TUOI_THAI	= null
		,	SO_NGAY_NGHI	= DATEDIFF (dd,kb.BatDauGiayNghi,kb.KetThucGiayNghi) + 1
		,	TU_NGAY	= FORMAT(KB.BatDauGiayNghi,'yyyyMMdd' )
		,	DEN_NGAY	= FORMAT(KB.KetThucGiayNghi,'yyyyMMdd' )
		,	HO_TEN_CHA	= ''
		,	HO_TEN_ME	= bn.NguoiLienHe
		,	MA_TTDV	= '2096091139'
		,	MA_BS	= mabs.SoBHXH
		,	NGAY_CT	= FORMAT(KB.NgayKham,'yyyyMMdd' )
		,	MA_THE_TAM	= null
		,	MAU_SO	= 'CT07'
		,	NULL


	From	(
				Select	*
				From	XacNhanChiPhi (nolock) 
				Where	TiepNhan_Id = @TiepNhan_Id and BenhAn_Id is null
			) xn
			join KhamBenh kb on kb.TiepNhan_Id = xn.TiepNhan_Id
			join TiepNhan tn on tn.TiepNhan_Id=kb.TiepNhan_Id
			left join DM_BenhNhan bn on bn.BenhNhan_Id=tn.BenhNhan_Id
			left join vw_NhanVien bs on bs.NhanVien_Id=kb.BacSiKham_Id
			left join CLSYeuCauChiTiet ct on ct.YeuCauChiTiet_Id=kb.YeuCauChiTiet_Id
			left join CLSYeuCau yc on yc.CLSYeuCau_Id=ct.CLSYeuCau_Id
			left join eHospital_ThuyDienUB_NSTL..NS_NHANVIEN mabs on mabs.NhanVien_Id=bs.NhanVien_Id
			left join DM_PhongBan pb on pb.PhongBan_Id=kb.PhongBan_Id
	where kb.SoGiayNghiBHXH is not null and kb.BatDauGiayNghi is not null and kb.KetThucGiayNghi is not null
	
---- END ADD BẢNG 11

--begin bảng 13
INSERT INTO [XML130].[dbo].[TT_13_GIAYCHUYENTUYEN]
		( MA_LK,
		SO_HOSO,
		SO_CHUYENTUYEN,
		GIAY_CHUYEN_TUYEN,
		MA_CSKCB,
		MA_NOI_DI,
		MA_NOI_DEN,
		HO_TEN,
		NGAY_SINH,
		GIOI_TINH,
		MA_QUOCTICH,
		MA_DANTOC,
		MA_NGHE_NGHIEP,
		DIA_CHI,
		MA_THE_BHYT,
		GT_THE_DEN,
		NGAY_VAO,
		NGAY_VAO_NOI_TRU,
		NGAY_RA,
		DAU_HIEU_LS,
		CHAN_DOAN_RV,
		QT_BENHLY,
		TOMTAT_KQ,
		PP_DIEUTRI,
		MA_BENH_CHINH,
		MA_BENH_KT,
		MA_BENH_YHCT,
		TEN_DICH_VU,
		TEN_THUOC,
		PP_DIEU_TRI,
		MA_LOAI_RV,
		MA_LYDO_CT,
		HUONG_DIEU_TRI,
		PHUONGTIEN_VC,
		HOTEN_NGUOI_HT,
		CHUCDANH_NGUOI_HT,
		MA_BAC_SI,
		MA_TTDV,
		DU_PHONG )

	SELECT		
	
			MA_LK = @Ma_LK,
			SO_HOSO = cv.SoPhieu,--tùy chỉnh theo dự án
			SO_CHUYENTUYEN = left (SoPhieu,6)  ,--tùy chỉnh theo dự án
			GIAY_CHUYEN_TUYEN = right(SoPhieu,8),--tùy chỉnh theo dự án
			MA_CSKCB = '22030', --tùy chỉnh theo dự án
			MA_NOI_DI = TD.TenBenhVien_En,
			MA_NOI_DEN = bv.TenBenhVien_En,
			HO_TEN = TenBenhNhan,
			NGAY_SINH = CASE	WHEN DM_BenhNhan.NgaySinh is null THEN convert(VARCHAR, DM_BenhNhan.NamSinh) + '01010000'	
						WHEN DM_BenhNhan.NgaySinh is not null THEN convert(VARCHAR, DM_BenhNhan.NgaySinh, 112) +'0000' end, --convert(VARCHAR,bn.GioPhut) END
			GIOI_TINH = CASE WHEN DM_BenhNhan.GioiTinh = 'T' THEN 1 
						WHEN DM_BenhNhan.GioiTinh = 'G' THEN 2
					END,
			MA_QUOCTICH = quoctich.Dictionary_Name_ru,
			MA_DANTOC = dantoc.Dictionary_Name_En,
			MA_NGHE_NGHIEP = nghenghiep.Dictionary_Name_En,
			DIA_CHI = isnull(DM_BenhNhan.diachi, TN.noilamviec),
			MA_THE_BHYT = left (tn.SoBHYT,15),
			GT_THE_DEN =  convert(VARCHAR, BHYTDenNgay, 112),
			NGAY_VAO = replace(convert(varchar , thoigiantiepnhan, 112)+convert(varchar(5), thoigiantiepnhan, 108), ':',''),
			NGAY_VAO_NOI_TRU = null,
			NGAY_RA = replace(convert(varchar , ThoiGianXacNhan, 112)+convert(varchar(5), ThoiGianXacNhan, 108), ':',''),
			DAU_HIEU_LS = cv.DauHieuLamSang,
			CHAN_DOAN_RV = @ChanDoan_PK,--tùy chỉnh theo dự án
			QT_BENHLY = isnull(kb.TrieuChungLamSang,cv.DauHieuLamSang),--tùy chỉnh theo dự án
			TOMTAT_KQ = cv.GhiChu,--tùy chỉnh theo dự án
			PP_DIEUTRI = N'Chuyển tuyến',
			MA_BENH_CHINH = @ICDKB,
			MA_BENH_KT =  case when  @ICD_PNT='' then @ICD_PK else @ICD_PNT end ,
			MA_BENH_YHCT = null,
			TEN_DICH_VU = isnull(cv.GhiChu, N'Khám bệnh'),--tùy chỉnh theo dự án
			TEN_THUOC = cv.ThuocDaDung,--tùy chỉnh theo dự án
			PP_DIEU_TRI = N'Chuyển tuyến',
			MA_LOAI_RV = null,--tùy chỉnh theo dự án
			MA_LYDO_CT = CASE WHEN lst.Dictionary_Id in (1021,10058) THEN 1 ELSE 2 END	, --tùy chỉnh theo dự án
			HUONG_DIEU_TRI = HuongDieuTri,
			PHUONGTIEN_VC = lst1.Dictionary_Name  ,
			HOTEN_NGUOI_HT = null,-- bổ sung combo chọn người đưa đi trong màn hình để lấy dữ liệu
			CHUCDANH_NGUOI_HT = null,-- bổ sung combo chọn người đưa đi trong màn hình để lấy dữ liệu
			MA_BAC_SI = bsi.SoChungChiHanhNghe,
			MA_TTDV = '2096091139',--tùy chỉnh theo dự án
			DU_PHONG  = null
	FROM ( select * from  TiepNhan where TiepNhan_Id = @TiepNhan_id and XacNhanChiPhi_Id is not null ) TN
		JOIN DM_BenhNhan (nolock) ON tn.BenhNhan_Id = DM_BenhNhan.BenhNhan_Id
		join XacNhanChiPhi xn (nolock) on xn.TiepNhan_Id = tn.TiepNhan_Id
		left join DM_BenhVien (nolock)  td on td.benhvien_id = tn.NoiGioiThieu_Id
		join ChuyenVien cv ( nolock ) on cv.TiepNhan_Id = tn.TiepNhan_Id
		join Lst_Dictionary lst on lst.Dictionary_Id = cv.LyDoChuyenVien_Id and lst.Dictionary_Type_Code = 'LyDoChuyenVien'
		join Lst_Dictionary (nolock)  lst1 on cv.PhuongTien_ID = lst1.Dictionary_Id and lst1.Dictionary_Type_Code = 'PhuongTienVanChuyen'
		join DM_BenhVien (nolock)  BV on cv.BenhVien_Id = BV.BenhVien_Id
		join Lst_Dictionary (nolock)  DanToc on DanToc.Dictionary_Id = DM_BenhNhan.DanToc_id and DanToc.Dictionary_Type_Code = 'DanToc'
		join Lst_Dictionary (nolock)  NgheNghiep on NgheNghiep.Dictionary_Id = DM_BenhNhan.NgheNghiep_id and NgheNghiep.Dictionary_Type_Code = 'NgheNghiep'
		join Lst_Dictionary (nolock)  QuocTich on QuocTich.Dictionary_Id = DM_BenhNhan.QuocTich_id and QuocTich.Dictionary_Type_Code = 'QuocGia'
		join KhamBenh kb (nolock) on kb.TiepNhan_Id = tn.TiepNhan_Id and kb.HuongGiaiQuyet_Id = 458 -- CHUYỂN VIỆN dic_code = 'ChuyenVien'
		join DM_ICD (nolock)  icd on icd.ICD_Id = kb.ChanDoanICD_Id
		join vw_NhanVien (nolock)  bsi on bsi.NhanVien_Id = kb.BacSiKham_Id
-- end bảng 13

-- begin bảng 14
	--DELETE FROM [XML130].[dbo].[TT_14_GIAYHENKHAMLAI] WHERE MA_LK = @Ma_Lk
	INSERT INTO XML130..TT_14_GIAYHENKHAMLAI (
		[MA_LK] ,
	[SO_GIAYHEN_KL] ,
	[MA_CSKCB] ,
	[HO_TEN] ,
	[NGAY_SINH] ,
	[GIOI_TINH] ,
	[DIA_CHI] ,
	[MA_THE_BHYT] ,
	[GT_THE_DEN] ,
	[NGAY_VAO] ,
	[NGAY_VAO_NOI_TRU] ,
	[NGAY_RA],
	[NGAY_HEN_KL] ,
	[CHAN_DOAN_RV] ,
	[MA_BENH_CHINH] ,
	[MA_BENH_KT] ,
	[MA_BENH_YHCT] ,
	[MA_DOITUONG_KCB],
	[MA_BAC_SI] ,
	[MA_TTDV] ,
	[NGAY_CT],
	[DU_PHONG])
	SELECT * FROM (
					SELECT top 1
					MA_LK = @Ma_Lk,            
					SO_GIAYHEN_KL = 'HTK.' + right(tn.SoTiepNhan,12), --2406.0049946
					MA_CSKCB = @MaCSKCB,
					HO_TEN = bn.TenBenhNhan,
					NGAY_SINH =  CASE	WHEN bn.NgaySinh is null THEN convert(VARCHAR, bn.NamSinh) + '01010000'	
										WHEN bn.NgaySinh is not null THEN convert(VARCHAR, bn.NgaySinh, 112) +'0000' end,
					GIOI_TINH = CASE WHEN bn.GioiTinh = 'T' THEN '1'
					   			WHEN bn.GioiTinh = 'G' THEN '2'
								WHEN bn.GioiTinh = 'K' THEN '3'
								END,
					DIA_CHI =  isnull(bn.diachi, TN.noilamviec),
					MA_THE_BHYT = upper(SUBSTRING (tn.SoBHYT, 0, 16)),
					GT_THE_DEN = format(tn.BHYTDenNgay,'yyyyMMdd'),
					NGAY_VAO = format(tn.ThoiGianTiepNhan,'yyyyMMddHHmm'),
                    NGAY_VAO_NOI_TRU = null,
					NGAY_RA = replace(convert(varchar , xn.ThoiGianXacNhan, 112)+convert(varchar(5), xn.ThoiGianXacNhan, 108), ':','')								--	ngay_ra
									,
					NGAY_HEN_KL = format(a.ThoiGianTaiKham,'yyyyMMddHHmm'),
					CHAN_DOAN_RV = isnull(@ChanDoan_NT,@ChanDoan_PK),
					MA_BENH_CHINH = @ICDKB ,
					MA_BENH_KT =  case when  @ICD_PNT='' then @ICD_PK else @ICD_PNT end,
					MA_BENH_YHCT = '' ,
					MA_DOITUONG_KCB = CASE WHEN lst1.Dictionary_Code = '2' and kcbbd.TenBenhVien_En <> @MaCSKCB THEN 2 -- Cap Cuu
											   WHEN (lst1.Dictionary_Code <> '2' or kcbbd.TenBenhVien_En = @MaCSKCB) AND lst.Dictionary_Code = 'TuyenKhamChuaBenh_TrongTuyen' THEN 1 -- Dung Tuyen
											   ELSE 3 END  ,
					MA_BAC_SI = bs.SoChungChiHanhNghe,
                    MA_TTDV = '2096091139',
					NGAY_CT = format(b.ThoiGianKham,'yyyyMMdd'),
					DU_PHONG = null
					from KhamBenh_HenTaiKham a (nolock ) 
						join KhamBenh (nolock )  b on b.KhamBenh_Id = a.KhamBenh_Id
						join Lst_Dictionary gq (nolock) on gq.Dictionary_Id = b.HuongGiaiQuyet_Id 
						join tiepnhan tn on tn.TiepNhan_Id  =b.TiepNhan_Id
						join DM_BenhNhan (nolock )  bn on bn.BenhNhan_Id = tn.BenhNhan_Id
						join DM_ICD  (nolock ) icd on icd.ICD_Id = b.ChanDoanICD_Id
						join vw_NhanVien bs (nolock )  on bs.NhanVien_Id = b.BacSiKham_Id
						join XacNhanChiPhi xn (nolock) on xn.TiepNhan_Id = b.TiepNhan_Id
						left join BenhAn ba (nolock) on ba.TiepNhan_Id = tn.TiepNhan_Id 
						left join Lst_Dictionary LST1 (nolock) on LST1.Dictionary_Id = TN.LyDoTiepNhan_Id
						left join DM_BenhVien kcbbd (nolock)on tn.BenhVien_KCB_id = kcbbd.BenhVien_Id
						LEFT JOIN	dbo.Lst_Dictionary lst ON lst.Dictionary_Id = tn.TuyenKhamBenh_Id
					where b.TiepNhan_Id = @TiepNhan_Id
							and gq.Dictionary_Code = 'HenTaiKham'
							and ba.BenhAn_Id is null

	union all
			SELECT top 1
					MA_LK = @Ma_Lk,            
					SO_GIAYHEN_KL = 'HTK.' + right(tn.SoTiepNhan,12), --2406.0049946
					MA_CSKCB = @MaCSKCB,
					HO_TEN = bn.TenBenhNhan,
					NGAY_SINH =  CASE	WHEN bn.NgaySinh is null THEN convert(VARCHAR, bn.NamSinh) + '01010000'	
										WHEN bn.NgaySinh is not null THEN convert(VARCHAR, bn.NgaySinh, 112) +'0000' end,
					GIOI_TINH = CASE WHEN bn.GioiTinh = 'T' THEN 1 WHEN bn.GioiTinh = 'G' THEN 2 END,
					DIA_CHI =  isnull(bn.diachi, TN.noilamviec),
					MA_THE_BHYT = RTRIM(LTRIM(ISNULL((SELECT SoBH 
													FROM (SELECT TOP 1 UPPER(ISNULL(SUBSTRING (RTRIM(LTRIM(Attribute1)), 0, 16), '')) + ';'				
															FROM TiepNhan_DoiTuongThayDoi
															WHERE TiepNhan_Id = @TiepNhan_Id And ISNULL(Attribute1,'') <> '' and IS2The=1
															ORDER BY TiepNhan_DoiTuongThayDoi_Id DESC
															FOR XML PATH('')
														 ) BH(SoBH)), '')
									)) + UPPER(ISNULL(SUBSTRING (RTRIM(LTRIM(TN.SoBHYT)), 0, 16), '')) ,
					GT_THE_DEN = RTRIM(LTRIM(ISNULL((SELECT DenNgay 
													FROM (SELECT top 1 convert(VARCHAR, Attribute6, 112) + ';'				
															FROM TiepNhan_DoiTuongThayDoi
															WHERE TiepNhan_Id = tn.TiepNhan_Id And ISNULL(Attribute6,'') <> '' and IS2The=1
															ORDER BY TiepNhan_DoiTuongThayDoi_Id DESC
															FOR XML PATH('')
														 ) BH(DenNgay)), '')
									)) + convert(VARCHAR, tn.BHYTDenNgay, 112),
					NGAY_VAO = replace(convert(varchar , ba.ThoiGianVaoVien, 112)+convert(varchar(5), ba.ThoiGianVaoVien, 108), ':',''),--format(tn.ThoiGianTiepNhan,'yyyyMMddHHmm'),
                    NGAY_VAO_NOI_TRU = replace(convert(varchar , ba.ThoiGianVaoVien, 112)+convert(varchar(5), ba.ThoiGianVaoVien, 108), ':',''),
					NGAY_RA = format(ba.ThoiGianRaVien,'yyyyMMddHHmm'),
					NGAY_HEN_KL = format(ba.NgayHenTaiKham,'yyyyMMddHHmm'),
					CHAN_DOAN_RV = isnull(@ChanDoan_NT,@ChanDoan_PK),
					MA_BENH_CHINH =  isnull(@ICD_NT,@ICDKB),
					MA_BENH_KT = case when  @ICD_PNT='' then @ICD_PK else @ICD_PNT end,
					MA_BENH_YHCT = '' ,
					MA_DOITUONG_KCB = CASE WHEN lst.Dictionary_Code = '2' and bv.TenBenhVien_En <> @MaCSKCB THEN 2 -- Cap Cuu
								   WHEN (lst.Dictionary_Code <> '2' Or  bv.TenBenhVien_En = @MaCSKCB) AND TuyenKB.Dictionary_Code = 'TuyenKhamChuaBenh_TrongTuyen' THEN 1 -- Dung Tuyen
								   ELSE 3 END , -- Trai Tuyen,
					MA_BAC_SI = bs.SoChungChiHanhNghe,
                    MA_TTDV = '2096091139',
					NGAY_CT = format(ba.ThoiGianRaVien,'yyyyMMdd'),
					DU_PHONG = null
					from BenhAn ba ( nolock)
						join tiepnhan tn on tn.TiepNhan_Id  =ba.TiepNhan_Id
						join DM_BenhNhan (nolock )  bn on bn.BenhNhan_Id = tn.BenhNhan_Id
						join DM_ICD  (nolock ) icd on icd.ICD_Id = ba.ICD_BenhChinh
						join vw_NhanVien bs (nolock )  on bs.NhanVien_Id = isnull(ba.BacSiDieuTriChinh_Id,ba.BacSiDieuTri_Id)
							join Lst_Dictionary (nolock ) lba on lba.Dictionary_Id = ba.LoaiBenhAn_Id
						Left join Lst_Dictionary TuyenKB (nolock) on TuyenKB.Dictionary_Id = TN.TuyenKhamBenh_ID
							left join Lst_Dictionary LST (nolock) on LST.Dictionary_Id = TN.LyDoTiepNhan_Id
						left join DM_Benhvien BV (nolock) on TN.BenhVien_KCB_Id = BV.BenhVien_Id
					
					where ba.TiepNhan_Id = @TiepNhan_Id
					and ba.NgayHenTaiKham is not null
					and lba.Attribute2 = 'BANT'

		)XML14

-- end bảng 14


end



INSERT INTO GUIDULIEU_XML130_LOG VALUES(NULL, @TiepNhan_Id, 'SUCCESS', NULL, NULL, NULL, NULL, getdate())
UPDATE XacNhanChiPhi SET Send130 = 1  WHERE TiepNhan_Id = @TiepNhan_Id
COMMIT TRANSACTION

END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION
	DECLARE @ERROR_NUMBER AS INT;
	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
	DECLARE @ErrorLine INT;

    SELECT
		@ERROR_NUMBER = ERROR_NUMBER(),
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE(),
		@ErrorLine = ERROR_LINE();

	INSERT INTO GUIDULIEU_XML130_LOG VALUES(NULL, @TiepNhan_Id, 'ERROR', @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine, getdate())
END CATCH
END


select top 2 * from GUIDULIEU_XML130_LOG where TiepNhan_Id = @TiepNhan_Id order by NgayTao desc
select * from XML130..TT_01_TONGHOP where MA_LK = @Ma_Lk
select * from XML130..TT_02_THUOC where MA_LK = @Ma_Lk
select * from XML130..TT_03_DVKT_VTYT where MA_LK = @Ma_Lk
select * from XML130..TT_04_CLS where MA_LK = @Ma_Lk
select * from XML130..TT_05_LAMSANG where MA_LK = @Ma_Lk

select * from XML130..TT_07_GIAY_RAVIEN where MA_LK = @Ma_Lk
select * from  XML130..TT_13_GIAYCHUYENTUYEN  Where MA_LK = @Ma_Lk
select * from  XML130..TT_14_GIAYHENKHAMLAI  Where MA_LK = @Ma_Lk



-- SELECT * FROM TiepNhan WHERE SoTiepNhan = 'TN.2406.0049363' --1500123