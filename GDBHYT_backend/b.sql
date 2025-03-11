USE [eHospital_ThuyDienUB]
GO
/****** Object:  StoredProcedure [dbo].[sp_XuatXML_BangKe01_130]    Script Date: 03/04/2025 3:48:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

BEGIN

declare @TiepNhan_Id int = null 
declare	@BenhAn_Id int = null

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
end
end try
begin catch
end catch
commit transaction
end