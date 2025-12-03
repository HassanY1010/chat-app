const sqlite3 = require('sqlite3').verbose();
const path = require('path');

class Database {
    constructor() {
        // تعديل مسار قاعدة البيانات ليعمل على Render داخل مجلد /data
        const dbPath = path.join(process.cwd(), 'data', 'chat.db');

        this.db = new sqlite3.Database(dbPath, (err) => {
            if (err) {
                console.error('Error opening database:', err);
            } else {
                console.log(`✅ Connected to SQLite database at: ${dbPath}`);
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
                if (err) {
                    console.error('❌ Error creating messages table:', err);
                } else {
                    console.log('✅ Messages table created/checked');
                    
                    // 2. التحقق من وإضافة الأعمدة المفقودة
                    this.checkAndAddColumns();
                }
            });

            this.db.run(createUsersTable, (err) => {
                if (err) {
                    console.error('❌ Error creating users table:', err);
                    return;
                }
                console.log('✅ Users table created/checked');
                
                // 3. حذف جميع المستخدمين الحاليين
                this.db.run('DELETE FROM users', (err) => {
                    if (err) {
                        console.error('❌ Error deleting old users:', err);
                    } else {
                        console.log('✅ All old users deleted');

                        // 4. إضافة المستخدمين الجدد
                        this.initializeDefaultUsers();
                    }
                });
            });
        });
    }

    // التحقق من وإضافة الأعمدة المفقودة
    checkAndAddColumns() {
        console.log('🔍 Checking for missing columns...');
        
        const columnsToCheck = [
            { name: 'has_voice', type: 'INTEGER DEFAULT 0' },
            { name: 'voice_filename', type: 'TEXT' },
            { name: 'voice_originalname', type: 'TEXT' },
            { name: 'voice_size', type: 'INTEGER' },
            { name: 'voice_duration', type: 'INTEGER' }
        ];

        this.db.all('PRAGMA table_info(messages);', (err, columns) => {
            if (err) {
                console.error('❌ Error checking table structure:', err);
                return;
            }

            const existingColumns = columns.map(col => col.name);
            console.log('📋 Existing columns:', existingColumns);

            let columnsAdded = 0;
            
            columnsToCheck.forEach(column => {
                if (!existingColumns.includes(column.name)) {
                    const addColumnSQL = `ALTER TABLE messages ADD COLUMN ${column.name} ${column.type};`;
                    
                    this.db.run(addColumnSQL, (err) => {
                        if (err) {
                            console.error(`❌ Error adding column ${column.name}:`, err);
                        } else {
                            console.log(`✅ Column ${column.name} added successfully`);
                            columnsAdded++;
                            
                            if (columnsAdded === columnsToCheck.length) {
                                console.log('🎉 All missing columns have been added');
                            }
                        }
                    });
                } else {
                    console.log(`✅ Column ${column.name} already exists`);
                }
            });
            
            if (columnsToCheck.every(col => existingColumns.includes(col.name))) {
                console.log('✅ All required columns are present');
            }
        });
    }

    initializeDefaultUsers() {
        const defaultUsers = [
            { username: 'حسن', status: 'online' },
            { username: 'حاتم', status: 'online' },
            { username: 'مشاري', status: 'online' }
        ];

        let insertedCount = 0;
        const totalUsers = defaultUsers.length;

        defaultUsers.forEach(user => {
            this.db.run(
                'INSERT OR REPLACE INTO users (username, status) VALUES (?, ?)',
                [user.username, user.status],
                (err) => {
                    if (err) {
                        console.error('❌ Error inserting user:', err);
                    } else {
                        insertedCount++;
                        console.log(`✅ User added: ${user.username} (${insertedCount}/${totalUsers})`);
                        
                        if (insertedCount === totalUsers) {
                            console.log('🎉 All default users initialized successfully');
                            this.testDatabaseConnection();
                        }
                    }
                }
            );
        });
    }

    // اختبار اتصال قاعدة البيانات
    testDatabaseConnection() {
        console.log('🔧 Testing database connection...');
        
        // اختبار استعلام بسيط
        this.db.get('SELECT COUNT(*) as count FROM messages', (err, row) => {
            if (err) {
                console.error('❌ Database test failed:', err);
            } else {
                console.log(`✅ Database test passed. Total messages: ${row.count}`);
            }
        });
        
        // اختبار هيكل الجدول
        this.db.all('PRAGMA table_info(messages)', (err, columns) => {
            if (err) {
                console.error('❌ Failed to get table info:', err);
            } else {
                console.log('📊 Table structure:');
                columns.forEach(col => {
                    console.log(`   - ${col.name} (${col.type})`);
                });
            }
        });
    }

    // حفظ رسالة جديدة
    saveMessage(sender, message, hasVoice = false) {
        return new Promise((resolve, reject) => {
            const sql = hasVoice 
                ? `INSERT INTO messages (sender, message, has_voice) VALUES (?, ?, ?)`
                : `INSERT INTO messages (sender, message) VALUES (?, ?)`;
            
            const params = hasVoice 
                ? [sender, message, hasVoice ? 1 : 0]
                : [sender, message];

            this.db.run(sql, params, function(err) {
                if (err) {
                    console.error('❌ Error saving message:', err);
                    reject(err);
                } else {
                    console.log(`✅ Message saved: ${sender} - "${message.substring(0, 30)}${message.length > 30 ? '...' : ''}" (ID: ${this.lastID})`);
                    resolve(this.lastID);
                }
            });
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
                    voiceFile.size || 0,
                    duration || 0
                ],
                function(err) {
                    if (err) {
                        console.error('❌ Error saving voice message:', err);
                        reject(err);
                    } else {
                        console.log(`✅ Voice message saved: ${sender} - ${voiceFile.filename} (ID: ${this.lastID})`);
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
                        console.error('❌ Error fetching all messages:', err);
                        reject(err);
                    } else {
                        console.log(`✅ Fetched ${rows.length} messages`);
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
                function(err) {
                    if (err) {
                        console.error('❌ Error updating user status:', err);
                        reject(err);
                    } else {
                        console.log(`✅ User status updated: ${username} -> ${status}`);
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
                        console.error('❌ Error fetching users:', err);
                        reject(err);
                    } else {
                        console.log(`✅ Fetched ${rows.length} users`);
                        resolve(rows);
                    }
                }
            );
        });
    }

    // جلب آخر 50 رسالة (مع التعامل مع الأعمدة المفقودة)
    getRecentMessages() {
        return new Promise((resolve, reject) => {
            // أولاً، تحقق من هيكل الجدول
            this.db.all('PRAGMA table_info(messages)', (err, columns) => {
                if (err) {
                    console.error('❌ Error getting table info:', err);
                    reject(err);
                    return;
                }

                const existingColumns = columns.map(col => col.name);
                
                // بناء الاستعلام بناءً على الأعمدة الموجودة
                const selectColumns = [
                    'id', 'sender', 'message',
                    'datetime(timestamp, "localtime") as timestamp',
                    'has_voice'
                ];

                // إضافة الأعمدة الاختيارية إذا كانت موجودة
                if (existingColumns.includes('voice_filename')) {
                    selectColumns.push('voice_filename');
                }
                if (existingColumns.includes('voice_originalname')) {
                    selectColumns.push('voice_originalname');
                }
                if (existingColumns.includes('voice_size')) {
                    selectColumns.push('voice_size');
                }
                if (existingColumns.includes('voice_duration')) {
                    selectColumns.push('voice_duration');
                }

                const sql = `SELECT ${selectColumns.join(', ')}
                             FROM messages 
                             ORDER BY timestamp DESC 
                             LIMIT 50`;

                console.log('📝 Executing query:', sql.substring(0, 100) + '...');

                this.db.all(sql, (err, rows) => {
                    if (err) {
                        console.error('❌ Error fetching recent messages:', err);
                        reject(err);
                    } else {
                        console.log(`✅ Fetched ${rows.length} recent messages`);
                        
                        // تأكد من وجود القيم الافتراضية للأعمدة المفقودة
                        const completeRows = rows.map(row => ({
                            ...row,
                            voice_filename: row.voice_filename || null,
                            voice_originalname: row.voice_originalname || null,
                            voice_size: row.voice_size || 0,
                            voice_duration: row.voice_duration || 0
                        }));
                        
                        resolve(completeRows.reverse()); // لإعادة الترتيب من الأقدم للأحدث
                    }
                });
            });
        });
    }

    // إغلاق الاتصال
    close() {
        this.db.close();
        console.log('✅ Database connection closed');
    }
}

module.exports = new Database();
