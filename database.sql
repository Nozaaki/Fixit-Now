-- ==========================================================
-- 1. BẢNG USERS (Tài khoản sinh viên & Thợ)
-- ==========================================================
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    phone VARCHAR(20) UNIQUE NOT NULL,                      -- Bắt buộc đăng nhập/đăng ký bằng SĐT
    password VARCHAR(100) NOT NULL,                         -- Mật khẩu tài khoản
    full_name VARCHAR(100) NOT NULL,                        -- Tên người dùng
    zalo_id VARCHAR(50) UNIQUE NULL,                        -- Cho phép NULL để đăng ký bằng SĐT không bị lỗi
    role VARCHAR(20) DEFAULT 'STUDENT',
    is_tech BOOLEAN DEFAULT FALSE                           -- Phân biệt Thợ (TRUE) và Khách (FALSE)
);

-- ==========================================================
-- 2. BẢNG SERVICES (Danh mục dịch vụ công nghệ)
-- ==========================================================
CREATE TABLE services (
    id INT PRIMARY KEY,                                     -- Giữ ID cố định (301, 302,...) theo code Frontend
    cat_id INT NOT NULL,
    name VARCHAR(200) NOT NULL,
    price VARCHAR(50) NOT NULL,
    is_hot BOOLEAN DEFAULT FALSE,
    icon VARCHAR(50) NOT NULL,
    image TEXT NULL                                         -- Link ảnh minh họa dịch vụ
);

-- ==========================================================
-- 3. BẢNG ORDERS (Đơn hàng đặt sửa chữa)
-- ==========================================================
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id) ON DELETE CASCADE,     -- Liên kết với tài khoản đặt
    service_id INT REFERENCES services(id) ON DELETE CASCADE, -- Liên kết với dịch vụ cần sửa
    location VARCHAR(200) NOT NULL,                         -- Vị trí Dom/Phòng
    status VARCHAR(20) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================================
-- 4. BẢNG REVIEWS (Đánh giá chuẩn Shopee/Lazada)
-- ==========================================================
CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    order_id INT UNIQUE REFERENCES orders(id) ON DELETE CASCADE,   -- Mỗi đơn hàng chỉ được đánh giá 1 lần
    user_id INT REFERENCES users(id) ON DELETE CASCADE,
    service_id INT REFERENCES services(id) ON DELETE CASCADE,
    rating INT CHECK (rating >= 1 AND rating <= 5),                 -- Số sao từ 1 đến 5
    comment TEXT NULL,                                              -- Bình luận phản hồi
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================================
-- 5. BẢNG TECH_APPLICATIONS (Hồ sơ đăng ký làm thợ)
-- ==========================================================
CREATE TABLE tech_applications (
    id SERIAL PRIMARY KEY,
    user_id INT UNIQUE REFERENCES users(id) ON DELETE CASCADE,      -- Liên kết chuẩn bảo vệ dữ liệu khóa ngoại
    phone VARCHAR(20) NOT NULL,
    location VARCHAR(100) NOT NULL,
    skills TEXT NOT NULL,                                           -- Lưu chuỗi kỹ năng ("Máy tính", "Điện thoại")
    status VARCHAR(50) DEFAULT 'Chờ duyệt',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================================
-- DỮ LIỆU MẪU ĐỂ CHẠY DEMO ĐỒ ÁN EXE201
-- ==========================================================

-- Chèn dữ liệu danh sách dịch vụ Máy tính & Điện thoại (cat_id = 3)
INSERT INTO services (id, cat_id, name, price, is_hot, icon, image) VALUES 
(301, 3, 'Cài lại Win & Phần mềm đồ họa', '100.000đ', true, 'fa-windows', 'https://images.unsplash.com/photo-1588508065123-287b28e013da?q=80&w=400&auto=format&fit=crop'),
(302, 3, 'Sửa màn hình / Ép kính điện thoại', 'Kiểm tra báo giá', true, 'fa-mobile-screen', 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?q=80&w=400&auto=format&fit=crop'),
(303, 3, 'Vệ sinh Laptop & Tra keo tản nhiệt', '120.000đ', false, 'fa-laptop-medical', 'https://images.unsplash.com/photo-1603302576837-37561b2e2302?q=80&w=400&auto=format&fit=crop'),
(304, 3, 'Thay Pin / Bàn phím Laptop', 'Từ 200.000đ', false, 'fa-keyboard', 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?q=80&w=400&auto=format&fit=crop'),
(305, 3, 'Cứu dữ liệu ổ cứng / Thẻ nhớ', 'Khảo sát báo giá', false, 'fa-database', 'https://images.unsplash.com/photo-1601524909162-be87252be298?q=80&w=400&auto=format&fit=crop');

-- Tạo sẵn một tài khoản Thợ mẫu để test hệ thống phân quyền (Mật khẩu: 123456)
INSERT INTO users (phone, full_name, password, is_tech) 
VALUES ('0912345678', 'Thợ Kỹ Thuật Trần Văn A', '123456', TRUE);