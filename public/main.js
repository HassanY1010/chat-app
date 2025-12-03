// متغيرات عامة
let socket;
let selectedUser = null;
let isConnected = false;

// قائمة الإيموجي الشائعة
const emojiList = [
    '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😊', '😇',
    '🙂', '🙃', '😉', '😌', '😍', '🥰', '😘', '😗', '😙', '😚',
    '😋', '😛', '😝', '😜', '🤪', '🤨', '🧐', '🤓', '😎', '🥸',
    '🤩', '🥳', '😏', '😒', '😞', '😔', '😟', '😕', '🙁', '☹️',
    '😣', '😖', '😫', '😩', '🥺', '😢', '😭', '😤', '😠', '😡',
    '🤬', '🤯', '😳', '🥵', '🥶', '😱', '😨', '😰', '😥', '😓',
    '🤗', '🤔', '🤭', '🤫', '🤥', '😶', '😐', '😑', '😬', '🙄',
    '😯', '😦', '😧', '😮', '😲', '🥱', '😴', '🤤', '😪', '😵',
    '🤐', '🥴', '🤢', '🤮', '🤧', '😷', '🤒', '🤕', '🤑', '🤠',
    '😈', '👿', '👹', '👺', '🤡', '💩', '👻', '💀', '☠️', '👽',
    '👾', '🤖', '🎃', '😺', '😸', '😹', '😻', '😼', '😽', '🙀',
    '😿', '😾', '🤲', '👐', '🙌', '👏', '🤝', '👍', '👎', '👊',
    '✊', '🤛', '🤜', '🤞', '✌️', '🤟', '🤘', '👌', '🤏', '👈',
    '👉', '👆', '👇', '☝️', '✋', '🤚', '🖐', '🖖', '👋', '🤙',
    '💪', '🦵', '🦶', '👂', '🦻', '👃', '🧠', '🦷', '🦴', '👀',
    '👁', '👅', '👄', '💋', '🩸', '❤️', '🧡', '💛', '💚', '💙',
    '💜', '🖤', '🤍', '🤎', '💔', '❤️‍🔥', '❤️‍🩹', '❣️', '💕', '💞',
    '💓', '💗', '💖', '💘', '💝', '💟', '☮️', '✝️', '☪️', '🕉',
    '☸️', '✡️', '🔯', '🕎', '☯️', '☦️', '🛐', '⛎', '♈', '♉',
    '♊', '♋', '♌', '♍', '♎', '♏', '♐', '♑', '♒', '♓',
    '🆔', '⚛️', '🉑', '☢️', '☣️', '📴', '📳', '🈶', '🈚', '🈸',
    '🈺', '🈷️', '✴️', '🆚', '💮', '🉐', '㊙️', '㊗️', '🈴', '🈵',
    '🈹', '🈲', '🅰️', '🅱️', '🆎', '🆑', '🅾️', '🆘', '❌', '⭕',
    '🛑', '⛔', '📛', '🚫', '💯', '💢', '♨️', '🚷', '🚯', '🚳',
    '🚱', '🔞', '📵', '🚭', '❗', '❕', '❓', '❔', '‼️', '⁉️',
    '🔅', '🔆', '〽️', '⚠️', '🚸', '🔱', '⚜️', '🔰', '♻️', '✅',
    '🈯', '💹', '❇️', '✳️', '❎', '🌐', '💠', 'Ⓜ️', '🌀', '💤',
    '🏧', '🚾', '♿', '🅿️', '🈳', '🈂️', '🛂', '🛃', '🛄', '🛅',
    '🚹', '🚺', '🚼', '⚧', '🚻', '🚮', '🎦', '📶', '🈁', '🔣',
    'ℹ️', '🔤', '🔡', '🔠', '🆖', '🆗', '🆙', '🆒', '🆕', '🆓',
    '0️⃣', '1️⃣', '2️⃣', '3️⃣', '4️⃣', '5️⃣', '6️⃣', '7️⃣', '8️⃣', '9️⃣',
    '🔟', '🔢', '#️⃣', '*️⃣', '⏏️', '▶️', '⏸', '⏯', '⏹', '⏺',
    '⏭', '⏮', '⏩', '⏪', '⏫', '⏬', '◀️', '🔼', '🔽', '➡️',
    '⬅️', '⬆️', '⬇️', '↗️', '↘️', '↙️', '↖️', '↕️', '↔️', '↪️',
    '↩️', '⤴️', '⤵️', '🔀', '🔁', '🔂', '🔄', '🔃', '🎵', '🎶',
    '➕', '➖', '➗', '✖️', '♾', '💲', '💱', '™️', '©️', '®️',
    '〰️', '➰', '➿', '🔚', '🔙', '🔛', '🔝', '🔜', '✔️', '☑️',
    '🔘', '🔴', '🟠', '🟡', '🟢', '🔵', '🟣', '⚫', '⚪', '🟤',
    '🔺', '🔻', '🔸', '🔹', '🔶', '🔷', '🟧', '🟨', '🟩', '🟦',
    '🟪', '⬛', '⬜', '🟫', '🔈', '🔇', '🔉', '🔊', '🔔', '🔕',
    '📣', '📢', '👁‍🗨', '💬', '💭', '🗯', '♠️', '♣️', '♥️', '♦️',
    '🃏', '🎴', '🀄', '🕐', '🕑', '🕒', '🕓', '🕔', '🕕', '🕖',
    '🕗', '🕘', '🕙', '🕚', '🕛', '🕜', '🕝', '🕞', '🕟', '🕠',
    '🕡', '🕢', '🕣', '🕤', '🕥', '🕦', '🕧'
];

// الاتصال بالسيرفر
function connectToServer() {
    socket = io();
    
    socket.on('connect', () => {
        console.log('Connected to server');
        updateConnectionStatus(true);
        isConnected = true;
    });
    
    socket.on('disconnect', () => {
        console.log('Disconnected from server');
        updateConnectionStatus(false);
        isConnected = false;
    });
    
    socket.on('initial_data', (data) => {
        console.log('Received initial data:', data);
        renderUsers(data.users);
        renderMessages(data.messages);
        
        // تمكين مربع الإدخال إذا كان هناك مستخدم محدد
        if (selectedUser) {
            enableMessageInput();
        }
    });
    
    socket.on('new_message', (message) => {
        addMessageToChat(message);
        scrollToBottom();
    });
    
    socket.on('users_update', (users) => {
        renderUsers(users);
    });
    
    socket.on('error', (errorMsg) => {
        showError(errorMsg);
    });
}

// تحديث حالة الاتصال
function updateConnectionStatus(connected) {
    const statusElement = document.getElementById('connection-status');
    const statusDot = statusElement.querySelector('.h-3');
    const statusText = statusElement.querySelector('span:last-child');
    
    if (connected) {
        statusDot.classList.remove('bg-red-500');
        statusDot.classList.add('bg-green-500');
        statusText.textContent = 'متصل';
        statusText.classList.remove('text-gray-600');
        statusText.classList.add('text-green-600');
    } else {
        statusDot.classList.remove('bg-green-500');
        statusDot.classList.add('bg-red-500');
        statusText.textContent = 'غير متصل';
        statusText.classList.remove('text-green-600');
        statusText.classList.add('text-gray-600');
    }
}

// عرض قائمة المستخدمين
function renderUsers(users) {
    const usersList = document.getElementById('users-list');
    usersList.innerHTML = '';
    
    users.forEach(user => {
        const userElement = document.createElement('div');
        userElement.className = 'flex items-center justify-between p-3 rounded-lg border';
        
        const statusColor = user.status === 'online' ? 'bg-green-500' : 'bg-gray-400';
        
        userElement.innerHTML = `
            <div class="flex items-center">
                <div class="h-10 w-10 rounded-full flex items-center justify-center ${getUserColorClass(user.username)} text-white font-semibold">
                    ${user.username.charAt(0)}
                </div>
                <div class="mr-3">
                    <div class="font-semibold text-gray-800">${user.username}</div>
                    <div class="text-xs text-gray-500">${user.last_seen}</div>
                </div>
            </div>
            <div class="flex items-center">
                <div class="h-3 w-3 ${statusColor} rounded-full ml-2"></div>
                <span class="text-sm ${user.status === 'online' ? 'text-green-600' : 'text-gray-500'}">
                    ${user.status === 'online' ? 'متصل' : 'غير متصل'}
                </span>
            </div>
        `;
        
        usersList.appendChild(userElement);
    });
}

// عرض الرسائل
function renderMessages(messages) {
    const chatMessages = document.getElementById('chat-messages');
    chatMessages.innerHTML = '';
    
    if (messages.length === 0) {
        chatMessages.innerHTML = `
            <div class="text-center text-gray-500 my-8">
                <i class="fas fa-comments text-3xl mb-2"></i>
                <p>لا توجد رسائل بعد. ابدأ المحادثة!</p>
            </div>
        `;
        return;
    }
    
    messages.forEach(message => {
        addMessageToChat(message, false);
    });
    
    scrollToBottom();
}

// إضافة رسالة جديدة للدردشة
function addMessageToChat(message, animate = true) {
    const chatMessages = document.getElementById('chat-messages');
    
    // إزالة رسالة "جارٍ تحميل الرسائل" إذا كانت موجودة
    const loadingMsg = chatMessages.querySelector('.text-center');
    if (loadingMsg) {
        loadingMsg.remove();
    }
    
    const messageElement = document.createElement('div');
    messageElement.className = `mb-4 ${animate ? 'message-enter' : ''}`;
    
    const isCurrentUser = message.sender === selectedUser;
    const alignmentClass = isCurrentUser ? 'items-end' : 'items-start';
    const bgColorClass = isCurrentUser ? 'bg-blue-100' : 'bg-gray-100';
    
    messageElement.innerHTML = `
        <div class="flex flex-col ${alignmentClass}">
            <div class="flex items-center mb-1 ${isCurrentUser ? 'flex-row-reverse' : ''}">
                <div class="h-8 w-8 rounded-full flex items-center justify-center ${getUserColorClass(message.sender)} text-white text-xs font-bold ml-2">
                    ${message.sender.charAt(0)}
                </div>
                <span class="font-semibold text-sm ${isCurrentUser ? 'text-blue-700' : 'text-gray-700'}">${message.sender}</span>
                <span class="text-xs text-gray-500 mx-2">${message.timestamp}</span>
            </div>
            <div class="${bgColorClass} p-3 rounded-2xl max-w-xs lg:max-w-md ${isCurrentUser ? 'rounded-tr-none' : 'rounded-tl-none'}">
                <p class="text-gray-800 emoji-support">${message.message}</p>
            </div>
        </div>
    `;
    
    chatMessages.appendChild(messageElement);
}

// اختيار المستخدم
function selectUser(username) {
    if (selectedUser === username) return;
    
    // تحديث أزرار المستخدمين
    document.querySelectorAll('.user-btn').forEach(btn => {
        btn.classList.remove('selected-user');
        btn.classList.add('opacity-80');
    });
    
    const selectedBtn = document.querySelector(`button[onclick="selectUser('${username}')"]`);
    selectedBtn.classList.add('selected-user');
    selectedBtn.classList.remove('opacity-80');
    
    selectedUser = username;
    document.getElementById('selected-user-display').textContent = username;
    
    // تسجيل دخول المستخدم
    if (socket && isConnected) {
        socket.emit('user_login', username);
        enableMessageInput();
    }
}

// تمكين إدخال الرسائل
function enableMessageInput() {
    const messageInput = document.getElementById('message-input');
    const sendBtn = document.getElementById('send-btn');
    const emojiToggle = document.getElementById('emoji-toggle');
    
    messageInput.disabled = false;
    messageInput.placeholder = `اكتب رسالتك كـ ${selectedUser}...`;
    sendBtn.disabled = false;
    emojiToggle.disabled = false;
    
    messageInput.focus();
}

// إرسال رسالة
function sendMessage() {
    const messageInput = document.getElementById('message-input');
    const message = messageInput.value.trim();
    
    if (!message || !selectedUser || !socket || !isConnected) return;
    
    // إرسال الرسالة عبر Socket.IO
    socket.emit('send_message', {
        sender: selectedUser,
        message: message
    });
    
    // مسح حقل الإدخال
    messageInput.value = '';
    
    // إعادة التركيز على حقل الإدخال
    messageInput.focus();
}

// التمرير لأسفل
function scrollToBottom() {
    const chatMessages = document.getElementById('chat-messages');
    chatMessages.scrollTop = chatMessages.scrollHeight;
}

// عرض رسالة خطأ
function showError(message) {
    alert(`خطأ: ${message}`);
}

// الحصول على لون المستخدم
function getUserColorClass(username) {
    switch(username) {
        case 'حسن': return 'bg-red-500';
        case 'حاتم': return 'bg-green-500';
        case 'مشاري': return 'bg-purple-500';
        default: return 'bg-blue-500';
    }
}

// تهيئة الإيموجي
function initializeEmojiPicker() {
    const emojiGrid = document.getElementById('emoji-grid');
    if (!emojiGrid) return;
    
    // إضافة الإيموجي إلى الشبكة
    emojiList.forEach(emoji => {
        const emojiButton = document.createElement('button');
        emojiButton.type = 'button';
        emojiButton.className = 'emoji-btn text-xl p-2 hover:bg-gray-100 rounded-lg transition-colors focus:outline-none focus:ring-2 focus:ring-blue-300';
        emojiButton.textContent = emoji;
        emojiButton.title = emoji;
        emojiButton.setAttribute('aria-label', `إيموجي ${emoji}`);
        emojiButton.addEventListener('click', () => {
            insertEmoji(emoji);
        });
        emojiGrid.appendChild(emojiButton);
    });
}

// إدراج الإيموجي في حقل النص
function insertEmoji(emoji) {
    const messageInput = document.getElementById('message-input');
    if (!messageInput || messageInput.disabled) return;
    
    const currentPosition = messageInput.selectionStart;
    const currentValue = messageInput.value;
    
    // إدراج الإيموجي في الموقع الحالي
    messageInput.value = currentValue.substring(0, currentPosition) + 
                        emoji + 
                        currentValue.substring(currentPosition);
    
    // تحديث موضع المؤشر
    const newPosition = currentPosition + emoji.length;
    messageInput.selectionStart = messageInput.selectionEnd = newPosition;
    
    // إعادة التركيز على حقل النص
    messageInput.focus();
    
    // إغلاق قائمة الإيموجي بعد الإدراج
    const emojiPicker = document.getElementById('emoji-picker');
    if (emojiPicker) {
        emojiPicker.classList.add('hidden');
    }
}

// التحكم في فتح وإغلاق قائمة الإيموجي
function setupEmojiPicker() {
    const emojiToggle = document.getElementById('emoji-toggle');
    const emojiPicker = document.getElementById('emoji-picker');
    const closeEmoji = document.getElementById('close-emoji');
    
    if (!emojiToggle || !emojiPicker) return;
    
    // تعطيل زر الإيموجي في البداية
    emojiToggle.disabled = true;
    
    // فتح/إغلاق قائمة الإيموجي
    emojiToggle.addEventListener('click', (e) => {
        e.stopPropagation();
        emojiPicker.classList.toggle('hidden');
        
        // إذا تم فتح قائمة الإيموجي، أضف حدث لإغلاقها عند الضغط على Esc
        if (!emojiPicker.classList.contains('hidden')) {
            const handleEscKey = (event) => {
                if (event.key === 'Escape') {
                    emojiPicker.classList.add('hidden');
                    document.removeEventListener('keydown', handleEscKey);
                }
            };
            document.addEventListener('keydown', handleEscKey);
        }
    });
    
    // إغلاق قائمة الإيموجي
    if (closeEmoji) {
        closeEmoji.addEventListener('click', () => {
            emojiPicker.classList.add('hidden');
        });
    }
    
    // إغلاق قائمة الإيموجي عند النقر خارجها
    document.addEventListener('click', (e) => {
        if (!emojiPicker.contains(e.target) && !emojiToggle.contains(e.target)) {
            emojiPicker.classList.add('hidden');
        }
    });
}

// تهيئة التطبيق عند تحميل الصفحة
function initializeApp() {
    connectToServer();
    
    // ربط حدث الإرسال بالزر
    document.getElementById('send-btn').addEventListener('click', sendMessage);
    
    // السماح بإرسال الرسالة بالضغط على Enter
    document.getElementById('message-input').addEventListener('keypress', (e) => {
        if (e.key === 'Enter') {
            sendMessage();
        }
    });
    
    // السماح باستخدام Ctrl+Enter لإرسال الرسالة
    document.getElementById('message-input').addEventListener('keydown', (e) => {
        if (e.key === 'Enter' && e.ctrlKey) {
            sendMessage();
        }
    });
    
    // تعيين الألوان لأزرار المستخدمين
    document.querySelectorAll('.user-btn').forEach(btn => {
        const username = btn.textContent.trim();
        if (username === 'حسن') btn.classList.add('bg-red-100', 'hover:bg-red-200', 'text-red-800');
        if (username === 'حاتم') btn.classList.add('bg-green-100', 'hover:bg-green-200', 'text-green-800');
        if (username === 'مشاري') btn.classList.add('bg-purple-100', 'hover:bg-purple-200', 'text-purple-800');
        btn.classList.add('opacity-80');
    });
    
    // تهيئة الإيموجي
    initializeEmojiPicker();
    setupEmojiPicker();
    
    // إضافة وظيفة البحث في الإيموجي
    setupEmojiSearch();
}

// إضافة وظيفة البحث في الإيموجي
function setupEmojiSearch() {
    const emojiSearchInput = document.getElementById('emoji-search');
    if (!emojiSearchInput) return;
    
    emojiSearchInput.addEventListener('input', (e) => {
        const searchTerm = e.target.value.toLowerCase();
        const emojiButtons = document.querySelectorAll('.emoji-btn');
        
        emojiButtons.forEach(button => {
            const emoji = button.textContent;
            if (searchTerm === '' || emoji.includes(searchTerm)) {
                button.style.display = 'block';
            } else {
                button.style.display = 'none';
            }
        });
    });
}

// بدء التطبيق عند تحميل الصفحة
document.addEventListener('DOMContentLoaded', initializeApp);