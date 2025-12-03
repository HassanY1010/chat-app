const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const path = require('path');
const db = require('./db');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

// منفذ السيرفر
const PORT = process.env.PORT || 3000;

// خدمة الملفات الثابتة
app.use(express.static(path.join(__dirname, '../public')));

// API لجلب الرسائل السابقة
app.get('/api/messages', async (req, res) => {
    try {
        const messages = await db.getAllMessages();
        res.json(messages);
    } catch (err) {
        res.status(500).json({ error: 'Failed to fetch messages' });
    }
});

// API لجلب المستخدمين
app.get('/api/users', async (req, res) => {
    try {
        const users = await db.getAllUsers();
        res.json(users);
    } catch (err) {
        res.status(500).json({ error: 'Failed to fetch users' });
    }
});

// إدارة اتصالات Socket.IO
io.on('connection', async (socket) => {
    console.log('New user connected:', socket.id);

    // إرسال البيانات الأولية عند الاتصال
    try {
        const [messages, users] = await Promise.all([
            db.getRecentMessages(),
            db.getAllUsers()
        ]);
        
        socket.emit('initial_data', { messages, users });
    } catch (err) {
        console.error('Error sending initial data:', err);
    }

    // معالجة تسجيل دخول المستخدم
    socket.on('user_login', async (username) => {
        try {
            await db.updateUserStatus(username, 'online');
            socket.username = username;
            
            // إرسال تحديث حالة المستخدم للجميع
            const users = await db.getAllUsers();
            io.emit('users_update', users);
            
            console.log(`${username} logged in`);
        } catch (err) {
            console.error('Error updating user status:', err);
        }
    });

    // معالجة إرسال الرسائل
    socket.on('send_message', async (data) => {
        try {
            // حفظ الرسالة في قاعدة البيانات
            await db.saveMessage(data.sender, data.message);
            
            // جلب الرسالة المحفوظة مع الوقت
            const messages = await db.getRecentMessages();
            const newMessage = messages[messages.length - 1];
            
            // إرسال الرسالة للجميع
            io.emit('new_message', newMessage);
        } catch (err) {
            console.error('Error saving message:', err);
            socket.emit('error', 'Failed to send message');
        }
    });

    // عند انقطاع الاتصال
    socket.on('disconnect', async () => {
        if (socket.username) {
            try {
                await db.updateUserStatus(socket.username, 'offline');
                const users = await db.getAllUsers();
                io.emit('users_update', users);
                console.log(`${socket.username} disconnected`);
            } catch (err) {
                console.error('Error updating user status on disconnect:', err);
            }
        }
    });
});

// تشغيل السيرفر
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});


// معالجة إغلاق التطبيق بشكل صحيح
process.on('SIGINT', () => {
    db.close();
    process.exit(0);
});