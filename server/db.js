const sqlite3 = require('sqlite3').verbose();
const path = require('path');

class Database {
    constructor() {

        // 👈 تحديد المسار الصحيح لملف SQLite في جذر المشروع
        const dbPath = path.join(__dirname, '../chat.db');

        this.db = new sqlite3.Database(dbPath, (err) => {
            if (err) {
                console.error('Error opening database:', err);
            } else {
                console.log('Connected to SQLite database');
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
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
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

        this.db.serialize(() => {
            this.db.run(createMessagesTable, (err) => {
                if (err) console.error('Error creating messages table:', err);
            });

            this.db.run(createUsersTable, (err) => {
                if (err) {
                    console.error('Error creating users table:', err);
                    return;
                }

                this.db.run('DELETE FROM users', (err) => {
                    if (err) {
                        console.error('Error deleting old users:', err);
                    } else {
                        console.log('All old users deleted');
                    }

                    this.initializeDefaultUsers();
                });
            });
        });
    }

    deleteOldUsersMessages() {
        return new Promise((resolve, reject) => {
            this.db.run(
                "DELETE FROM messages WHERE sender IN ('User1', 'User2', 'User3')",
                (err) => {
                    if (err) {
                        console.error('Error deleting old messages:', err);
                        reject(err);
                    } else {
                        console.log('Old messages from previous users deleted');
                        resolve();
                    }
                }
            );
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

    saveMessage(sender, message) {
        return new Promise((resolve, reject) => {
            this.db.run(
                'INSERT INTO messages (sender, message) VALUES (?, ?)',
                [sender, message],
                function (err) {
                    if (err) {
                        reject(err);
                    } else {
                        resolve(this.lastID);
                    }
                }
            );
        });
    }

    getAllMessages() {
        return new Promise((resolve, reject) => {
            this.db.all(
                'SELECT id, sender, message, datetime(timestamp, "localtime") as timestamp FROM messages ORDER BY timestamp ASC',
                (err, rows) => {
                    if (err) reject(err);
                    else resolve(rows);
                }
            );
        });
    }

    updateUserStatus(username, status) {
        return new Promise((resolve, reject) => {
            this.db.run(
                'UPDATE users SET status = ?, last_seen = CURRENT_TIMESTAMP WHERE username = ?',
                [status, username],
                (err) => {
                    if (err) reject(err);
                    else resolve(true);
                }
            );
        });
    }

    getAllUsers() {
        return new Promise((resolve, reject) => {
            this.db.all(
                'SELECT username, status, datetime(last_seen, "localtime") as last_seen FROM users ORDER BY username ASC',
                (err, rows) => {
                    if (err) reject(err);
                    else resolve(rows);
                }
            );
        });
    }

    getRecentMessages() {
        return new Promise((resolve, reject) => {
            this.db.all(
                `SELECT id, sender, message, datetime(timestamp, "localtime") as timestamp 
                 FROM messages 
                 ORDER BY timestamp DESC 
                 LIMIT 50`,
                (err, rows) => {
                    if (err) reject(err);
                    else resolve(rows.reverse());
                }
            );
        });
    }

    clearAllData() {
        return new Promise((resolve, reject) => {
            this.db.serialize(() => {
                this.db.run('DELETE FROM messages', (err) => {
                    if (err) {
                        console.error('Error clearing messages:', err);
                        reject(err);
                    } else {
                        console.log('All messages cleared');
                    }
                });

                this.db.run('DELETE FROM users', (err) => {
                    if (err) {
                        console.error('Error clearing users:', err);
                        reject(err);
                    } else {
                        console.log('All users cleared');
                        this.initializeDefaultUsers();
                        resolve();
                    }
                });
            });
        });
    }

    close() {
        this.db.close();
    }
}

module.exports = new Database();
