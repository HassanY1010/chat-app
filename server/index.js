const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const path = require('path');
const db = require('./db');
const multer = require('multer');
const { v4: uuidv4 } = require('uuid');
const fs = require('fs-extra');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

const PORT = process.env.PORT || 3000;

// ===============================
//  🔥 Render: مكان ثابت للملفات
// ===============================
const uploadsDir = path.join(process.cwd(), 'data', 'uploads');
fs.ensureDirSync(uploadsDir);

// ===============================
//  🔥 Multer لرفع الصوتيات
// ===============================
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, uploadsDir);
    },
    filename: (req, file, cb) => {
        const uniqueName = `${uuidv4()}_${Date.now()}${path.extname(file.originalname)}`;
        cb(null, uniqueName);
    }
});

const upload = multer({
    storage: storage,
    limits: {
        fileSize: 10 * 1024 * 1024,
    },
    fileFilter: (req, file, cb) => {
        const allowedTypes = [
            'audio/mpeg', 'audio/wav', 'audio/ogg',
            'audio/webm', 'audio/x-m4a', 'audio/mp4'
        ];
        if (allowedTypes.includes(file.mimetype)) cb(null, true);
        else cb(new Error('نوع الملف غير مسموح'));
    }
});

// ===============================
//  🔥 ملفات الواجهة
// ===============================
app.use(express.static(path.join(__dirname, '../public')));

// رفع وتشغيل الصوتيات
app.use('/uploads', express.static(uploadsDir));

// ===============================
//  🔥 API رفع الصوتيات
// ===============================
app.post('/api/upload-voice', upload.single('voice'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'لم يتم رفع أي ملف' });
        }

        const fileInfo = {
            filename: req.file.filename,
            originalname: req.file.originalname,
            mimetype: req.file.mimetype,
            size: req.file.size,
            path: `/uploads/${req.file.filename}`,
            url: `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`
        };

        console.log('File uploaded successfully:', fileInfo);

        res.json({
            success: true,
            message: 'تم رفع الملف الصوتي بنجاح',
            file: fileInfo
        });

    } catch (err) {
        console.error('Error uploading file:', err);
        res.status(500).json({ error: 'فشل في رفع الملف: ' + err.message });
    }
});

// ===============================
//  🔥 API الرسائل والمستخدمين
// ===============================
app.get('/api/messages', async (req, res) => {
    try {
        const messages = await db.getAllMessages();
        res.json(messages);
    } catch (err) {
        console.error('Error fetching messages:', err);
        res.status(500).json({ error: 'Failed to fetch messages' });
    }
});

app.get('/api/users', async (req, res) => {
    try {
        const users = await db.getAllUsers();
        res.json(users);
    } catch (err) {
        console.error('Error fetching users:', err);
        res.status(500).json({ error: 'Failed to fetch users' });
    }
});

// ===============================
//  🔥 Socket.IO Chat
// ===============================
io.on('connection', async (socket) => {
    console.log('New user connected:', socket.id);

    // إرسال بيانات أولية
    try {
        const [messages, users] = await Promise.all([
            db.getRecentMessages(),
            db.getAllUsers()
        ]);

        console.log('Sending initial data:', { messages: messages.length, users: users.length });
        socket.emit('initial_data', { messages, users });

    } catch (err) {
        console.error('Error sending initial data:', err);
        socket.emit('error', 'فشل في تحميل البيانات الأولية');
    }

    // تسجيل دخول المستخدم
    socket.on('user_login', async (username) => {
        try {
            console.log('User login:', username);
            await db.updateUserStatus(username, 'online');
            socket.username = username;
            
            const updatedUsers = await db.getAllUsers();
            io.emit('users_update', updatedUsers);
            console.log('User status updated:', username);
            
        } catch (err) {
            console.error('Error updating user status:', err);
            socket.emit('error', 'فشل في تحديث حالة المستخدم');
        }
    });

    // رسالة نصية
    socket.on('send_message', async (data) => {
        try {
            console.log('Received message:', data);
            
            // حفظ الرسالة في قاعدة البيانات
            const messageId = await db.saveMessage(data.sender, data.message, false);
            console.log('Message saved with ID:', messageId);
            
            // جلب آخر الرسائل
            const messages = await db.getRecentMessages();
            const lastMessage = messages[messages.length - 1];
            
            console.log('Broadcasting new message:', lastMessage);
            io.emit('new_message', lastMessage);
            
        } catch (err) {
            console.error('Error saving message:', err);
            socket.emit('error', 'فشل في حفظ الرسالة');
        }
    });

    // رسالة صوتية
    socket.on('send_voice_message', async (data) => {
        try {
            console.log('Received voice message:', data);
            
            // حفظ الرسالة الصوتية في قاعدة البيانات
            const messageId = await db.saveVoiceMessage(
                data.sender, 
                data.voiceFile, 
                data.duration
            );
            console.log('Voice message saved with ID:', messageId);
            
            // جلب آخر الرسائل
            const messages = await db.getRecentMessages();
            const lastMessage = messages[messages.length - 1];
            
            console.log('Broadcasting new voice message:', lastMessage);
            io.emit('new_message', lastMessage);
            
        } catch (err) {
            console.error('Error saving voice message:', err);
            socket.emit('error', 'فشل في حفظ الرسالة الصوتية');
        }
    });

    // عند الخروج
    socket.on('disconnect', async () => {
        console.log('User disconnected:', socket.id, 'Username:', socket.username);
        if (socket.username) {
            try {
                await db.updateUserStatus(socket.username, 'offline');
                const updatedUsers = await db.getAllUsers();
                io.emit('users_update', updatedUsers);
                console.log('User status updated to offline:', socket.username);
            } catch (err) {
                console.error('Error on disconnect:', err);
            }
        }
    });
});

// ===============================
//  🔥 تشغيل السيرفر
// ===============================
server.listen(PORT, () => {
    console.log(`✅ Server running on port ${PORT}`);
    console.log(`📁 Uploads directory: ${uploadsDir}`);
    console.log(`🌐 Web interface: http://localhost:${PORT}`);
});

// ===============================
//  🔥 إغلاق النظام بدون مشاكل
// ===============================
process.on('SIGINT', () => {
    console.log('Shutting down server...');
    db.close();
    process.exit(0);
});
