-- 1. Bảng Users (Sinh viên)
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    zalo_id VARCHAR(50) UNIQUE NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    role VARCHAR(20) DEFAULT 'STUDENT'
);

-- 2. Bảng Technicians (Thợ)
CREATE TABLE technicians (
    id SERIAL PRIMARY KEY,
    user_id INT UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    skills TEXT[],                   -- Mảng kỹ năng: {'Điện', 'Nước'}
    experience_years INT DEFAULT 0,
    rating_avg DECIMAL(3,2) DEFAULT 5.0,
    is_active BOOLEAN DEFAULT true
);

-- 3. Bảng Services (Danh mục dịch vụ)
CREATE TABLE services (
    id INT PRIMARY KEY,
    cat_id INT,
    name VARCHAR(200) NOT NULL,
    price VARCHAR(50),
    is_hot BOOLEAN DEFAULT false,
    icon VARCHAR(50)
);

-- 4. Bảng Orders (Đơn hàng)
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id),
    service_id INT REFERENCES services(id),
    location VARCHAR(200),
    status VARCHAR(20) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Chèn dữ liệu --
INSERT INTO services (id, cat_id, name, price, is_hot, icon) VALUES 
(101, 1, 'Xử lý chập cháy ổ điện', 'Từ 100.000đ', true, 'fa-plug-circle-xmark'),
(102, 1, 'Thay bóng đèn LED/Tuýp', '50.000đ/Bóng', false, 'fa-lightbulb'),
(201, 2, 'Thay vòi xịt vệ sinh', '~ 50.000đ', false, 'fa-sink'),
(301, 3, 'Cài lại Win & Phần mềm', '100.000đ', true, 'fa-windows');

INSERT INTO users (zalo_id, full_name) VALUES ('ZALO_001', 'Sinh Viên FPT Demo');
-- Sửa lại lần 1 --
-- Cho phép zalo_id được để trống
ALTER TABLE users ALTER COLUMN zalo_id DROP NOT NULL;

-- Thêm cột Số điện thoại và Mật khẩu
ALTER TABLE users ADD COLUMN phone VARCHAR(20) UNIQUE;
ALTER TABLE users ADD COLUMN password VARCHAR(100);
-- 1. Xóa dịch vụ "Cài lại Win & Phần mềm"
DELETE FROM services WHERE id = 301;

-- 2. Thêm các dịch vụ mới cho nhóm Điện (cat_id = 1)
INSERT INTO services (id, cat_id, name, price, is_hot, icon) VALUES 
(105, 1, 'Sửa Tivi', 'Khảo sát báo giá', false, 'fa-tv'),
(106, 1, 'Sửa Tủ lạnh', 'Từ 150.000đ', false, 'fa-temperature-arrow-down'),
(107, 1, 'Sửa Điều hòa / Vệ sinh', 'Từ 200.000đ', true, 'fa-snowflake');

-- 3. Thêm dịch vụ mới cho nhóm Nước (cat_id = 2)
INSERT INTO services (id, cat_id, name, price, is_hot, icon) VALUES 
(205, 2, 'Thông tắc bồn cầu / cống', 'Từ 150.000đ', true, 'fa-toilet');

-- 4. Thêm các dịch vụ Điện tử mới vào nhóm Máy tính (cat_id = 3)
INSERT INTO services (id, cat_id, name, price, is_hot, icon) VALUES 
(302, 3, 'Sửa Điện thoại', 'Kiểm tra báo giá', true, 'fa-mobile-screen'),
(303, 3, 'Sửa Laptop', 'Từ 100.000đ', false, 'fa-laptop-medical');
-- 5. Thêm dịch vụ vào nhóm Sửa Khóa (cat_id = 4)
INSERT INTO services (id, cat_id, name, price, is_hot, icon) VALUES 
(402, 4, 'Sửa khóa xe / Phá ổ', 'Từ 50.000đ', true, 'fa-motorcycle'),
(403, 4, 'Sửa khóa cửa / Thay ổ', 'Từ 100.000đ', false, 'fa-door-closed');
-- 6. Thêm bảng lưu hồ sơ thợ
CREATE TABLE IF NOT EXISTS tech_applications (
    id SERIAL PRIMARY KEY,
    user_id INT,
    phone VARCHAR(20),
    location VARCHAR(100),
	skills TEXT,
    status VARCHAR(50) DEFAULT 'Chờ duyệt',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- 7. Sửa bảng users (phân biệt thợ với sinh viên)
-- Thêm cột is_tech (Mặc định ai đăng ký trên web cũng là FALSE - tức là Khách)
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_tech BOOLEAN DEFAULT FALSE;

-- Thêm trực tiếp các tài khoản Thợ vào hệ thống (Đánh dấu is_tech = TRUE)
INSERT INTO users (phone, full_name, password, is_tech) 
VALUES 
('0912345678', 'Thợ Nước Trần Văn A', '123456', TRUE);
-- 8. Thêm cột image vào bảng services
ALTER TABLE services ADD COLUMN IF NOT EXISTS image TEXT;

-----Sửa lại lần 2-------
-- 1. XÓA BỚT CÁC DỊCH VỤ KHÔNG CẦN THIẾT, CHỈ GIỮ LẠI ĐIỆN THOẠI & MÁY TÍNH (cat_id = 3)
TRUNCATE TABLE services RESTART IDENTITY CASCADE;

INSERT INTO services (id, cat_id, name, price, is_hot, icon) VALUES 
(301, 3, 'Cài lại Win & Phần mềm đồ họa', '100.000đ', true, 'fa-windows'),
(302, 3, 'Sửa màn hình / Ép kính điện thoại', 'Kiểm tra báo giá', true, 'fa-mobile-screen'),
(303, 3, 'Vệ sinh Laptop & Tra keo tản nhiệt', '120.000đ', false, 'fa-laptop-medical'),
(304, 3, 'Thay Pin / Bàn phím Laptop', 'Từ 200.000đ', false, 'fa-keyboard'),
(305, 3, 'Cứu dữ liệu ổ cứng / Thẻ nhớ', 'Khảo sát báo giá', false, 'fa-database');

-- 2. TẠO BẢNG ĐÁNH GIÁ SẢN PHẨM/DỊCH VỤ (Kiểu Shopee, Lazada)
CREATE TABLE IF NOT EXISTS reviews (
    id SERIAL PRIMARY KEY,
    order_id INT UNIQUE REFERENCES orders(id) ON DELETE CASCADE, -- Mỗi đơn hàng chỉ được đánh giá 1 lần
    user_id INT REFERENCES users(id) ON DELETE CASCADE,
    service_id INT REFERENCES services(id) ON DELETE CASCADE,
    rating INT CHECK (rating >= 1 AND rating <= 5),             -- Số sao từ 1 đến 5
    comment TEXT,                                               -- Nội dung bình luận
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);