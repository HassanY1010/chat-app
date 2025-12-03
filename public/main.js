// متغيرات عامة
let socket;
let selectedUser = null;
let isConnected = false;
let mediaRecorder = null;
let audioChunks = [];
let recordingTimer = null;
let recordingSeconds = 0;
let isRecording = false;

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
    '♊', '♋', '♌', '♍', '♎', '♏', '♐', '♑', '♒', '♓'
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

        // تحديث الإحصائيات
        updateStatistics(data.messages);

        // تمكين مربع الإدخال إذا كان هناك مستخدم محدد
        if (selectedUser) {
            enableMessageInput();
        }
    });

    socket.on('new_message', (message) => {
        addMessageToChat(message);
        scrollToBottom();

        // تحديث الإحصائيات
        incrementMessageCount();
        if (message.has_voice) {
            incrementVoiceCount();
        }

        // تشغيل الصوت إذا كان رسالة صوتية
        if (message.has_voice && !isRecording) {
            playNotificationSound();
        }
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
    if (!statusElement) return;
    
    const statusDot = statusElement.querySelector('.h-3, .h-2') || statusElement.querySelector('div');
    const statusText = statusElement.querySelector('span:last-child');

    if (connected) {
        if (statusDot) {
            statusDot.classList.remove('bg-red-400', 'bg-red-500');
            statusDot.classList.add('bg-green-500');
        }
        if (statusText) {
            statusText.textContent = 'متصل';
            statusText.classList.remove('text-gray-600');
            statusText.classList.add('text-green-600');
        }
    } else {
        if (statusDot) {
            statusDot.classList.remove('bg-green-500');
            statusDot.classList.add('bg-red-400', 'bg-red-500');
        }
        if (statusText) {
            statusText.textContent = 'غير متصل';
            statusText.classList.remove('text-green-600');
            statusText.classList.add('text-gray-600');
        }
    }
}

// عرض قائمة المستخدمين
function renderUsers(users) {
    const usersList = document.getElementById('users-list');
    if (usersList) {
        usersList.innerHTML = '';

        users.forEach(user => {
            const userElement = document.createElement('div');
            userElement.className = 'flex items-center justify-between p-3 rounded-lg border border-gray-200 bg-white/50';

            const statusColor = user.status === 'online' ? 'bg-green-500' : 'bg-gray-400';

            userElement.innerHTML = `
                <div class="flex items-center">
                    <div class="h-10 w-10 rounded-full flex items-center justify-center ${getUserColorClass(user.username)} text-white font-semibold">
                        ${user.username.charAt(0)}
                    </div>
                    <div class="mr-3">
                        <div class="font-semibold text-gray-800">${user.username}</div>
                        <div class="text-xs text-gray-500">آخر ظهور: ${user.last_seen}</div>
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
    
    // تحديث قائمة المستخدمين للجوال
    const mobileUsersList = document.getElementById('mobile-users-list');
    if (mobileUsersList) {
        mobileUsersList.innerHTML = '';
        
        users.forEach(user => {
            const userElement = document.createElement('div');
            userElement.className = 'flex items-center justify-between p-3 rounded-lg border border-gray-200 bg-white/50';

            const statusColor = user.status === 'online' ? 'bg-green-500' : 'bg-gray-400';

            userElement.innerHTML = `
                <div class="flex items-center">
                    <div class="h-10 w-10 rounded-full flex items-center justify-center ${getUserColorClass(user.username)} text-white font-semibold">
                        ${user.username.charAt(0)}
                    </div>
                    <div class="mr-3">
                        <div class="font-semibold text-gray-800">${user.username}</div>
                        <div class="text-xs text-gray-500">آخر ظهور: ${user.last_seen}</div>
                    </div>
                </div>
                <div class="flex items-center">
                    <div class="h-3 w-3 ${statusColor} rounded-full ml-2"></div>
                    <span class="text-sm ${user.status === 'online' ? 'text-green-600' : 'text-gray-500'}">
                        ${user.status === 'online' ? 'متصل' : 'غير متصل'}
                    </span>
                </div>
            `;

            mobileUsersList.appendChild(userElement);
        });
    }
}

// عرض الرسائل
function renderMessages(messages) {
    const chatMessages = document.getElementById('chat-messages');
    if (!chatMessages) return;
    
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
    if (!chatMessages) return;

    // إزالة رسالة "جارٍ تحميل الرسائل" إذا كانت موجودة
    const loadingMsg = chatMessages.querySelector('.text-center');
    if (loadingMsg) {
        loadingMsg.remove();
    }

    const messageElement = document.createElement('div');
    messageElement.className = `mb-4 ${animate ? 'animate__animated animate__fadeInUp' : ''}`;

    const isCurrentUser = message.sender === selectedUser;
    const alignmentClass = isCurrentUser ? 'items-end' : 'items-start';
    const bgColorClass = isCurrentUser ? 'bg-blue-100 border-blue-200' : 'bg-gray-100 border-gray-200';

    // التحقق إذا كانت رسالة صوتية
    if (message.has_voice) {
        const voiceUrl = `/uploads/${message.voice_filename}`;
        const duration = message.voice_duration || 0;
        const durationText = formatDuration(duration);

        messageElement.innerHTML = `
            <div class="flex flex-col ${alignmentClass}">
                <div class="flex items-center mb-1 ${isCurrentUser ? 'flex-row-reverse' : ''}">
                    <div class="h-8 w-8 rounded-full flex items-center justify-center ${getUserColorClass(message.sender)} text-white text-xs font-bold ml-2">
                        ${message.sender.charAt(0)}
                    </div>
                    <span class="font-semibold text-sm ${isCurrentUser ? 'text-blue-700' : 'text-gray-700'}">${message.sender}</span>
                    <span class="text-xs text-gray-500 mx-2">${message.timestamp}</span>
                    <span class="text-xs ${isCurrentUser ? 'text-blue-600' : 'text-purple-600'}">
                        <i class="fas fa-microphone ml-1"></i>صوتي
                    </span>
                </div>
                <div class="${bgColorClass} p-4 rounded-2xl max-w-xs lg:max-w-md ${isCurrentUser ? 'rounded-tr-none' : 'rounded-tl-none'} border">
                    <div class="flex items-center justify-between mb-2">
                        <div class="flex items-center">
                            <div class="w-10 h-10 rounded-full bg-gradient-to-r from-red-500 to-pink-500 flex items-center justify-center mr-3">
                                <i class="fas fa-microphone text-white"></i>
                            </div>
                            <div>
                                <div class="font-medium text-gray-800">رسالة صوتية</div>
                                <div class="text-xs text-gray-600">${durationText} · ${formatFileSize(message.voice_size)}</div>
                            </div>
                        </div>
                        <button onclick="playVoiceMessage('${voiceUrl}', this)" class="play-voice-btn bg-gradient-to-r from-green-500 to-emerald-500 hover:from-green-600 hover:to-emerald-600 text-white p-2 rounded-full transition-all transform hover:scale-110">
                            <i class="fas fa-play"></i>
                        </button>
                    </div>
                    <div class="mt-2">
                        <audio id="audio-${message.id}" class="hidden" preload="metadata">
                            <source src="${voiceUrl}" type="${message.voice_filename.endsWith('.mp3') ? 'audio/mpeg' : 'audio/wav'}">
                            المتصفح لا يدود تشغيل الصوت.
                        </audio>
                        <div class="voice-player flex items-center space-x-2 space-x-reverse">
                            <button onclick="togglePlayPause('audio-${message.id}', this)" class="text-gray-600 hover:text-blue-600">
                                <i class="fas fa-play-circle text-lg"></i>
                            </button>
                            <div class="flex-grow bg-gray-200 rounded-full h-2">
                                <div class="bg-gradient-to-r from-blue-500 to-purple-500 h-2 rounded-full w-0" id="progress-${message.id}"></div>
                            </div>
                            <span class="text-xs text-gray-500" id="time-${message.id}">${durationText}</span>
                            <a href="${voiceUrl}" download="${message.voice_originalname}" class="text-gray-600 hover:text-green-600" title="تحميل">
                                <i class="fas fa-download"></i>
                            </a>
                        </div>
                    </div>
                    ${message.message && message.message !== '🎤 رسالة صوتية' ? `
                    <div class="mt-3 pt-3 border-t border-gray-300">
                        <p class="text-gray-700 text-sm"><i class="fas fa-comment ml-1"></i> ${message.message}</p>
                    </div>
                    ` : ''}
                </div>
            </div>
        `;
    } else {
        messageElement.innerHTML = `
            <div class="flex flex-col ${alignmentClass}">
                <div class="flex items-center mb-1 ${isCurrentUser ? 'flex-row-reverse' : ''}">
                    <div class="h-8 w-8 rounded-full flex items-center justify-center ${getUserColorClass(message.sender)} text-white text-xs font-bold ml-2">
                        ${message.sender.charAt(0)}
                    </div>
                    <span class="font-semibold text-sm ${isCurrentUser ? 'text-blue-700' : 'text-gray-700'}">${message.sender}</span>
                    <span class="text-xs text-gray-500 mx-2">${message.timestamp}</span>
                </div>
                <div class="${bgColorClass} p-3 rounded-2xl max-w-xs lg:max-w-md ${isCurrentUser ? 'rounded-tr-none' : 'rounded-tl-none'} border">
                    <p class="text-gray-800 emoji-support">${message.message}</p>
                </div>
            </div>
        `;
    }

    chatMessages.appendChild(messageElement);

    // تهيئة مشغلات الصوت
    if (message.has_voice) {
        initAudioPlayer(`audio-${message.id}`);
    }
}

// تشغيل رسالة صوتية
function playVoiceMessage(url, button) {
    const audio = new Audio(url);
    audio.play();

    button.innerHTML = '<i class="fas fa-pause"></i>';
    button.classList.remove('bg-gradient-to-r', 'from-green-500', 'to-emerald-500');
    button.classList.add('bg-gradient-to-r', 'from-yellow-500', 'to-orange-500');

    audio.onended = function () {
        button.innerHTML = '<i class="fas fa-play"></i>';
        button.classList.remove('bg-gradient-to-r', 'from-yellow-500', 'to-orange-500');
        button.classList.add('bg-gradient-to-r', 'from-green-500', 'to-emerald-500');
    };
}

// تبديل التشغيل/الإيقاف للصوت
function togglePlayPause(audioId, button) {
    const audio = document.getElementById(audioId);
    if (audio.paused) {
        audio.play();
        button.innerHTML = '<i class="fas fa-pause-circle text-lg"></i>';
    } else {
        audio.pause();
        button.innerHTML = '<i class="fas fa-play-circle text-lg"></i>';
    }
}

// تهيئة مشغل الصوت
function initAudioPlayer(audioId) {
    const audio = document.getElementById(audioId);
    const progress = document.getElementById(`progress-${audioId.replace('audio-', '')}`);
    const timeDisplay = document.getElementById(`time-${audioId.replace('audio-', '')}`);

    audio.addEventListener('timeupdate', function () {
        if (progress && timeDisplay) {
            const percent = (audio.currentTime / audio.duration) * 100;
            progress.style.width = percent + '%';

            const currentTime = formatTime(audio.currentTime);
            const duration = formatTime(audio.duration);
            timeDisplay.textContent = `${currentTime} / ${duration}`;
        }
    });

    audio.addEventListener('ended', function () {
        if (progress) {
            progress.style.width = '0%';
        }
        const playBtn = audio.parentElement.querySelector('.fa-play-circle');
        if (playBtn) {
            playBtn.classList.remove('fa-pause-circle');
            playBtn.classList.add('fa-play-circle');
        }
    });
}

// تنسيق الوقت
function formatTime(seconds) {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs < 10 ? '0' : ''}${secs}`;
}

// تنسيق المدة
function formatDuration(seconds) {
    if (!seconds) return '0:00';
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs < 10 ? '0' : ''}${secs}`;
}

// تنسيق حجم الملف
function formatFileSize(bytes) {
    if (bytes === 0) return '0 ب';
    const k = 1024;
    const sizes = ['ب', 'ك.ب', 'م.ب', 'ج.ب'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
}

// اختيار المستخدم
function selectUser(username) {
    if (selectedUser === username) return;

    // تحديث أزرار المستخدمين
    document.querySelectorAll('.user-select-btn').forEach(btn => {
        btn.classList.remove('border-2', 'border-blue-400', 'ring-2', 'ring-blue-200');
    });

    const selectedBtn = document.querySelector(`button[onclick="selectUser('${username}')"]`);
    if (selectedBtn) {
        selectedBtn.classList.add('border-2', 'border-blue-400', 'ring-2', 'ring-blue-200');
    }

    selectedUser = username;
    
    // تحديث عرض المستخدم المحدد
    updateSelectedUserDisplay();
    
    // تمكين حقل الإدخال والميزات
    enableMessageInput();
    
    // تسجيل دخول المستخدم عبر السيرفر
    if (socket && isConnected) {
        socket.emit('user_login', username);
    }
    
    // إغلاق نافذة الترحيب
    const welcomeModal = document.getElementById('welcome-modal');
    if (welcomeModal) {
        welcomeModal.classList.add('hidden');
    }
    
    // إغلاق القائمة الجانبية للجوال
    const mobileSidebar = document.getElementById('mobile-sidebar');
    if (mobileSidebar && window.innerWidth < 768) {
        mobileSidebar.classList.add('translate-x-full');
        document.body.style.overflow = 'auto';
    }
    
    // إظهار رسالة ترحيبية
    showSuccess(`تم اختيار ${username} بنجاح! يمكنك البدء بالدردشة الآن.`);
}

// تحديث عرض المستخدم المحدد
function updateSelectedUserDisplay() {
    const userAvatar = document.getElementById('user-avatar');
    const selectedUserDisplay = document.getElementById('selected-user-display');
    
    if (userAvatar && selectedUser) {
        userAvatar.textContent = selectedUser.charAt(0);
        userAvatar.className = 'w-8 h-8 lg:w-10 lg:h-10 rounded-full flex items-center justify-center text-white font-bold ml-3 ' + getUserColorClass(selectedUser);
    }
    
    if (selectedUserDisplay && selectedUser) {
        selectedUserDisplay.textContent = selectedUser;
        selectedUserDisplay.classList.add('text-blue-600');
    }
}

// تمكين إدخال الرسائل
function enableMessageInput() {
    const messageInput = document.getElementById('message-input');
    const sendBtn = document.getElementById('send-btn');
    const emojiToggle = document.getElementById('emoji-toggle');
    const voiceRecordBtn = document.getElementById('voice-record-btn');
    const emojiCategories = document.querySelectorAll('.emoji-category');
    const formatBtns = document.querySelectorAll('[onclick^="formatText"]');

    if (messageInput) {
        messageInput.disabled = false;
        messageInput.placeholder = `اكتب رسالتك كـ ${selectedUser}...`;
        messageInput.focus();
    }
    
    if (sendBtn) {
        sendBtn.disabled = false;
        sendBtn.classList.remove('opacity-50', 'cursor-not-allowed');
    }
    
    if (emojiToggle) {
        emojiToggle.disabled = false;
        emojiToggle.classList.remove('opacity-50', 'cursor-not-allowed');
    }
    
    if (voiceRecordBtn) {
        voiceRecordBtn.disabled = false;
        voiceRecordBtn.classList.remove('opacity-50', 'cursor-not-allowed');
    }
    
    // تمكين أزرار الإيموجي
    emojiCategories.forEach(btn => {
        btn.disabled = false;
    });
    
    // تمكين أزرار التنسيق
    formatBtns.forEach(btn => {
        btn.disabled = false;
    });
}

// بدء التسجيل الصوتي
async function startVoiceRecording() {
    if (!selectedUser) {
        showError('يجب اختيار مستخدم أولاً');
        return;
    }

    try {
        const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
        mediaRecorder = new MediaRecorder(stream);
        audioChunks = [];
        
        // إظهار واجهة التسجيل
        showRecordingUI();
        
        // بدء عداد التسجيل
        startRecordingTimer();
        
        // بدء التسجيل
        mediaRecorder.start();
        isRecording = true;

        mediaRecorder.ondataavailable = (event) => {
            audioChunks.push(event.data);
        };

        mediaRecorder.onstop = () => {
            const audioBlob = new Blob(audioChunks, { type: 'audio/webm' });
            stream.getTracks().forEach(track => track.stop());
            
            // إخفاء واجهة التسجيل
            hideRecordingUI();
            stopRecordingTimer();
            
            // عرض معاينة التسجيل
            showRecordingPreview(audioBlob);
            isRecording = false;
        };

    } catch (err) {
        console.error('Error starting recording:', err);
        showError('فشل في بدء التسجيل. يرجى التحقق من صلاحيات الميكروفون.');
    }
}

// إظهار واجهة التسجيل
function showRecordingUI() {
    const recordingContainer = document.getElementById('voice-recording-container');
    const messageInput = document.getElementById('message-input');
    const sendBtn = document.getElementById('send-btn');

    if (recordingContainer) {
        recordingContainer.classList.remove('hidden');
        recordingContainer.classList.add('animate__fadeIn');
    }
    
    if (messageInput) {
        messageInput.disabled = true;
    }
    
    if (sendBtn) {
        sendBtn.disabled = true;
    }
}

// إخفاء واجهة التسجيل
function hideRecordingUI() {
    const recordingContainer = document.getElementById('voice-recording-container');
    const messageInput = document.getElementById('message-input');
    const sendBtn = document.getElementById('send-btn');

    if (recordingContainer) {
        recordingContainer.classList.add('hidden');
        recordingContainer.classList.remove('animate__fadeIn');
    }
    
    if (messageInput) {
        messageInput.disabled = false;
    }
    
    if (sendBtn) {
        sendBtn.disabled = false;
    }
}

// بدء عداد التسجيل
function startRecordingTimer() {
    recordingSeconds = 0;
    updateRecordingTimer();

    recordingTimer = setInterval(() => {
        recordingSeconds++;
        updateRecordingTimer();

        // إيقاف التسجيل تلقائياً بعد 60 ثانية
        if (recordingSeconds >= 60) {
            stopVoiceRecording();
            showError('تم الوصول إلى الحد الأقصى للتسجيل (60 ثانية)');
        }
    }, 1000);
}

// تحديث عداد التسجيل
function updateRecordingTimer() {
    const timerElement = document.getElementById('recording-timer');
    const mins = Math.floor(recordingSeconds / 60);
    const secs = recordingSeconds % 60;
    if (timerElement) {
        timerElement.textContent = `${mins}:${secs < 10 ? '0' : ''}${secs}`;
    }

    // تحديث شريط التسجيل
    const recordingLevel = document.getElementById('recording-level');
    if (recordingLevel) {
        const level = Math.min(recordingSeconds / 60, 1);
        recordingLevel.style.width = `${level * 100}%`;

        // تغيير اللون بناءً على الوقت المتبقي
        if (recordingSeconds > 50) {
            recordingLevel.classList.remove('bg-red-500');
            recordingLevel.classList.add('bg-red-700');
        }
    }
}

// إيقاف عداد التسجيل
function stopRecordingTimer() {
    if (recordingTimer) {
        clearInterval(recordingTimer);
        recordingTimer = null;
    }
}

// إيقاف التسجيل الصوتي
function stopVoiceRecording() {
    if (mediaRecorder && isRecording) {
        mediaRecorder.stop();
        isRecording = false;
    }
}

// عرض معاينة التسجيل
function showRecordingPreview(audioBlob) {
    const audioUrl = URL.createObjectURL(audioBlob);

    const previewModal = document.createElement('div');
    previewModal.className = 'fixed inset-0 z-50 flex items-center justify-center bg-black/70 animate__animated animate__fadeIn p-4';
    previewModal.innerHTML = `
        <div class="bg-white rounded-3xl shadow-2xl max-w-md w-full mx-auto overflow-hidden animate__animated animate__zoomIn">
            <div class="bg-gradient-to-r from-blue-600 to-purple-600 p-6 text-center">
                <h3 class="text-2xl font-bold text-white">🎤 معاينة التسجيل</h3>
                <p class="text-white/90 mt-2">${formatDuration(recordingSeconds)}</p>
            </div>
            <div class="p-6">
                <div class="mb-6">
                    <audio controls class="w-full" id="preview-audio">
                        <source src="${audioUrl}" type="audio/webm">
                        المتصفح لا يدود تشغيل الصوت.
                    </audio>
                </div>
                <div class="flex space-x-3 space-x-reverse">
                    <button onclick="sendVoiceMessage(this)" class="flex-1 bg-gradient-to-r from-green-500 to-emerald-500 hover:from-green-600 hover:to-emerald-600 text-white font-bold py-3 rounded-xl transition-all transform hover:scale-105 active:scale-95" data-audio-blob="true">
                        <i class="fas fa-paper-plane ml-2"></i>إرسال
                    </button>
                    <button onclick="cancelRecording(this)" class="flex-1 bg-gradient-to-r from-red-500 to-pink-500 hover:from-red-600 hover:to-pink-600 text-white font-bold py-3 rounded-xl transition-all transform hover:scale-105 active:scale-95">
                        <i class="fas fa-times ml-2"></i>إلغاء
                    </button>
                </div>
                <div class="mt-4 text-center text-sm text-gray-500">
                    <i class="fas fa-info-circle ml-1"></i>
                    سيتم حفظ التسجيل في قاعدة البيانات
                </div>
            </div>
        </div>
    `;

    document.body.appendChild(previewModal);

    // تخزين البيانات للاستخدام لاحقاً
    previewModal.audioBlob = audioBlob;
    previewModal.audioUrl = audioUrl;
    previewModal.duration = recordingSeconds;
}

// إرسال الرسالة الصوتية
async function sendVoiceMessage(button) {
    const modal = button.closest('.fixed');
    const audioBlob = modal.audioBlob;
    const duration = modal.duration;

    // إظهار مؤشر التحميل
    button.disabled = true;
    button.innerHTML = '<i class="fas fa-spinner fa-spin ml-2"></i>جاري الرفع...';

    try {
        // إنشاء FormData لرفع الملف
        const formData = new FormData();
        formData.append('voice', audioBlob, `recording_${selectedUser}_${Date.now()}.webm`);

        // رفع الملف إلى السيرفر
        const response = await fetch('/api/upload-voice', {
            method: 'POST',
            body: formData
        });

        const result = await response.json();

        if (result.success) {
            // إرسال الرسالة الصوتية عبر Socket.IO
            socket.emit('send_voice_message', {
                sender: selectedUser,
                voiceFile: result.file,
                duration: duration
            });

            // إغلاق النافذة
            modal.remove();

            // تنظيف الذاكرة
            URL.revokeObjectURL(modal.audioUrl);

            showSuccess('تم إرسال الرسالة الصوتية بنجاح');
        } else {
            throw new Error(result.error || 'فشل في رفع الملف');
        }
    } catch (err) {
        console.error('Error sending voice message:', err);
        showError('فشل في إرسال الرسالة الصوتية');
        button.disabled = false;
        button.innerHTML = '<i class="fas fa-paper-plane ml-2"></i>إرسال';
    }
}

// إلغاء التسجيل
function cancelRecording(button) {
    const modal = button.closest('.fixed');
    if (modal.audioUrl) {
        URL.revokeObjectURL(modal.audioUrl);
    }
    modal.remove();
}

// إرسال رسالة نصية
function sendMessage() {
    const messageInput = document.getElementById('message-input');
    const message = messageInput ? messageInput.value.trim() : '';

    if (!message || !selectedUser || !socket || !isConnected) {
        if (!selectedUser) {
            showError('يجب اختيار مستخدم أولاً');
        }
        return;
    }

    // إرسال الرسالة عبر Socket.IO
    socket.emit('send_message', {
        sender: selectedUser,
        message: message
    });

    // مسح حقل الإدخال
    if (messageInput) {
        messageInput.value = '';
        document.getElementById('char-count').textContent = '0';
        
        // إعادة ضبط ارتفاع حقل الإدخال
        messageInput.style.height = 'auto';
        messageInput.style.height = (messageInput.scrollHeight) + 'px';

        // إعادة التركيز على حقل الإدخال
        messageInput.focus();
    }
}

// التمرير لأسفل
function scrollToBottom() {
    const chatMessages = document.getElementById('chat-messages');
    if (chatMessages) {
        chatMessages.scrollTop = chatMessages.scrollHeight;
    }
}

// عرض رسالة خطأ
function showError(message) {
    const errorDiv = document.createElement('div');
    errorDiv.className = 'fixed top-4 right-4 bg-red-500 text-white px-6 py-3 rounded-xl shadow-lg z-50 animate__animated animate__fadeInRight';
    errorDiv.innerHTML = `
        <div class="flex items-center">
            <i class="fas fa-exclamation-circle ml-2"></i>
            <span>${message}</span>
        </div>
    `;

    document.body.appendChild(errorDiv);

    setTimeout(() => {
        errorDiv.classList.add('animate__fadeOutRight');
        setTimeout(() => errorDiv.remove(), 300);
    }, 3000);
}

// عرض رسالة نجاح
function showSuccess(message) {
    const successDiv = document.createElement('div');
    successDiv.className = 'fixed top-4 right-4 bg-green-500 text-white px-6 py-3 rounded-xl shadow-lg z-50 animate__animated animate__fadeInRight';
    successDiv.innerHTML = `
        <div class="flex items-center">
            <i class="fas fa-check-circle ml-2"></i>
            <span>${message}</span>
        </div>
    `;

    document.body.appendChild(successDiv);

    setTimeout(() => {
        successDiv.classList.add('animate__fadeOutRight');
        setTimeout(() => successDiv.remove(), 300);
    }, 3000);
}

// تشغيل صوت الإشعار
function playNotificationSound() {
    const soundBtn = document.getElementById('sound-btn');
    if (!soundBtn) return;
    
    const icon = soundBtn.querySelector('i');

    if (icon && icon.classList.contains('fa-volume-up')) {
        const audio = new Audio('data:audio/wav;base64,UklGRigAAABXQVZFZm10IBIAAAABAAEAQB8AAEAfAAABAAgAZGF0YQ');
        audio.volume = 0.3;
        audio.play().catch(() => { });
    }
}

// تحديث الإحصائيات
function updateStatistics(messages) {
    const totalMessages = messages.length;
    const voiceMessages = messages.filter(m => m.has_voice).length;

    const messageCount = document.getElementById('message-count');
    const voiceCount = document.getElementById('voice-count');
    const messageTotal = document.getElementById('message-total');
    const voiceTotal = document.getElementById('voice-total');

    if (messageCount) messageCount.textContent = totalMessages;
    if (voiceCount) voiceCount.textContent = voiceMessages;
    if (messageTotal) messageTotal.textContent = `${totalMessages} رسالة`;
    if (voiceTotal) voiceTotal.textContent = `${voiceMessages} رسالة صوتية`;
}

// زيادة عداد الرسائل
function incrementMessageCount() {
    const countElement = document.getElementById('message-count');
    if (!countElement) return;
    
    const current = parseInt(countElement.textContent) || 0;
    countElement.textContent = current + 1;

    const totalElement = document.getElementById('message-total');
    if (totalElement) {
        totalElement.textContent = `${current + 1} رسالة`;
    }
}

// زيادة عداد الرسائل الصوتية
function incrementVoiceCount() {
    const countElement = document.getElementById('voice-count');
    if (!countElement) return;
    
    const current = parseInt(countElement.textContent) || 0;
    countElement.textContent = current + 1;

    const totalElement = document.getElementById('voice-total');
    if (totalElement) {
        totalElement.textContent = `${current + 1} رسالة صوتية`;
    }
}

// الحصول على لون المستخدم
function getUserColorClass(username) {
    switch (username) {
        case 'حسن': return 'bg-gradient-to-r from-red-500 to-pink-500';
        case 'حاتم': return 'bg-gradient-to-r from-green-500 to-emerald-500';
        case 'مشاري': return 'bg-gradient-to-r from-purple-500 to-indigo-500';
        default: return 'bg-gradient-to-r from-blue-500 to-purple-500';
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
        emojiButton.className = 'emoji-btn text-xl p-2 hover:bg-gray-100 rounded-lg transition-all duration-200 transform hover:scale-125';
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

    // تحديث عداد الأحرف
    const charCount = document.getElementById('char-count');
    if (charCount) {
        charCount.textContent = messageInput.value.length;
    }

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

    // فتح/إغلاق قائمة الإيموجي
    emojiToggle.addEventListener('click', (e) => {
        e.stopPropagation();
        if (!selectedUser) {
            showError('يجب اختيار مستخدم أولاً');
            return;
        }
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
        if (emojiPicker && !emojiPicker.classList.contains('hidden')) {
            if (!emojiPicker.contains(e.target) && !emojiToggle.contains(e.target)) {
                emojiPicker.classList.add('hidden');
            }
        }
    });
}

// إعداد زر التسجيل الصوتي
function setupVoiceRecording() {
    const voiceRecordBtn = document.getElementById('voice-record-btn');
    const sendVoiceBtn = document.getElementById('send-voice-btn');
    const cancelVoiceBtn = document.getElementById('cancel-voice-btn');

    if (!voiceRecordBtn) return;

    // بدء التسجيل عند النقر
    voiceRecordBtn.addEventListener('click', () => {
        if (!selectedUser) {
            showError('يجب اختيار مستخدم أولاً');
            return;
        }
        startVoiceRecording();
    });

    // إرسال التسجيل
    if (sendVoiceBtn) {
        sendVoiceBtn.addEventListener('click', () => {
            stopVoiceRecording();
        });
    }

    // إلغاء التسجيل
    if (cancelVoiceBtn) {
        cancelVoiceBtn.addEventListener('click', () => {
            stopVoiceRecording();
            showError('تم إلغاء التسجيل');
        });
    }

    // دعم الضغط الطويل للتسجيل (للجوال)
    let pressTimer;
    voiceRecordBtn.addEventListener('touchstart', (e) => {
        e.preventDefault();
        if (!selectedUser) {
            showError('يجب اختيار مستخدم أولاً');
            return;
        }
        pressTimer = setTimeout(() => {
            startVoiceRecording();
        }, 500);
    });

    voiceRecordBtn.addEventListener('touchend', (e) => {
        e.preventDefault();
        clearTimeout(pressTimer);
    });

    voiceRecordBtn.addEventListener('contextmenu', (e) => {
        e.preventDefault();
    });
}

// تهيئة أحداث الإدخال
function setupInputEvents() {
    const messageInput = document.getElementById('message-input');
    const sendBtn = document.getElementById('send-btn');
    const charCount = document.getElementById('char-count');

    if (!messageInput || !sendBtn) return;

    // ربط حدث الإرسال بالزر
    sendBtn.addEventListener('click', sendMessage);

    // السماح بإرسال الرسالة بالضغط على Enter
    messageInput.addEventListener('keypress', (e) => {
        if (e.key === 'Enter' && !e.ctrlKey && !e.shiftKey) {
            e.preventDefault();
            sendMessage();
        }
    });

    // تحديث عداد الأحرف
    messageInput.addEventListener('input', function() {
        if (charCount) {
            charCount.textContent = this.value.length;
            if (this.value.length > 500) {
                charCount.classList.add('text-red-500');
            } else {
                charCount.classList.remove('text-red-500');
            }
            
            // تعديل ارتفاع مربع النص تلقائياً
            this.style.height = 'auto';
            this.style.height = (this.scrollHeight) + 'px';
        }
    });

    // السماح باستخدام Ctrl+Enter لسطر جديد
    messageInput.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' && e.ctrlKey) {
            // السماح بإدخال سطر جديد
            const start = messageInput.selectionStart;
            const end = messageInput.selectionEnd;
            messageInput.value = messageInput.value.substring(0, start) + '\n' + messageInput.value.substring(end);
            messageInput.selectionStart = messageInput.selectionEnd = start + 1;
            e.preventDefault();
        }
    });
}

// تحديث الوقت
function updateTime() {
    const now = new Date();
    const timeString = now.toLocaleTimeString('ar-SA', {
        hour: '2-digit',
        minute: '2-digit'
    });
    const timeElement = document.getElementById('current-time');
    if (timeElement) {
        timeElement.textContent = timeString;
    }
}

// تهيئة التطبيق
function initializeApp() {
    connectToServer();

    // تهيئة الإيموجي
    initializeEmojiPicker();
    setupEmojiPicker();

    // تهيئة التسجيل الصوتي
    setupVoiceRecording();

    // تهيئة أحداث الإدخال
    setupInputEvents();

    // إعداد تحديث الوقت
    updateTime();
    setInterval(updateTime, 60000);
    
    // تمكين زر العودة للأعلى
    const scrollToTopBtn = document.getElementById('scroll-to-top');
    if (scrollToTopBtn) {
        window.addEventListener('scroll', () => {
            if (window.scrollY > 300) {
                scrollToTopBtn.classList.remove('hidden');
            } else {
                scrollToTopBtn.classList.add('hidden');
            }
        });
        
        scrollToTopBtn.addEventListener('click', () => {
            window.scrollTo({ top: 0, behavior: 'smooth' });
        });
    }
    
    console.log('Chat application initialized successfully');
}

// بدء التطبيق
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeApp);
} else {
    initializeApp();
}

// جعل الدوال متاحة عالمياً
window.selectUser = selectUser;
window.sendMessage = sendMessage;
window.playVoiceMessage = playVoiceMessage;
window.togglePlayPause = togglePlayPause;
window.startVoiceRecording = startVoiceRecording;
window.stopVoiceRecording = stopVoiceRecording;
window.sendVoiceMessage = sendVoiceMessage;
window.cancelRecording = cancelRecording;
window.insertEmoji = insertEmoji;
