const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const axios = require('axios'); // Thêm thư viện axios để gọi API Telegram

const app = express();
app.use(cors());
app.use(express.json());

// Kết nối PostgreSQL 
// const pool = new Pool({
//     user: 'postgres',
//     host: 'localhost',
//     database: 'Fixit Now',
//     password: '230704',
//     port: 5432,
// });

// Cấu hình kết nối PostgreSQL cho môi trường Cloud (Render/Heroku/Railway)
const pool = new Pool({
    connectionString: process.env.DATABASE_URL, // Render/Heroku/Railway sẽ cung cấp biến môi trường này
    ssl: {
        rejectUnauthorized: false // Cấu hình SSL cho PostgreSQL trên Cloud
    }
});

// 1. Lấy danh sách dịch vụ
app.get('/api/services', async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM services');
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// 2. Tạo Đơn Hàng (Đã thêm tính năng báo về Telegram)
app.post('/api/orders', async (req, res) => {
    const { userId, serviceId, location, userName } = req.body;

    try {
        const orderResult = await pool.query(
            'INSERT INTO orders (user_id, service_id, location) VALUES ($1, $2, $3) RETURNING id, created_at',
            [userId, serviceId, location]
        );
        const newOrder = orderResult.rows[0];

        const serviceResult = await pool.query('SELECT name, price FROM services WHERE id = $1', [serviceId]);
        const service = serviceResult.rows[0];

        const orderDate = new Date(newOrder.created_at || new Date()).toLocaleString('vi-VN');

        // ==========================================
        // CẤU HÌNH THÔNG BÁO TELEGRAM CỦA KHÔI
        // ==========================================
        // Đọc cấu hình bảo mật từ biến môi trường của Render
        const teleToken = process.env.TELE_TOKEN; 
        const chatId = process.env.TELE_CHAT_ID;
        
        // Nội dung tin nhắn
        const teleMessage = `
🚨 **CÓ ĐƠN HÀNG MỚI!**
-----------------------------
👤 **Khách hàng:** ${userName || 'Khách (Chưa có tên)'}
🛠 **Dịch vụ:** ${service.name}
📍 **Địa chỉ:** ${location}
💰 **Giá dự kiến:** ${service.price}
⏰ **Thời gian:** ${orderDate}
🆔 **Mã đơn:** FIXIT${newOrder.id}
-----------------------------
👉 *Khôi hãy check đơn và điều phối thợ nhé!*
        `;

        // Lệnh gửi tin nhắn qua Telegram API (chạy ngầm, không ảnh hưởng đến tốc độ của app)
        if (teleToken !== 'YOUR_BOT_TOKEN_HERE' && chatId !== 'YOUR_CHAT_ID_HERE') {
            axios.post(`https://api.telegram.org/bot${teleToken}/sendMessage`, {
                chat_id: chatId,
                text: teleMessage,
                parse_mode: 'Markdown'
            }).catch(err => console.error("Lỗi gửi Telegram:", err.message));
        }
        // ==========================================

        res.json({ 
            success: true, 
            order: {
                id: `FIXIT${newOrder.id}FPT`, 
                rawId: newOrder.id,
                serviceName: service.name,
                price: service.price,
                location: location,
                date: orderDate
            }
        });

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// 3. API Đăng ký tài khoản
app.post('/api/register', async (req, res) => {
    const { phone, fullName, password } = req.body;
    try {
        const result = await pool.query(
            'INSERT INTO users (phone, full_name, password) VALUES ($1, $2, $3) RETURNING id, full_name, phone',
            [phone, fullName, password]
        );
        res.json({ success: true, message: "Đăng ký thành công!", user: result.rows[0] });
    } catch (err) {
        // In lỗi chi tiết ra tab LOGS trên Render để Khôi kiểm tra
        console.error("🔴 LỖI ĐĂNG KÝ THỰC TẾ:", err.message);
        
        // Trả về lỗi thật cho giao diện alert để biết đường xử lý
        res.json({ success: false, error: `Lỗi hệ thống: ${err.message}` });
    }
});

// 4. API Đăng nhập 
app.post('/api/login', async (req, res) => {
    const { phone, password } = req.body;
    try {
        const result = await pool.query(
            'SELECT id, full_name, phone, is_tech FROM users WHERE phone = $1 AND password = $2',
            [phone, password]
        );
        if (result.rows.length > 0) {
            res.json({ success: true, message: "Đăng nhập thành công!", user: result.rows[0] });
        } else {
            res.json({ success: false, error: "Sai thông tin đăng nhập!" });
        }
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

// 5. API Lấy lịch sử đơn hàng của 1 User
app.get('/api/orders/history/:userId', async (req, res) => {
    const userId = req.params.userId;
    try {
        const result = await pool.query(`
            SELECT 
                o.id, 
                o.location, 
                o.created_at, 
                s.name as service_name, 
                s.price, 
                s.icon,
                -- Kiểm tra xem đơn hàng này đã tồn tại trong bảng reviews chưa, nếu có thì trả về true, ngược lại false
                CASE WHEN r.id IS NOT NULL THEN TRUE ELSE FALSE END as is_reviewed
            FROM orders o
            JOIN services s ON o.service_id = s.id
            LEFT JOIN reviews r ON o.id = r.order_id
            WHERE o.user_id = $1
            ORDER BY o.created_at DESC
        `, [userId]);
        
        res.json({ success: true, orders: result.rows });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

// 6. API Nộp hồ sơ đăng ký làm thợ
app.post('/api/tech-register', async (req, res) => {
    const { userId, phone, location, skills } = req.body; 
    
    try {
        const checkExist = await pool.query('SELECT * FROM tech_applications WHERE user_id = $1', [userId]);
        if (checkExist.rows.length > 0) {
            return res.json({ success: false, error: "Bạn đã nộp hồ sơ rồi, vui lòng chờ Admin duyệt nhé!" });
        }

        await pool.query(
            'INSERT INTO tech_applications (user_id, phone, location, skills) VALUES ($1, $2, $3, $4)',
            [userId, phone, location, skills]
        );
        res.json({ success: true, message: "Hồ sơ của bạn đã được gửi thành công!" });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

// 7. API Viết Đánh Giá (Shopee / Lazada Style)
app.post('/api/reviews', async (req, res) => {
    const { orderId, userId, serviceId, rating, comment } = req.body;
    try {
        // Kiểm tra xem đơn hàng này đã được đánh giá chưa
        const check = await pool.query('SELECT id FROM reviews WHERE order_id = $1', [orderId]);
        if (check.rows.length > 0) {
            return res.json({ success: false, error: "Đơn hàng này đã được đánh giá trước đó!" });
        }

        await pool.query(
            'INSERT INTO reviews (order_id, user_id, service_id, rating, comment) VALUES ($1, $2, $3, $4, $5)',
            [orderId, userId, serviceId, rating, comment]
        );
        res.json({ success: true, message: "Cảm ơn bạn đã đánh giá dịch vụ!" });
    } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// 8. API Lấy tất cả đánh giá của 1 dịch vụ
app.get('/api/reviews/:serviceId', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT r.id, r.rating, r.comment, r.created_at, u.full_name 
            FROM reviews r
            JOIN users u ON r.user_id = u.id
            WHERE r.service_id = $1
            ORDER BY r.created_at DESC
        `, [req.params.serviceId]);
        res.json({ success: true, reviews: result.rows });
    } catch (err) { res.status(500).json({ success: false, error: err.message }); }
});

// Server lắng nghe cổng động do nền tảng Cloud cấp (Render/Heroku/Railway)
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`🚀 Server FixIt Now đang hoạt động tại cổng ${PORT}`);
});

// ==========================================
// CẤU HÌNH TRẢ VỀ GIAO DIỆN FRONTEND
// ==========================================
const path = require('path');

// Chỉ định cho Express biết vị trí để đọc các file tĩnh (nếu có hình ảnh, css đi kèm)
app.use(express.static(path.join(__dirname)));

// Khi người dùng truy cập vào đường link gốc (/) -> Tự động gửi file index.html về trình duyệt
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});