*******************************************************
* FILE NAME : KHOẢNG TRỐNG TÍN DỤNG NHÀ Ở (MISSING MIDDLE)
* PROJECT   : Housing Credit Constraint & Welfare
* DATA      : VHLSS 2024
* Author    : Truong Nhat Duy
*******************************************************
clear all
set more off
capture log close
*======================================================*
* Đặt thư mục làm việc 
local workdir `c(pwd)'
cd "`workdir'"
* Khai báo đường dẫn lưu ảnh:
local export_path "D:\01. HOC HANH\13. THAC SI UEH\08. ĐĂNG KÝ ĐỀ TÀI LUẬN VĂN TỐT NGHIỆP THẠC SĨ\Khoảng trống chính sách tín dụng nhà ở cho người thu nhập thấp\01. de cuong & bai viet\figures"
* biểu đồ có nền trắng chuẩn học thuật:
set scheme s2color 
*======================================================*
log using "Heckman_MissingMiddle_2024.log", replace text
*======================================================*
* STEP 1 : TẠO CÁC FILE VỆ TINH (SẴN SÀNG ĐỂ MERGE)
*======================================================*
display ">>> 1. Xu ly cac file thanh phan"
*======================================================*
* 1.1. Lấy thông tin CHỦ HỘ
use "Ho_ThanhVien.dta", clear
rename *, lower
keep if m1a_c3 == 1  
gen informal = (m4a_c10 == 2 | m4a_c11 == 2)
gen fintech_user = (m6b_c1 == 1 | m6b_c3 == 1)
rename m1a_c5 age_head
* ==========================================
* TẠO BIẾN SỐ NĂM ĐI HỌC (YEARS OF SCHOOLING)
* ==========================================
* 1. Khởi tạo từ số lớp phổ thông thực tế (từ lớp 1 đến lớp 12)
gen edu_head = m2_c1 if m2_c1 >= 1 & m2_c1 <= 12
* 2. Xử lý nhóm Mầm non (0) và Chưa bao giờ đi học (99)
replace edu_head = 0 if m2_c1 == 0 | m2_c1 == 99
* 3. Bổ sung số năm cho nhóm có Bằng cấp Nghề nghiệp (Dựa vào m2_c2b)
* Giả định chuẩn: Sơ cấp (+1), Trung cấp (+2), Cao đẳng (+3) sau THPT
replace edu_head = 13 if m2_c2b == 4  // Sơ cấp / Giấy phép lái xe ô tô
replace edu_head = 14 if m2_c2b == 5  // Trung cấp
replace edu_head = 15 if m2_c2b == 6  // Cao đẳng
* 4. Bổ sung số năm cho nhóm Đại học trở lên (Dựa vào m2_c2a)
replace edu_head = 15 if m2_c2a == 6  // Cao đẳng (TH khai nhầm sang cột a)
replace edu_head = 16 if m2_c2a == 7  // Đại học
replace edu_head = 18 if m2_c2a == 8  // Thạc sĩ
replace edu_head = 21 if m2_c2a == 9  // Tiến sĩ
* 5. Kiểm tra lại phân phối của biến mới tạo
tab edu_head, missing
sum edu_head, detail
* ==========================================
keep idho informal fintech_user age_head edu_head
sort idho
save "Temp_Head.dta", replace
*======================================================*
* 1.2. Biến IV: Vốn xã hội (Mục 5B3)
use "Ho_Muc5B3.dta", clear
rename *, lower
tostring m5b3_ma, replace // Ép kiểu chuỗi để tránh lỗi numeric/string
gen social_network = 1 if m5b3_ma == "401" & m5b3_c2 > 0
collapse (max) social_network, by(idho)
sort idho
save "Temp_IV_Social.dta", replace
*======================================================*
* 1.3. Biến IV: Tiếp cận thông tin (Mục 6A2)
use "Ho_Muc6A2.dta", clear
rename *, lower
tostring m6a_ma, replace
gen info_access = 1 if m6a_ma == "16" & m6a_c3 > 0
collapse (max) info_access, by(idho)
sort idho
save "Temp_IV_Info.dta", replace
*======================================================*
* 1.4. Nhóm Tín dụng Kinh doanh (Mục 4C)
use "ho_muc4c.dta", clear
rename *, lower
gen vay_kinhdoanh = (m4c_c24 > 0 & m4c_c24 != .)
sort idho
collapse (max) vay_kinhdoanh (sum) tong_vay=m4c_c24 (count) so_khoan=m4c_c24 (mean) ky, by(idho)
*======================================================*
* 1.4. Nhóm Tín dụng Kinh doanh (Mục 4C)
use "ho_muc4c.dta", clear
rename *, lower
*======================================================*
* Tạo biến vay kinh doanh
gen vay_kinhdoanh = (m4c_c24 > 0 & m4c_c24 != .)
*======================================================*
* Gom gộp về cấp hộ
collapse (max) vay_kinhdoanh ///
         (sum) tong_vay=m4c_c24 ///
         (count) so_khoan=m4c_c24 ///
         (mean) ky, by(idho)
*======================================================*
* Chuẩn hóa idho về str17
destring idho, replace force
tostring idho, replace format(%017.0f)
*======================================================*
* Kiểm tra dữ liệu
duplicates report idho
tab vay_kinhdoanh
summarize tong_vay so_khoan ky
*======================================================*
* Chuẩn hóa idho về str17
*======================================================*
save "Temp_Vay_KinhDoanh.dta", replace
*======================================================*
* 1.5. Nhóm Tín dụng Tiêu dùng (Mục 5B3)
use "Ho_Muc5B3.dta", clear
rename *, lower
tostring m5b3_ma, replace
*======================================================*
gen vay_tieudung = 1 if (m5b3_ma == "402" | m5b3_ma == "403") & m5b3_c2 > 0
collapse (max) vay_tieudung, by(idho)
sort idho
save "Temp_Vay_TieuDung.dta", replace
*======================================================*
* 1.6. Xử lý file Trọng số
use "weight2024_ver2.dta", clear
rename *, lower
tostring tinh huyen xa diaban, replace format(%02.0f)
gen matinh = substr("00" + tinh, -2, 2)
gen mahuyen = substr("000" + huyen, -3, 3)
gen maxa = substr("00000" + xa, -5, 5)
keep matinh mahuyen maxa diaban wt45
sort matinh mahuyen maxa diaban
save "Temp_Weights.dta", replace

*======================================================*
* STEP 2 : MERGE MASTER DATA (GỘP 1 LẦN DUY NHẤT)
*======================================================*
display ">>> 2. Gop du lieu vao file Master..."

use "Ho_ThongTinHo.dta", clear
rename *, lower
*======================================================*
* Chuẩn hóa mã định danh để merge trọng số
tostring tinh huyen xa diaban, replace format(%02.0f)
gen matinh = substr("00" + tinh, -2, 2)
gen mahuyen = substr("000" + huyen, -3, 3)
gen maxa = substr("00000" + xa, -5, 5)
*======================================================*
* Merge 1:1 các file vệ tinh
merge 1:1 idho using "Temp_Head.dta", keep(master match)
drop _merge
*======================================================*
merge 1:1 idho using "Temp_IV_Social.dta", keep(master match) 
drop _merge
replace social_network = 0 if missing(social_network)
*======================================================*
merge 1:1 idho using "Temp_IV_Info.dta", keep(master match) 
drop _merge
replace info_access = 0 if missing(info_access)
*======================================================*
merge 1:1 idho using "Temp_Vay_KinhDoanh.dta", keep(master match)
drop _merge
replace vay_kinhdoanh = 0 if missing(vay_kinhdoanh)
*======================================================*
merge 1:1 idho using "Temp_Vay_TieuDung.dta", keep(master match) 
drop _merge
replace vay_tieudung = 0 if missing(vay_tieudung)
*======================================================*
save "Ho_Master_NoWeights.dta", replace
*======================================================*
* Merge m:1 trọng số
use "Temp_Weights.dta", clear
rename *, lower
tostring tinh huyen xa diaban, replace format(%02.0f)
save "Temp_Weights_clean.dta", replace
*======================================================*
use "Ho_Master_NoWeights.dta", clear
merge m:1 tinh huyen xa diaban using "Temp_Weights_clean.dta", keep(master match)
tab _merge
drop _merge
save "Ho_Master_Merged.dta", replace
*======================================================*
* Xóa file tạm:
erase "Temp_Head.dta"
erase "Temp_IV_Social.dta"
erase "Temp_IV_Info.dta"
erase "Temp_Vay_KinhDoanh.dta"
erase "Temp_Vay_TieuDung.dta"
erase "Temp_Weights.dta"
*======================================================*
* STEP  : KIỂM TRA BIẾN TRƯỚC PHÂN TÍCH
*======================================================*

display ">>> 3. Kiem tra outlier va missing..."
*======================================================*
* 1. Kiểm tra chi tiết phân phối biến liên tục
summarize tongthu tongchi thunhap thubq tongchitieu tongchitieubq, detail
summarize age_head edu_head tong_vay so_khoan ky wt45, detail
*======================================================*
* 2. Kiểm tra missing trong toàn bộ file
misstable summarize
*======================================================*
* 3. Kiểm tra phân phối trọng số
summarize wt45, detail
histogram wt45, bin(50) normal
*======================================================*
* 4. Kiểm tra phân phối thu nhập và chi tiêu
histogram thunhap, bin(50) normal
histogram tongchi, bin(50) normal
histogram tongthu, bin(50) normal
*======================================================*
* 5. Kiểm tra biến giáo dục (edu_head) để xử lý mã missing
tab edu_head, missing
*======================================================*
* STEP 3 : TẠO BIẾN CHO MÔ HÌNH HECKMAN
*======================================================*
display ">>> 3. Tao bien mo hinh (Khong bi ngat quang)..."
*======================================================*
* 3.1. Lọc mẫu Đô thị & Phân nhóm Missing Middle
keep if ttnt == 1
*======================================================*
gen income_pc = thunhap / tsnguoi
xtile quintile = income_pc [pw=wt45], nq(5)
keep if quintile <= 3  
*======================================================*
* 3.2. Biến Outcome: Gánh nặng nhà ở
gen housing_burden = (m7_c20 / thunhap) * 100
replace housing_burden = . if housing_burden > 100 | housing_burden < 0
*======================================================*
* 3.3. Các biến kiểm soát
gen ln_income = ln(income_pc + 1)
gen collateral = (m7_c3 == 1)
capture replace vay_tieudung = 1 if m7_c3 == 3 // Mua trả góp
*======================================================*
* 3.4. Xây dựng Cấu trúc Tín dụng (Credit Typology):
gen vay_moi = 0
capture replace vay_moi = 1 if m4d_03 > 0 & m4d_03 != .
capture replace vay_moi = 1 if m4d_04 > 0 & m4d_04 != .
*======================================================*
gen count_loai_vay = vay_kinhdoanh + vay_tieudung + vay_moi
*======================================================*
gen credit_type = 0
replace credit_type = 1 if vay_kinhdoanh == 1 & count_loai_vay == 1
replace credit_type = 2 if vay_tieudung == 1 & count_loai_vay == 1
replace credit_type = 3 if vay_moi == 1 & count_loai_vay == 1
replace credit_type = 4 if count_loai_vay >= 2
*======================================================*
label define lbl_credittype 0 "Khong vay" 1 "Vay Kinh doanh" 2 "Vay Tieu dung/Nha o" 3 "Vay Moi" 4 "Hon hop"
label values credit_type lbl_credittype
*======================================================*
* BIẾN TÍN DỤNG CHÍNH (Y1)
gen credit_access = (credit_type > 0)
label var credit_access "Có tiếp cận tín dụng"
*======================================================*
* 3.5. Biến IV đa kênh (Tivi + Internet/MXH)
gen info_broad = 0
replace info_broad = 1 if (info_access == 1 | fintech_user == 1)
*======================================================*
* 3.6. Biến IV Peer Effect (Chỉ tính khi credit_access ĐÃ HOÀN THIỆN)
bysort matinh mahuyen maxa diaban: egen total_borrowers = total(credit_access)
bysort matinh mahuyen maxa diaban: egen total_hh = count(idho)
gen peer_effect = (total_borrowers - credit_access) / (total_hh - 1)
replace peer_effect = 0 if total_hh <= 1

*======================================================*
* Kiểm tra phân phối quintile
tab quintile
*======================================================*
* Kiểm tra outcome housing_burden
summarize housing_burden, detail
histogram housing_burden, bin(50) normal
*======================================================*
* Kiểm tra credit_type
tab credit_type, missing
*======================================================*
* Kiểm tra credit_access
tab credit_access
*======================================================*
* Kiểm tra info_broad và peer_effect
tab info_broad
summarize peer_effect, detail
*======================================================*
label var housing_burden "Gánh nặng nhà ở (% thu nhập)"
label var credit_access "Có tiếp cận tín dụng"
label var ln_income "Log thu nhập bình quân"
label var peer_effect "Peer effect (tỷ lệ vay trong địa bàn)"
*======================================================*
save "Ho_Heckman_Model.dta", replace
*======================================================*
* XỬ LÝ LÀM SẠCH DATA (TT)
*======================================================*
*======================================================*
* xử lý biến số năm giáo dục:
*======================================================*
* 1. Mở file chính
use "Ho_Heckman_Model.dta", clear
* 2. Ghép dữ liệu và TỰ ĐỘNG CẬP NHẬT giá trị mới cho edu_head
* Lệnh update replace sẽ ghi đè giá trị edu_head từ file Temp_Head sang file chính
merge 1:1 idho using "Temp_Head.dta", update replace
* 3. Kiểm tra kết quả merge
tab _merge
* 4. Xóa biến _merge để dọn dẹp dữ liệu
keep if _merge == 3 | _merge == 4 | _merge == 5
* Hoặc đơn giản hơn (vì bạn chỉ muốn giữ dữ liệu gốc):
keep if _merge >= 3 
drop _merge
* 5. Kiểm tra lại phân phối (Lúc này edu_head sẽ có nhiều giá trị khác nhau, không chỉ có số 9)
tab edu_head, m
summarize edu_head, detail
* 6. Chạy lại mô hình của bạn
regress credit_access ln_income informal collateral edu_head age_head
* 7. Lưu file đã cập nhật
save "Ho_Heckman_Model_updated.dta", replace

*======================================================*
* STEP 4 : CHẠY MÔ HÌNH HECKMAN CHÍNH (FIML)
*======================================================*
display ">>> 4. Dang chay mo hinh Heckman (Full Model)..."
use "Ho_Heckman_Model_updated.dta", clear
svyset diaban [pw=wt45]

* Chạy mô hình Heckman với tùy chọn pweight:
heckman housing_burden ln_income tsnguoi collateral [pw=wt45], ///
    select(credit_access = ln_income informal collateral edu_head age_head peer_effect social_network info_broad) ///
    vce(robust)

est store HECKMAN_MAIN

* CHẠY MÔ HÌNH ENDOGENOUS TREATMENT EFFECTS:
etregress housing_burden ln_income tsnguoi collateral [pw=wt45], ///
    treat(credit_access = ln_income informal collateral edu_head age_head peer_effect social_network) ///
    vce(robust)
	
*======================================================*
* CHẠY CÁC TEST kiểm định
*======================================================*	
*======================================================*
* KIỂM TRA MA TRẬN TƯƠNG QUAN VÀ ĐA CỘNG TUYẾN
*======================================================*
* 1. Chạy ma trận tương quan
pwcorr housing_burden credit_access ln_income tsnguoi collateral edu_head age_head peer_effect social_network, star(0.05) sig
*======================================================*
* ---> XUẤT MA TRẬN TƯƠNG QUAN RA LATEX
quietly estpost correlate housing_burden credit_access ln_income tsnguoi collateral edu_head age_head peer_effect social_network, matrix
esttab using "appendix_correlation.tex", replace ///
    unstack not noobs compress ///
    title("Ma trận tương quan Pearson") ///
    b(3) star(* 0.10 ** 0.05 *** 0.01) ///
    booktabs alignment(c)
*======================================================*	
* 2. Kiểm tra Đa cộng tuyến (VIF)
* chạy hồi quy tuyến tính (regres):
qui regress housing_burden credit_access ln_income tsnguoi collateral edu_head age_head peer_effect social_network
* Hiển thị bảng VIF:
vif	

*======================================================*
* STEP 5 — CHẠY KIỂM TRA ĐỘ VỮNG (ROBUSTNESS CHECKS):
*======================================================*
display ">>> 5. Dang chay cac mo hinh so sanh (Robustness Check)..."
*======================================================*
heckman housing_burden ln_income tsnguoi collateral [pw=wt45], ///
    select(credit_access = ln_income informal collateral edu_head age_head peer_effect) vce(robust)
est store Model_1
*======================================================*
heckman housing_burden ln_income tsnguoi collateral [pw=wt45], ///
    select(credit_access = ln_income informal collateral edu_head age_head social_network) vce(robust)
est store Model_2
*======================================================*
heckman housing_burden ln_income tsnguoi collateral [pw=wt45], ///
    select(credit_access = ln_income informal collateral edu_head age_head info_broad) vce(robust)
est store Model_3
*======================================================*
* Tính Wald Test cho Full Model (HECKMAN_MAIN)
* Chạy lại mô hình Full (Model_4)
qui heckman housing_burden ln_income tsnguoi collateral [pw=wt45], ///
    select(credit_access = ln_income informal collateral edu_head age_head peer_effect social_network info_broad) vce(robust)
* Chạy kiểm định Wald (Joint test) cho 3 biến công cụ
test [credit_access]peer_effect [credit_access]social_network [credit_access]info_broad

*======================================================*
* STEP 6 : CHẠY KIỂM TRA ĐỘ VỮNG BẰNG ETREGRESS
*======================================================*
display ">>> 5. Dang chay cac mo hinh so sanh (Robustness Check)..."

* Model 1: Chỉ dùng Peer Effect làm IV
eststo Model_1: etregress housing_burden ln_income tsnguoi collateral [pw=wt45], ///
    treat(credit_access = ln_income informal collateral edu_head age_head peer_effect) vce(robust)
*======================================================*
* Model 2: Dùng Peer Effect và Social Network làm IV (Model chính)
eststo Model_2: etregress housing_burden ln_income tsnguoi collateral [pw=wt45], ///
    treat(credit_access = ln_income informal collateral edu_head age_head peer_effect social_network) vce(robust)
*======================================================*
* Model 3: Loại bỏ informal, thêm biến tương tác tuổi và học vấn (để test biến kiểm soát)
eststo Model_3: etregress housing_burden ln_income tsnguoi collateral [pw=wt45], ///
    treat(credit_access = ln_income collateral edu_head age_head c.edu_head#c.age_head peer_effect social_network) vce(robust)

*======================================================*
* KIỂM ĐỊNH CHẨN ĐOÁN BIẾN CÔNG CỤ:
*======================================================*

* 1. First-stage F-statistic (Kiểm định sức mạnh biến công cụ)
ivregress 2sls housing_burden (credit_access = peer_effect social_network) ///
    ln_income tsnguoi collateral, vce(robust)
estat firststage
*======================================================*
* 2. Over-identification Test (Sargan-Hansen)
estat overid
*======================================================*
* 3. Falsification Test (Exclusion restriction)
regress housing_burden peer_effect social_network if credit_access==0
*======================================================*
* 4. Kiểm định Hausman / Durbin-Wu-Hausman
estat endogenous
estat endogenous, durbin

*======================================================*
* THAY ĐỔI THƯỚC ĐO VÀ HỒI QUY PHÂN VỊ
*======================================================*

* 1. Giới hạn biến phụ thuộc (Capping)
* Giới hạn gánh nặng nhà ở tối đa 100%
gen housing_burden_cap = housing_burden
replace housing_burden_cap = 100 if housing_burden_cap > 100
*======================================================*
* 2. Hồi quy phân vị (Quantile Regression)
* Ước lượng tại các phân vị 25th, 50th, 75th
qreg housing_burden_cap ln_income tsnguoi collateral credit_access, quantile(0.25)
qreg housing_burden_cap ln_income tsnguoi collateral credit_access, quantile(0.50)
qreg housing_burden_cap ln_income tsnguoi collateral credit_access, quantile(0.75)

*======================================================*
* STEP 7 — XUẤT BẢNG KẾT QUẢ
*======================================================*
display ">>> 6. XUẤT BẢNG KẾT QUẢ"

* Xuất bảng so sánh
esttab Model_1 Model_2 Model_3, b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(1.credit_access ln_income tsnguoi collateral) ///
    title("Bang: Kiem tra do vung cua mo hinh Endogenous Treatment") mtitle("Model 1" "Model 2" "Model 3")
*======================================================*
capture esttab Model_1 Model_2 Model_3 Model_4 using "Heckman_Robustness_Table.rtf", ///
    replace wide align(c) ///
    b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
    title("Bang 1: Ket qua uoc luong Heckman FIML voi cac bien cong cu") ///
    mtitles("Chi Peer Effect" "Chi Social Net" "Chi Info Broad" "Full Model") ///
    keep(housing_burden:ln_income housing_burden:tsnguoi housing_burden:collateral ///
         select:ln_income select:informal select:peer_effect select:social_network select:info_broad) ///
    order(housing_burden:ln_income housing_burden:tsnguoi housing_burden:collateral ///
          select:ln_income select:informal select:peer_effect select:social_network select:info_broad) ///
    scalars("rho He so rho" "wald_chi2 Thong ke Wald (Chi2)" "wald_p P-value Wald test") ///
    addnotes("Sai so chuan manh (Robust SE) trong ngoac. Co su dung trong so khao sat (wt45).")

* ----------------------------------------------------------------------
* ĐỒ THỊ: 
* ----------------------------------------------------------------------

* ----------------------------------------------------------------------
* ĐỒ THỊ 1: Boxplot So sánh gánh nặng nhà ở giữa 2 nhóm Vay và Không Vay
* ----------------------------------------------------------------------
graph box housing_burden, over(credit_access) ///
    title("Đồ thị 1: Phân phối Gánh nặng chi phí nhà ở" ///
          "theo Tình trạng tiếp cận tín dụng", size(medsmall)) ///
    ytitle("Tỷ lệ chi phí nhà ở / Thu nhập (%)") ///
    note("Nguồn: Tính toán của tác giả từ VHLSS 2024")
*======================================================*
graph export "`export_path'\fig1_boxplot_burden.png", as(png) replace

* ----------------------------------------------------------------------
* ĐỒ THỊ 2: Scatter plot và Trendline giữa Thu nhập và Gánh nặng nhà ở
* ----------------------------------------------------------------------

twoway (scatter housing_burden ln_income, mcolor(navy%30) msize(small)) ///
       (lfit housing_burden ln_income, lcolor(red) lwidth(medthick)), ///
    title("Đồ thị 2: Mối liên hệ giữa Thu nhập cốt lõi" ///
          "và Gánh nặng chi phí nhà ở", size(medsmall)) ///
    xtitle("Logarit tự nhiên của Thu nhập (ln_income)") ///
    ytitle("Tỷ lệ chi phí nhà ở / Thu nhập (%)") ///
    legend(order(1 "Quan sát thực tế" 2 "Đường xu hướng tuyến tính")) ///
    note("Nguồn: Tính toán của tác giả từ VHLSS 2024")
*======================================================*
graph export "`export_path'\fig2_scatter_income.png", as(png) replace

* ----------------------------------------------------------------------
* ĐỒ THỊ 3: Bar chart thể hiện "Bẫy tài sản" (Gộp 4 nhóm)
* ----------------------------------------------------------------------

graph bar (mean) housing_burden, over(collateral) over(credit_access) ///
    title("Đồ thị 3: Trung bình Gánh nặng nhà ở" ///
          "theo Tình trạng sở hữu tài sản và Tín dụng", size(medsmall)) ///
    ytitle("Trung bình tỷ lệ chi phí nhà ở / Thu nhập (%)") ///
    b1title("Tình trạng sở hữu tài sản (0 = Thuê, 1 = Sở hữu)") ///
    blabel(bar, format(%9.1f)) ///
    note("Nguồn: Tính toán của tác giả từ VHLSS 2024")
*======================================================*
graph export "`export_path'\fig3_bar_asset_trap.png", as(png) replace

* ----------------------------------------------------------------------
* ĐỒ THỊ 4: Kernel density của Housing Burden (Phân phối cực đoan)
* ----------------------------------------------------------------------
kdensity housing_burden, recast(area) fcolor(navy%30) lcolor(navy) lwidth(medthick) ///
    title("Đồ thị 4: Phân phối Mật độ Gánh nặng chi phí nhà ở", size(medsmall)) ///
    xtitle("Tỷ lệ chi phí nhà ở / Thu nhập (%)") ///
    ytitle("Mật độ (Density)") ///
    xline(30, lcolor(red) lpattern(dash)) ///
    note("Nguồn: Tính toán của tác giả từ VHLSS 2024. Đường đứt nét đỏ = ngưỡng gánh nặng 30%.")
*======================================================*
graph export "`export_path'\fig4_density_burden.png", as(png) replace

* ----------------------------------------------------------------------
* ĐỒ THỊ 5: Bar chart theo Credit Type (Cơ cấu dòng vốn)
* ----------------------------------------------------------------------
graph bar (count), over(credit_type, label(angle(45) labsize(small))) ///
    title("Đồ thị 5: Cơ cấu mục đích sử dụng vốn vay" ///
          "trong nhóm Missing Middle", size(medsmall)) ///
    ytitle("Số lượng hộ gia đình") ///
    blabel(bar, format(%9.0f) size(small)) ///
    bar(1, color(teal)) ///
    note("Nguồn: Tính toán của tác giả từ VHLSS 2024")
*======================================================*
graph export "`export_path'\fig5_bar_credit_type.png", as(png) replace

* ----------------------------------------------------------------------
* ĐỒ THỊ 6: Line chart Peer Effect theo địa bàn
* ----------------------------------------------------------------------
preserve
collapse (mean) peer_effect, by(diaban)
*======================================================*
* Tạo biến số thứ tự cho địa bàn
encode diaban, gen(diaban_num)
*======================================================*
sort diaban_num
twoway (line peer_effect diaban_num, lcolor(blue) lwidth(medthick) msymbol(circle)), ///
    title("Đồ thị 6: Sự phân hóa của Hiệu ứng đồng trang lứa (Peer Effect)" ///
          "theo các địa bàn khảo sát", size(medsmall)) ///
    xtitle("Khu vực / Địa bàn") ///
    ytitle("Mức độ Peer Effect trung bình") ///
    xlabel(, valuelabel angle(45) labsize(small)) ///
    note("Nguồn: Tính toán của tác giả từ VHLSS 2024")
*======================================================*
graph export "`export_path'\fig6_line_peer_effect.png", as(png) replace
restore
* ----------------------------------------------------------------------
* ĐỒ THỊ 7: Interaction plot (Gánh nặng nhà ở theo Thu nhập và Tín dụng)
* ----------------------------------------------------------------------
graph bar (mean) housing_burden, over(quintile) over(credit_access) ///
    title("Đồ thị 7: Gánh nặng nhà ở phân hóa theo" ///
          "Phân vị thu nhập và Tình trạng tín dụng", size(medsmall)) ///
    ytitle("Trung bình tỷ lệ chi phí nhà ở / Thu nhập (%)") ///
    blabel(bar, format(%9.1f) size(small)) ///
    legend(label(1 "Không vay") label(2 "Có vay")) ///
    note("Nguồn: Tính toán của tác giả từ VHLSS 2024")
*======================================================*
graph export "`export_path'\fig7_bar_quintile_credit.png", as(png) replace

*====================================================
* PHẦN THỐNG KÊ MÔ TẢ CÁC BIẾN TRONG MÔ HÌNH:
*====================================================

* 1. Thống kê mô tả cơ bản
summarize housing_burden credit_access ln_income social_network ///
          age_head tsnguoi edu_head
*======================================================*
* 2. Thống kê chi tiết (có median, percentiles)
summarize housing_burden credit_access ln_income social_network ///
          age_head tsnguoi edu_head, detail
*======================================================*
* 3. Thống kê mô tả theo bảng (mean, sd, min, max)
tabstat housing_burden credit_access ln_income social_network ///
        age_head tsnguoi edu_head, statistics(count mean sd min max) columns(statistics)

*====================================================
* 4. Xuất bảng sang LaTeX bằng estout (chèn vào luận văn)
*====================================================
ssc install estout, replace   // cài đặt nếu chưa có
*======================================================*
estpost summarize housing_burden credit_access ln_income social_network ///
    age_head tsnguoi edu_head, detail
*======================================================*
esttab using "appendix_desc_stats.tex", ///
    cells("count mean sd min max") ///
    label replace ///
    title("Thống kê mô tả các biến trong mô hình") ///
    alignment(l c c c c c) ///
    booktabs ///
    varlabels(housing_burden "Gánh nặng nhà ở (Tỷ lệ chi phí/Thu nhập)" ///
              credit_access "Tiếp cận tín dụng (1=Có,0=Không)" ///
              ln_income "Thu nhập hộ gia đình (log)" ///
              social_network "Tham gia mạng lưới xã hội (1=Có, 0=Không)" ///
              age_head "Tuổi chủ hộ (Năm)" ///
              tsnguoi "Số nhân khẩu (Người)" ///
              edu_head "Học vấn chủ hộ (Số năm đi học)")
/* =====================================================
   ADVANCE Q1 - HETEROGENEITY, MECHANISM, & SPATIAL
   Data: Ho_Heckman_Model_updated.dta
   ===================================================== */

clear all
set more off
capture ssc install winsor2, replace

use "Ho_Heckman_Model_updated.dta", clear
eststo clear

* 1. KHAI BÁO GLOBAL PATH ĐỂ DÙNG XUYÊN SUỐT (Sửa lại đường dẫn của bạn nếu cần)
global path "D:\01. HOC HANH\13. THAC SI UEH\08. ĐĂNG KÝ ĐỀ TÀI LUẬN VĂN TỐT NGHIỆP THẠC SĨ\Khoảng trống chính sách tín dụng nhà ở cho người thu nhập thấp\01. de cuong & bai viet"

display "=== ADVANCE Q1 - ĐÃ FIX TOÀN BỘ LỖI & THÊM ĐỒ THỊ HN - HCM ==="

/* Phục hồi lại Model Main để làm gốc so sánh */
eststo Main: etregress housing_burden ln_income tsnguoi collateral edu_head age_head informal ///
    [pw=wt45], treat(credit_access = ln_income collateral informal edu_head age_head peer_effect social_network) vce(robust)

/* ====================== 1. HETEROGENEITY ANALYSIS ====================== */
display "--- 1. Heterogeneity by Income Quintile ---"
eststo Het_Q: etregress housing_burden i.credit_access##i.quintile ln_income tsnguoi collateral edu_head age_head informal ///
    [pw=wt45], treat(credit_access = ln_income collateral informal edu_head age_head peer_effect social_network) ///
    vce(robust) iterate(500)

margins, dydx(credit_access) at(quintile=(1 2 3))
marginsplot, title("Fig 8: Marginal Effect of Credit Access by Income Quintile") ///
    ytitle("Average Marginal Effect on Housing Burden (%)") ///
    xtitle("Income Quintile") yline(0, lcolor(red) lpattern(dash)) ///
    note("Source: Authors' calculation from VHLSS 2024") 
graph export "$path\figures\fig8_hetero_marginal.png", as(png) replace width(2000)

esttab Het_Q using "$path\Table_Heterogeneity.rtf", replace ///
    b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(1.credit_access 1.credit_access#2.quintile 1.credit_access#3.quintile) ///
    mtitle("Heterogeneity by Quintile") title("Heterogeneous Treatment Effects")

/* ====================== 2. MECHANISM ANALYSIS ====================== */
display "--- 2. Mechanism: Credit Type ---"
eststo Mech_B: regress housing_burden i.credit_type ln_income tsnguoi collateral edu_head age_head informal ///
    if credit_access == 1 [pw=wt45], vce(robust)

esttab Mech_B using "$path\Table_Mechanism.rtf", replace ///
    b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(*.credit_type) mtitle("By Credit Purpose") ///
    title("Mechanism: Effect of Different Credit Types on Housing Burden")

/* ====================== 3. QUANTILE REGRESSION (FIXED LOOP) ====================== */
display "--- 3. Quantile Regressions ---"
eststo clear
foreach q in 10 25 50 75 90 {
    quietly qreg housing_burden credit_access ln_income tsnguoi collateral, quantile(`q') vce(robust)
    eststo Q`q'
}
esttab Q10 Q25 Q50 Q75 Q90 using "$path\Table_Quantile_Advanced.rtf", replace ///
    b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitle("Q10" "Q25" "Q50" "Q75" "Q90") title("Quantile Regression - Housing Burden")

/* ====================== 4. ADDITIONAL ROBUSTNESS ====================== */
display "--- 4. Advanced Robustness ---"
capture encode tinh, gen(tinh_num) 

eststo Rob_FE: etregress housing_burden ln_income tsnguoi collateral i.tinh_num [pw=wt45], ///
    treat(credit_access = ln_income collateral i.tinh_num peer_effect social_network) vce(cluster tinh_num)

winsor2 housing_burden, cuts(1 99) suffix(_w)
eststo Rob_Win: etregress housing_burden_w ln_income tsnguoi collateral [pw=wt45], ///
    treat(credit_access = ln_income collateral peer_effect social_network) vce(robust)

esttab Main Het_Q Rob_FE Rob_Win using "$path\Table_AdvancedRobustness.rtf", replace ///
    b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(1.credit_access ln_income tsnguoi collateral) ///
    mtitle("Main" "Hetero" "Province FE" "Winsorized") title("Robustness Checks")

/* ====================== 5. POLICY SIMULATION ====================== */
display "--- 5. Policy Counterfactual ---"
qui etregress housing_burden ln_income tsnguoi collateral [pw=wt45], ///
    treat(credit_access = ln_income collateral peer_effect social_network) vce(robust)
predict xb_hat, xb
gen sim_social_rent = xb_hat - _b[collateral]*collateral if e(sample)

sum housing_burden if quintile <= 2 [aw=wt45]
local mean1 = r(mean)
sum sim_social_rent if quintile <= 2 [aw=wt45]
local mean2 = r(mean)
local reduction = `mean1' - `mean2'
display "=== POLICY IMPACT: Nhà ở xã hội cho thuê giảm " %4.2f `reduction' " pp gánh nặng cho Q1 & Q2 ==="

/* ====================== 6. ĐỒ THỊ SO SÁNH TP. HÀ NỘI & TP. HỒ CHÍ MINH ====================== */
display "--- 6. Spatial Heterogeneity: Hanoi vs HCMC ---"
capture drop major_city
gen major_city = ""
replace major_city = "Hanoi" if tinh == "01" | matinh == "01"
replace major_city = "HCMC"  if tinh == "79" | matinh == "79"

graph box housing_burden if major_city != "", over(credit_access) over(major_city) ///
    title("Housing Burden by Credit Access: Hanoi vs HCMC", size(medsmall)) ///
    ytitle("Housing Burden (% of Income)") ///
    note("Source: Authors' calculation from VHLSS 2024") 
graph export "$path\figures\fig9_hn_hcmc_boxplot.png", as(png) replace width(2000)

graph bar (mean) housing_burden if major_city != "", over(quintile) over(credit_access) over(major_city) ///
    title("Housing Burden by Income Quintile & Credit Access", size(medsmall)) ///
    ytitle("Average Housing Burden (%)") ///
    note("Source: Authors' calculation from VHLSS 2024") 
graph export "$path\figures\fig10_hn_hcmc_bar.png", as(png) replace width(2000)

* Bổ sung chạy lại Main để lưu vào bộ nhớ trước khi xuất bảng
/* --- XÓA SẠCH BỘ NHỚ CŨ ĐỂ LÀM LẠI --- */
eststo clear

/* 1. CHẠY LẠI MODEL MAIN */
display "--- Running Main Model ---"
qui etregress housing_burden ln_income tsnguoi collateral edu_head age_head informal ///
    [pw=wt45], treat(credit_access = ln_income collateral informal edu_head age_head peer_effect social_network) vce(robust)
eststo Main

/* 2. CHẠY LẠI MODEL HETEROGENEITY */
display "--- Running Hetero Model ---"
qui etregress housing_burden i.credit_access##i.quintile ln_income tsnguoi collateral edu_head age_head informal ///
    [pw=wt45], treat(credit_access = ln_income collateral informal edu_head age_head peer_effect social_network) vce(robust)
eststo Het_Q

/* 3. CHẠY LẠI MODEL PROVINCE FE */
display "--- Running Province FE Model ---"
capture encode tinh, gen(tinh_num) 
qui etregress housing_burden ln_income tsnguoi collateral i.tinh_num [pw=wt45], ///
    treat(credit_access = ln_income collateral i.tinh_num peer_effect social_network) vce(cluster tinh_num)
eststo Rob_FE

/* 4. CHẠY LẠI MODEL WINSORIZE */
display "--- Running Winsorize Model ---"
capture winsor2 housing_burden, cuts(1 99) suffix(_w)
qui etregress housing_burden_w ln_income tsnguoi collateral [pw=wt45], ///
    treat(credit_access = ln_income collateral peer_effect social_network) vce(robust)
eststo Rob_Win

/* 5. XUẤT BẢNG TỔNG HỢP 4 MÔ HÌNH VÀO 1 FILE RTF */
display "--- Exporting Table ---"
esttab Main Het_Q Rob_FE Rob_Win using "Table_AdvancedRobustness.rtf", replace ///
    b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    keep(1.credit_access ln_income tsnguoi collateral) ///
    mtitle("Main" "Hetero" "Province FE" "Winsorized") ///
    title("Advanced Robustness Checks") ///
    addnotes("Robust SE in parentheses. FE model uses clustered SE.")

display "=== HOÀN THÀNH ==="
*====================================================			  
log close

*======================================================*			  
* END ======================================================*			  
log close