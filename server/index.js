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
            'audio/webm', 'audio/x-m4a'
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

        res.json({
            success: true,
            message: 'تم رفع الملف الصوتي بنجاح',
            file: fileInfo
        });

    } catch (err) {
        console.error('Error uploading file:', err);
        res.status(500).json({ error: 'فشل في رفع الملف' });
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
        res.status(500).json({ error: 'Failed to fetch messages' });
    }
});

app.get('/api/users', async (req, res) => {
    try {
        const users = await db.getAllUsers();
        res.json(users);
    } catch (err) {
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

        socket.emit('initial_data', { messages, users });

    } catch (err) {
        console.error('Error sending initial data:', err);
    }

    // تسجيل دخول المستخدم
    socket.on('user_login', async (username) => {
        try {
            await db.updateUserStatus(username, 'online');
            socket.username = username;
            io.emit('users_update', await db.getAllUsers());
        } catch (err) {
            console.error('Error updating user status:', err);
        }
    });

    // رسالة نصية
    socket.on('send_message', async (data) => {
        try {
            await db.saveMessage(data.sender, data.message, data.isVoiceMessage || false);

            const messages = await db.getRecentMessages();
            io.emit('new_message', messages[messages.length - 1]);

        } catch (err) {
            console.error('Error saving message:', err);
        }
    });

    // رسالة صوتية
    socket.on('send_voice_message', async (data) => {
        try {
            const { sender, voiceFile, duration } = data;

            await db.saveVoiceMessage(sender, voiceFile, duration);

            const messages = await db.getRecentMessages();
            io.emit('new_message', messages[messages.length - 1]);

        } catch (err) {
            console.error('Error saving voice message:', err);
        }
    });

    // عند الخروج
    socket.on('disconnect', async () => {
        if (socket.username) {
            try {
                await db.updateUserStatus(socket.username, 'offline');
                io.emit('users_update', await db.getAllUsers());
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
    console.log(`Server running on port ${PORT}`);
});


// ===============================
//  🔥 إغلاق النظام بدون مشاكل
// ===============================
process.on('SIGINT', () => {
    db.close();
    process.exit(0);
});
