const sqlite3 = require('sqlite3').verbose();
const path = require('path');

class Database {
    constructor() {
        // استخدام قاعدة بيانات في الذاكرة مع حفظ دائم
      // تعديل مسار قاعدة البيانات ليعمل على Render داخل مجلد /data
const dbPath = path.join(process.cwd(), 'data', 'chat.db');

this.db = new sqlite3.Database(dbPath, (err) => {
    if (err) {
        console.error('Error opening database:', err);
    } else {
        console.log(`Connected to SQLite database at: ${dbPath}`);
        this.initializeDatabase();
    }
});

    }

    initializeDatabase() {
        const createMessagesTable = `
            CREATE TABLE IF NOT EXISTS messages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                sender TEXT NOT NULL,
                message TEXT NOT NULL,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                has_voice INTEGER DEFAULT 0,
                voice_filename TEXT,
                voice_originalname TEXT,
                voice_size INTEGER,
                voice_duration INTEGER
            )
        `;

        const createUsersTable = `
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT UNIQUE NOT NULL,
                status TEXT DEFAULT 'offline',
                last_seen DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        `;

        // استخدام serialize للتأكد من تنفيذ الأوامر بالتسلسل
        this.db.serialize(() => {
            // 1. إنشاء الجداول أولاً
            this.db.run(createMessagesTable, (err) => {
                if (err) console.error('Error creating messages table:', err);
            });

            this.db.run(createUsersTable, (err) => {
                if (err) {
                    console.error('Error creating users table:', err);
                    return;
                }
                
                // 2. حذف جميع المستخدمين الحاليين
                this.db.run('DELETE FROM users', (err) => {
                    if (err) {
                        console.error('Error deleting old users:', err);
                    } else {
                        console.log('All old users deleted');
                    }
                    
                    // 3. إضافة المستخدمين الجدد
                    this.initializeDefaultUsers();
                });
            });
        });
    }

    initializeDefaultUsers() {
        const defaultUsers = [
            { username: 'حسن', status: 'offline' },
            { username: 'حاتم', status: 'offline' },
            { username: 'مشاري', status: 'offline' }
        ];

        defaultUsers.forEach(user => {
            this.db.run(
                'INSERT INTO users (username, status) VALUES (?, ?)',
                [user.username, user.status],
                (err) => {
                    if (err) {
                        console.error('Error inserting user:', err);
                    } else {
                        console.log(`User added: ${user.username}`);
                    }
                }
            );
        });
    }

    // حفظ رسالة جديدة
    saveMessage(sender, message, hasVoice = false) {
        return new Promise((resolve, reject) => {
            this.db.run(
                'INSERT INTO messages (sender, message, has_voice) VALUES (?, ?, ?)',
                [sender, message, hasVoice ? 1 : 0],
                function(err) {
                    if (err) {
                        reject(err);
                    } else {
                        resolve(this.lastID);
                    }
                }
            );
        });
    }

    // حفظ رسالة صوتية
    saveVoiceMessage(sender, voiceFile, duration) {
        return new Promise((resolve, reject) => {
            this.db.run(
                `INSERT INTO messages 
                 (sender, message, has_voice, voice_filename, voice_originalname, voice_size, voice_duration) 
                 VALUES (?, ?, ?, ?, ?, ?, ?)`,
                [
                    sender,
                    '🎤 رسالة صوتية',
                    1,
                    voiceFile.filename,
                    voiceFile.originalname,
                    voiceFile.size,
                    duration
                ],
                function(err) {
                    if (err) {
                        reject(err);
                    } else {
                        resolve(this.lastID);
                    }
                }
            );
        });
    }

    // جلب جميع الرسائل
    getAllMessages() {
        return new Promise((resolve, reject) => {
            this.db.all(
                `SELECT id, sender, message, 
                        datetime(timestamp, "localtime") as timestamp,
                        has_voice, voice_filename, voice_originalname, 
                        voice_size, voice_duration
                 FROM messages 
                 ORDER BY timestamp ASC`,
                (err, rows) => {
                    if (err) {
                        reject(err);
                    } else {
                        resolve(rows);
                    }
                }
            );
        });
    }

    // تحديث حالة المستخدم
    updateUserStatus(username, status) {
        return new Promise((resolve, reject) => {
            this.db.run(
                'UPDATE users SET status = ?, last_seen = CURRENT_TIMESTAMP WHERE username = ?',
                [status, username],
                (err) => {
                    if (err) {
                        reject(err);
                    } else {
                        resolve(true);
                    }
                }
            );
        });
    }

    // جلب معلومات المستخدمين
    getAllUsers() {
        return new Promise((resolve, reject) => {
            this.db.all(
                'SELECT username, status, datetime(last_seen, "localtime") as last_seen FROM users ORDER BY username ASC',
                (err, rows) => {
                    if (err) {
                        reject(err);
                    } else {
                        resolve(rows);
                    }
                }
            );
        });
    }

    // جلب آخر 50 رسالة
    getRecentMessages() {
        return new Promise((resolve, reject) => {
            this.db.all(
                `SELECT id, sender, message, 
                        datetime(timestamp, "localtime") as timestamp,
                        has_voice, voice_filename, voice_originalname, 
                        voice_size, voice_duration
                 FROM messages 
                 ORDER BY timestamp DESC 
                 LIMIT 50`,
                (err, rows) => {
                    if (err) {
                        reject(err);
                    } else {
                        resolve(rows.reverse()); // لإعادة الترتيب من الأقدم للأحدث
                    }
                }
            );
        });
    }

    close() {
        this.db.close();
    }
}

module.exports = new Database();
