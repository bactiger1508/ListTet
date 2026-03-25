# 🧧 Săn Sale Tết - Hệ Thống Quản Lý Mua Sắm Thông Minh

Ứng dụng giúp người dùng lập kế hoạch, theo dõi chi tiêu và quản lý tài chính hiệu quả trong dịp Tết Nguyên Đán với các tính năng phân tích thông minh và lưu trữ hình ảnh lịch sử.

## 🚀 Tính Năng Cốt Lõi (Business Logic)

### 1. Quản Lý Ngân Sách Thông Minh (Smart Budgeting)
- **Hệ thống Phân tích Độ lệch (Variance Analysis):** So sánh tổng ngân sách được cấp (`planned_budget`) với tổng giá trị giỏ hàng mong muốn (`target_price * quantity`) để dự báo tình hình tài chính trước khi mua.
- **Cảnh Báo Sức Khỏe Tài Chính (Financial Health):**
  - 🟢 **Healthy:** Kế hoạch chi tiêu nằm trong ngân sách.
  - 🟡 **Danger:** Tổng giá trị giỏ hàng vượt ngân sách dự kiến.
  - 🔴 **Critical:** Số tiền thực tế đã chi vượt quá ngân sách cho phép.
- **Smart Suggestions:** Tự động đưa ra các gợi ý tối ưu hóa (ví dụ: cắt giảm các món không thiết yếu) khi ngân sách rơi vào tình trạng Danger/Critical.

### 2. Quản Lý Media & Hóa Đơn (Integrated Media)
- **Hệ thống Receipt & Product Gallery:** Lưu trữ tập trung toàn bộ hình ảnh liên quan đến kỳ Tết (Hóa đơn và Ảnh sản phẩm).
- **Liên kết ngữ cảnh (Contextual Binding):** Ảnh được gắn trực tiếp vào từng món đồ (để nhớ mẫu sản phẩm) hoặc từng giao dịch chi tiêu (để đối chiếu hóa đơn).

### 3. Trí Tuệ Lịch Sư (Historical Intelligence)
- **So sánh đa mùa (Multi-season Comparison):** Tự động tìm kiếm và hiển thị dữ liệu lịch sử của món đồ dựa trên tên trong các năm cũ.
- **Nhận diện giá & ảnh:** Giúp người dùng biết chính xác năm ngoái mình mua món đó ở đâu, giá bao nhiêu để không bị mua đắt trong năm nay.






## 🎬 Kịch Bản Demo Điển Hình

**B1: Giới thiệu ứng dụng & Khởi tạo dữ liệu (Tạo Kỳ Tết)**
- Mở App, giới thiệu Màn hình Splash.
- Chuyển sang Tab `Kỳ Tết`, bấm dấu **(+)** để tạo "Tết Ất Tỵ 2025".
- Nhập *Thời gian bắt đầu, Kết thúc* và thiết lập *Tổng Ngân Sách Vĩ Mô* (VD: 20 triệu). Bấm **Lưu**.

**B2: Quản lý & Phân bổ Ngân Sách Chi Tiết**
- Trở về Tab `Tổng quan (Dashboard)` -> Bấm nút **Hạng mục** nhỏ phía trên biểu đồ.
- Chọn chức năng **Chỉnh sửa (Icon cây bút chì)** cạnh từng danh mục (Thực phẩm, Quà tặng, Quần áo...) để nhập số tiền cấp cho mỗi mục sao cho "Tổng phân bổ" khớp với "Tổng Ngân Sách".

**B3: Lên kế hoạch chi tiêu (Tạo Wishlist Cần Mua)**
- Chuyển sang Tab `Cần Mua`. Bấm **(+) Add** để thêm khoảng 2-3 món đồ cần sửa soạn.
- Nhập tên đồ, giá dự kiến, chọn hạng mục tương ứng. Bật nhãn "Quan trọng" (Ngôi sao) cho các món đồ thiết yếu. Thêm cả URL link mua hàng và chụp 1 tấm ảnh đính kèm minh họa (nếu có).

**B4: Chốt đơn & Đồng bộ luồng tiền tự động (Core Logic)**
- Vuốt trái một món hàng vừa tạo -> Bấm **Đã Mua**.
- Nhập giá tiền thực tế (có thể nhập thấp hơn giá dự kiến để App tự tính tiền Tiết Kiệm sinh lời).
- Dẫn chứng: Giới thiệu hệ thống tự động sinh ra một tờ hóa đơn bên Tab `Chi tiêu` giúp người dùng không bao giờ phải nhập tay 2 lần! 

**B5: Xử lý Hành vi thực tế (Cập nhật giá và Xóa liên đới)**
- Vuốt trái một món đã mua -> Ấn biểu tượng cây bút để **Sửa Giá**. Demo việc hóa đơn gốc bên Tab `Chi tiêu` cũng tự thay đổi số tiền nhảy theo.
- Lại vuốt trái món đó -> Ấn **Theo dõi** (Undo hủy thao tác mua). 
- Dẫn chứng: Chạy qua Tab `Chi tiêu` chỉ ra rằng Hóa rác ban nãy đã bị tiêu hủy sạch sẽ! Chứng minh luồng dữ liệu bảo vệ (Cascade Deletion) vô cùng khắt khe.

**B6: Tổng kết Mua Sắm (AI Advisor & Hệ sinh thái Gamification)**
- Trở trục về màn hình `Tổng quan (Dashboard)`. Kéo xuống Giới thiệu **Cây Tài Lộc** xanh tốt dựa trên số tiền tiết kiệm được. 
- Giới thiệu hộp thoại **Cố vấn AI thông minh** đang khen ngợi/hoặc phát cảnh báo đỏ nếu tiêu vượt mức. Xem Biểu đồ Tròn và Cột thể hiện trực quan các khoản chi.

**B7: Tổng kết Tết (Chức năng Thả thính - Gamification x2)**
- Bấm vào icon **Ngôi sao lấp lánh** trên góc phải trên cùng của Dashboard.
- Lướt qua màn hình Wrap up, tóm tắt lại "thành tựu" sắm Tết trong 1 năm qua .

**B8: Ghi chú bằng Hình Ảnh (Gallery)**
- Sang Tab `Thư viện`. Bấm dấu **(+)** để chụp hình 1 hóa đơn giấy hoặc cảnh nhà cửa ngày Tết, thêm ghi chú cho hóa đơn.

**B9: Khép lại Báo Cáo Tài Chính (Xuất CSV)**
- Quay về Tab `Tổng quan`. Kéo qua tab Thống kê/Báo cáo và bấm **Xuất CSV**. Mở file Excel ra để minh họa chức năng tích hợp gửi báo cáo qua Email thành công.

**B10: Nhân bản dữ liệu đón năm mới (Reusability)**
- Cuối cùng quay về Tab `Kỳ Tết`. Ấn **Nhân bản** cái Tết Ất Tỵ vất vả vừa gầy dựng sang thành "Tết Bính Ngọ 2026". 
- Kết luận: Chỉ với 1 click, người dùng đã bê nguyên Bộ danh mục và Danh sách đồ đạc Cần mua của năm cũ sang năm hiện tại siêu nhanh chóng. End Demo. Cúi chào hội đồng!

---

## 🛠 Kiến Trúc Kỹ Thuật (Tech Stack)

| Thành phần | Công nghệ sử dụng | Ý nghĩa |
|---|---|---|
| **Framework** | Flutter | Xây dựng giao diện mượt mà trên đa nền tảng |
| **State Management** | Provider | Quản lý luồng dữ liệu và trạng thái ứng dụng |
| **Database** | SQLite (sqflite) | Lưu trữ offline-first, hỗ trợ migration (V4) |
| **Storage** | Path Provider | Quản lý lưu trữ file ảnh nội bộ |
| **Tools** | Image Picker | Tích hợp camera và thư viện ảnh |
