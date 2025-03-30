// 计时器功能实现
class Timer {
    constructor() {
        this.totalSeconds = 0;
        this.interval = null;
        this.isRunning = false;
        this.callback = null;
        this.initialSeconds = 0; // 记录初始设置的时间，用于计算进度
    }

    // 设置总时间（秒）
    setTime(minutes, seconds = 0) {
        this.totalSeconds = minutes * 60 + seconds;
        this.initialSeconds = this.totalSeconds; // 记录初始时间
        this.updateDisplay();
    }

    // 开始计时
    start(callback) {
        if (this.isRunning) return;
        
        this.callback = callback;
        this.isRunning = true;
        
        this.interval = setInterval(() => {
            if (this.totalSeconds <= 0) {
                this.pause();
                if (this.callback) this.callback();
                return;
            }
            
            this.totalSeconds--;
            this.updateDisplay();
        }, 1000);
    }

    // 暂停计时
    pause() {
        this.isRunning = false;
        clearInterval(this.interval);
    }

    // 重置计时
    reset(minutes, seconds = 0) {
        this.pause();
        this.setTime(minutes, seconds);
    }

    // 更新显示
    updateDisplay() {
        const minutes = Math.floor(this.totalSeconds / 60);
        const seconds = this.totalSeconds % 60;
        
        // 可以在这里更新UI显示
        const displayTime = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
        
        // 这里应该连接到UI元素
        const timerDisplay = document.querySelector('.timer-display');
        if (timerDisplay) {
            timerDisplay.textContent = displayTime;
        }
        
        // 更新进度环
        this.updateProgress();
    }
    
    // 更新进度环
    updateProgress() {
        // 计算进度百分比
        const progress = this.initialSeconds > 0 ? 
            (1 - (this.totalSeconds / this.initialSeconds)) * 100 : 0;
            
        // 更新圆形进度条
        const timerCircle = document.querySelector('.timer-circle');
        if (timerCircle) {
            timerCircle.style.background = `conic-gradient(var(--primary-color) ${progress}%, #eaeaea ${progress}%)`;
        }
    }
    
    // 获取剩余时间（秒）
    getRemainingTime() {
        return this.totalSeconds;
    }
    
    // 获取是否正在运行
    isActive() {
        return this.isRunning;
    }
}

// 间隔计时器类（用于HIIT等多组训练）
class IntervalTimer {
    constructor() {
        this.timer = new Timer();
        this.phases = []; // 存储训练和休息阶段的时间
        this.currentPhase = 0;
        this.currentSet = 1;
        this.totalSets = 1;
        this.phaseNames = []; // 阶段名称，例如"运动"、"休息"
        this.onPhaseEnd = null;
        this.onComplete = null;
    }
    
    // 设置间隔计时器参数
    setup(phases, phaseNames, sets) {
        this.phases = phases; // 例如 [30, 10] 表示30秒运动，10秒休息
        this.phaseNames = phaseNames || ["运动", "休息"];
        this.totalSets = sets || 1;
        this.currentSet = 1;
        this.currentPhase = 0;
        
        // 设置初始阶段时间
        if (this.phases.length > 0) {
            const [minutes, seconds] = this.convertToMinSec(this.phases[0]);
            this.timer.reset(minutes, seconds);
        }
        
        this.updateSetDisplay();
    }
    
    // 开始计时
    start() {
        if (this.phases.length === 0) return;
        
        this.timer.start(() => {
            // 当前阶段结束时的回调
            this.nextPhase();
        });
        
        this.updatePhaseDisplay();
    }
    
    // 暂停计时
    pause() {
        this.timer.pause();
    }
    
    // 重置计时器
    reset() {
        this.currentPhase = 0;
        this.currentSet = 1;
        
        if (this.phases.length > 0) {
            const [minutes, seconds] = this.convertToMinSec(this.phases[0]);
            this.timer.reset(minutes, seconds);
        }
        
        this.updateSetDisplay();
        this.updatePhaseDisplay();
    }
    
    // 进入下一个阶段
    nextPhase() {
        // 如果有阶段结束回调，执行它
        if (this.onPhaseEnd) {
            this.onPhaseEnd(this.currentPhase, this.currentSet);
        }
        
        // 更新阶段和组数
        this.currentPhase = (this.currentPhase + 1) % this.phases.length;
        
        // 如果完成一组循环，增加当前组数
        if (this.currentPhase === 0) {
            this.currentSet++;
        }
        
        // 检查是否完成所有组
        if (this.currentSet > this.totalSets) {
            // 完成所有组
            if (this.onComplete) {
                this.onComplete();
            }
            return;
        }
        
        // 设置下一阶段时间
        const [minutes, seconds] = this.convertToMinSec(this.phases[this.currentPhase]);
        this.timer.reset(minutes, seconds);
        
        // 播放声音提醒阶段变化
        this.playPhaseChangeSound();
        
        // 更新显示
        this.updateSetDisplay();
        this.updatePhaseDisplay();
        
        // 继续计时
        this.timer.start(() => {
            this.nextPhase();
        });
    }
    
    // 播放阶段变化提示音
    playPhaseChangeSound() {
        const audio = new Audio('audio/phase-change.mp3');
        audio.play().catch(e => console.log('播放提示音失败:', e));
    }
    
    // 更新组数显示
    updateSetDisplay() {
        const setDisplay = document.querySelector('.set-display');
        if (setDisplay) {
            setDisplay.textContent = `${this.currentSet} / ${this.totalSets}组`;
        }
    }
    
    // 更新阶段显示
    updatePhaseDisplay() {
        const phaseDisplay = document.querySelector('.phase-display');
        if (phaseDisplay && this.phaseNames[this.currentPhase]) {
            phaseDisplay.textContent = this.phaseNames[this.currentPhase];
            
            // 更新阶段颜色
            if (this.currentPhase % 2 === 0) {
                // 运动阶段
                phaseDisplay.classList.remove('rest-phase');
                phaseDisplay.classList.add('workout-phase');
            } else {
                // 休息阶段
                phaseDisplay.classList.remove('workout-phase');
                phaseDisplay.classList.add('rest-phase');
            }
        }
    }
    
    // 将秒数转换为分钟和秒
    convertToMinSec(totalSeconds) {
        const minutes = Math.floor(totalSeconds / 60);
        const seconds = totalSeconds % 60;
        return [minutes, seconds];
    }
    
    // 获取总时间（秒）
    getTotalTime() {
        let total = 0;
        for (let i = 0; i < this.totalSets; i++) {
            for (let phase of this.phases) {
                total += phase;
            }
        }
        return total;
    }
    
    // 获取当前已完成时间（秒）
    getElapsedTime() {
        // 计算已完成的完整组的时间
        let elapsed = 0;
        const phaseSum = this.phases.reduce((sum, time) => sum + time, 0);
        
        // 已完成的完整组
        elapsed += (this.currentSet - 1) * phaseSum;
        
        // 当前组已完成的阶段
        for (let i = 0; i < this.currentPhase; i++) {
            elapsed += this.phases[i];
        }
        
        // 当前阶段已经过的时间
        if (this.currentPhase < this.phases.length) {
            const currentPhaseTotal = this.phases[this.currentPhase];
            const currentPhaseRemaining = this.timer.getRemainingTime();
            elapsed += (currentPhaseTotal - currentPhaseRemaining);
        }
        
        return elapsed;
    }
    
    // 获取总进度百分比
    getProgressPercentage() {
        const total = this.getTotalTime();
        const elapsed = this.getElapsedTime();
        return total > 0 ? (elapsed / total) * 100 : 0;
    }
    
    // 更新总进度条
    updateTotalProgress() {
        const progress = this.getProgressPercentage();
        const progressBar = document.querySelector('.total-progress .progress-bar');
        if (progressBar) {
            progressBar.style.width = `${progress}%`;
        }
    }
}

// 创建间隔计时器UI
function createIntervalTimerUI(title, workoutTime, restTime, sets) {
    // 切换到计时器运行界面
    const timerScreen = document.getElementById('timer-screen');
    
    // 保存原来的内容
    const originalContent = timerScreen.innerHTML;
    
    // 创建间隔计时器运行UI
    timerScreen.innerHTML = `
        <div class="d-flex justify-content-between align-items-center my-4">
            <button class="btn btn-outline-secondary back-btn"><i class="bi bi-arrow-left"></i></button>
            <h2 class="text-center mb-0">${title}</h2>
            <button class="btn btn-outline-primary edit-btn"><i class="bi bi-pencil"></i></button>
        </div>
        
        <div class="phase-display workout-phase mb-2">运动</div>
        
        <div class="timer-circle">
            <div class="timer-circle-inner">
                <div class="timer-display">00:00</div>
            </div>
        </div>
        
        <div class="set-display my-3 text-center">1 / ${sets}组</div>
        
        <div class="total-progress mb-3">
            <div class="progress">
                <div class="progress-bar" role="progressbar" style="width: 0%"></div>
            </div>
        </div>
        
        <div class="timer-controls">
            <button class="action-btn btn btn-outline-secondary rounded-circle reset-btn">
                <i class="bi bi-arrow-counterclockwise"></i>
            </button>
            <button class="action-btn btn btn-primary rounded-circle start-btn">
                <i class="bi bi-play-fill"></i>
            </button>
            <button class="action-btn btn btn-outline-primary rounded-circle skip-btn">
                <i class="bi bi-skip-forward"></i>
            </button>
        </div>
    `;
    
    // 初始化间隔计时器逻辑
    const intervalTimer = new IntervalTimer();
    
    // 设置间隔时间和组数
    intervalTimer.setup([workoutTime, restTime], ["运动", "休息"], sets);
    
    // 每100毫秒更新一次总进度条
    const progressInterval = setInterval(() => {
        if (intervalTimer.timer.isActive()) {
            intervalTimer.updateTotalProgress();
        }
    }, 100);
    
    // 设置完成回调
    intervalTimer.onComplete = () => {
        clearInterval(progressInterval);
        // 播放完成提示音
        playCompletionSound();
        // 显示完成提示
        showNotification(title, "训练完成！");
        
        // 更新UI为完成状态
        const phaseDisplay = document.querySelector('.phase-display');
        if (phaseDisplay) {
            phaseDisplay.textContent = "完成";
            phaseDisplay.classList.remove('workout-phase', 'rest-phase');
            phaseDisplay.classList.add('complete-phase');
        }
        
        document.querySelector('.start-btn').innerHTML = '<i class="bi bi-play-fill"></i>';
    };
    
    // 返回按钮事件
    timerScreen.querySelector('.back-btn').addEventListener('click', () => {
        clearInterval(progressInterval);
        intervalTimer.pause();
        timerScreen.innerHTML = originalContent;
        initPresets(new Timer()); // 重新初始化预设
    });
    
    // 编辑按钮事件
    timerScreen.querySelector('.edit-btn').addEventListener('click', () => {
        clearInterval(progressInterval);
        intervalTimer.pause();
        showEditIntervalDialog(title, workoutTime, restTime, sets, originalContent);
    });
    
    // 开始/暂停按钮事件
    const startBtn = timerScreen.querySelector('.start-btn');
    startBtn.addEventListener('click', () => {
        if (intervalTimer.timer.isActive()) {
            intervalTimer.pause();
            startBtn.innerHTML = '<i class="bi bi-play-fill"></i>';
        } else {
            intervalTimer.start();
            startBtn.innerHTML = '<i class="bi bi-pause-fill"></i>';
            // 立即更新进度
            intervalTimer.updateTotalProgress();
        }
    });
    
    // 重置按钮事件
    timerScreen.querySelector('.reset-btn').addEventListener('click', () => {
        intervalTimer.reset();
        startBtn.innerHTML = '<i class="bi bi-play-fill"></i>';
        intervalTimer.updateTotalProgress();
    });
    
    // 跳过按钮事件
    timerScreen.querySelector('.skip-btn').addEventListener('click', () => {
        intervalTimer.nextPhase();
    });
}

// 显示编辑间隔计时器对话框
function showEditIntervalDialog(title, workoutTime, restTime, sets, originalContent) {
    // 创建对话框
    const dialog = document.createElement('div');
    dialog.className = 'modal fade';
    dialog.id = 'editIntervalModal';
    dialog.innerHTML = `
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">编辑间隔计时器</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <form>
                        <div class="mb-3">
                            <label for="intervalName" class="form-label">名称</label>
                            <input type="text" class="form-control" id="intervalName" value="${title}">
                        </div>
                        <div class="mb-3">
                            <label for="workoutTime" class="form-label">运动时间 (秒)</label>
                            <input type="number" class="form-control" id="workoutTime" min="1" value="${workoutTime}">
                        </div>
                        <div class="mb-3">
                            <label for="restTime" class="form-label">休息时间 (秒)</label>
                            <input type="number" class="form-control" id="restTime" min="1" value="${restTime}">
                        </div>
                        <div class="mb-3">
                            <label for="sets" class="form-label">组数</label>
                            <input type="number" class="form-control" id="sets" min="1" value="${sets}">
                        </div>
                        <div class="form-check mb-3">
                            <input class="form-check-input" type="checkbox" id="saveAsPreset">
                            <label class="form-check-label" for="saveAsPreset">
                                保存为预设
                            </label>
                        </div>
                    </form>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">取消</button>
                    <button type="button" class="btn btn-primary" id="saveInterval">保存</button>
                </div>
            </div>
        </div>
    `;
    
    // 添加到文档
    document.body.appendChild(dialog);
    
    // 初始化Bootstrap模态框
    const modal = new bootstrap.Modal(dialog);
    modal.show();
    
    // 保存按钮事件
    document.getElementById('saveInterval').addEventListener('click', () => {
        const newTitle = document.getElementById('intervalName').value || title;
        const newWorkoutTime = parseInt(document.getElementById('workoutTime').value) || workoutTime;
        const newRestTime = parseInt(document.getElementById('restTime').value) || restTime;
        const newSets = parseInt(document.getElementById('sets').value) || sets;
        const saveAsPreset = document.getElementById('saveAsPreset').checked;
        
        // 关闭对话框
        modal.hide();
        
        // 清理DOM
        setTimeout(() => {
            document.body.removeChild(dialog);
        }, 500);
        
        // 创建新的间隔计时器
        createIntervalTimerUI(newTitle, newWorkoutTime, newRestTime, newSets);
        
        // 如果选择保存为预设
        if (saveAsPreset && window.presetManager) {
            window.presetManager.addPreset(newTitle, newWorkoutTime, newRestTime, newSets);
            window.presetManager.renderPresets();
        }
    });
}

// 初始化计时器预设
function initPresets(timer) {
    // 为"我的预设"中的启动按钮添加事件
    document.querySelectorAll('#timer-screen .preset-item .btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            // 获取预设信息
            const presetItem = e.target.closest('.preset-item');
            const title = presetItem.querySelector('.card-title').textContent;
            const timeText = presetItem.querySelector('small').textContent;
            
            // 解析时间（这里简化处理，实际需要针对不同格式做解析）
            const minutes = parseInt(timeText.match(/\d+/)[0]);
            
            // 创建计时器UI
            createTimerUI(title, minutes);
        });
    });
    
    // 为模板卡片添加事件
    document.querySelectorAll('#timer-screen .card .btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const card = e.target.closest('.card');
            const title = card.querySelector('.card-title').textContent;
            const timeText = card.querySelector('.card-text').textContent;
            
            // 检查是否是间隔计时模式
            if (timeText.includes('运动') && timeText.includes('休息') && timeText.includes('组')) {
                // 解析间隔计时参数
                const matches = timeText.match(/(\d+)秒运动，(\d+)秒休息，(\d+)组/);
                if (matches && matches.length === 4) {
                    const workoutTime = parseInt(matches[1]);
                    const restTime = parseInt(matches[2]);
                    const sets = parseInt(matches[3]);
                    
                    // 创建间隔计时器UI
                    createIntervalTimerUI(title, workoutTime, restTime, sets);
                    return;
                }
            }
            
            // 普通计时模式
            let minutes = 25; // 默认值
            if (timeText.includes('分钟')) {
                minutes = parseInt(timeText.match(/\d+/)[0]);
            }
            
            // 创建计时器UI
            createTimerUI(title, minutes);
        });
    });
}

// 创建计时器UI
function createTimerUI(title, minutes) {
    // 切换到计时器运行界面
    const timerScreen = document.getElementById('timer-screen');
    
    // 保存原来的内容
    const originalContent = timerScreen.innerHTML;
    
    // 创建计时器运行UI
    timerScreen.innerHTML = `
        <div class="d-flex justify-content-between align-items-center my-4">
            <button class="btn btn-outline-secondary back-btn"><i class="bi bi-arrow-left"></i></button>
            <h2 class="text-center mb-0">${title}</h2>
            <button class="btn btn-outline-primary edit-btn"><i class="bi bi-pencil"></i></button>
        </div>
        
        <div class="timer-circle">
            <div class="timer-circle-inner">
                <div class="timer-display">${minutes.toString().padStart(2, '0')}:00</div>
            </div>
        </div>
        
        <div class="timer-controls">
            <button class="action-btn btn btn-outline-secondary rounded-circle">
                <i class="bi bi-arrow-counterclockwise"></i>
            </button>
            <button class="action-btn btn btn-primary rounded-circle">
                <i class="bi bi-play-fill"></i>
            </button>
            <button class="action-btn btn btn-outline-primary rounded-circle">
                <i class="bi bi-skip-forward"></i>
            </button>
        </div>
    `;
    
    // 初始化计时器逻辑
    const timer = new Timer();
    timer.setTime(minutes);
    
    // 返回按钮事件
    timerScreen.querySelector('.back-btn').addEventListener('click', () => {
        timer.pause();
        timerScreen.innerHTML = originalContent;
        initPresets(new Timer()); // 重新初始化预设
    });
    
    // 编辑按钮事件
    timerScreen.querySelector('.edit-btn').addEventListener('click', () => {
        timer.pause();
        showEditTimerDialog(title, minutes, originalContent);
    });
    
    // 开始/暂停按钮事件
    const startBtn = timerScreen.querySelector('.btn-primary');
    startBtn.addEventListener('click', () => {
        if (timer.isRunning) {
            timer.pause();
            startBtn.innerHTML = '<i class="bi bi-play-fill"></i>';
        } else {
            timer.start(() => {
                // 计时结束后的回调
                playCompletionSound();
                showNotification(title, '计时完成！');
            });
            startBtn.innerHTML = '<i class="bi bi-pause-fill"></i>';
        }
    });
    
    // 重置按钮事件
    timerScreen.querySelector('.btn-outline-secondary').addEventListener('click', () => {
        timer.reset(minutes);
        startBtn.innerHTML = '<i class="bi bi-play-fill"></i>';
    });
    
    // 跳过按钮事件
    timerScreen.querySelector('.btn-outline-primary').addEventListener('click', () => {
        timer.setTime(0);
    });
}

// 显示编辑计时器对话框
function showEditTimerDialog(name, minutes, originalPreset) {
    // 创建对话框
    const dialog = document.createElement('div');
    dialog.className = 'modal fade';
    dialog.id = 'editTimerModal';
    dialog.innerHTML = `
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">编辑计时器预设</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <form>
                        <div class="mb-3">
                            <label for="presetName" class="form-label">名称</label>
                            <input type="text" class="form-control" id="presetName" value="${name}">
                        </div>
                        <div class="mb-3">
                            <label for="presetMinutes" class="form-label">时间（分钟）</label>
                            <input type="number" class="form-control" id="presetMinutes" min="1" max="180" value="${minutes}">
                        </div>
                    </form>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">取消</button>
                    <button type="button" class="btn btn-primary" id="savePreset">保存</button>
                </div>
            </div>
        </div>
    `;
    
    // 添加到文档
    document.body.appendChild(dialog);
    
    // 初始化Bootstrap模态框
    const modal = new bootstrap.Modal(dialog);
    modal.show();
    
    // 保存按钮事件
    document.getElementById('savePreset').addEventListener('click', () => {
        const name = document.getElementById('presetName').value;
        const minutes = parseInt(document.getElementById('presetMinutes').value);
        
        if (!name || isNaN(minutes) || minutes <= 0) {
            alert('请输入有效的名称和时间！');
            return;
        }
        
        // 保存预设
        console.log('保存预设:', { name, minutes });
        
        // 添加或更新预设
        const presetManager = window.presetManager;
        if (presetManager) {
            if (originalPreset) {
                // 更新现有预设
                presetManager.updatePreset(originalPreset.id, name, minutes);
            } else {
                // 添加新预设
                presetManager.addPreset(name, minutes);
            }
            presetManager.renderPresets(); // 重新渲染预设列表
        }
        
        // 关闭对话框
        modal.hide();
        
        // 清理DOM
        setTimeout(() => {
            document.body.removeChild(dialog);
        }, 500);
    });
}

// 显示添加计时器对话框
function showAddTimerDialog() {
    // 创建对话框
    const dialog = document.createElement('div');
    dialog.className = 'modal fade';
    dialog.id = 'addTimerModal';
    dialog.innerHTML = `
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">添加计时器</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <form>
                        <div class="mb-3">
                            <label for="timerName" class="form-label">名称</label>
                            <input type="text" class="form-control" id="timerName" placeholder="例如：阅读时间">
                        </div>
                        <div class="mb-3">
                            <label for="timerMinutes" class="form-label">时间（分钟）</label>
                            <input type="number" class="form-control" id="timerMinutes" min="1" max="180" value="25">
                        </div>
                        <div class="form-check mb-3">
                            <input class="form-check-input" type="checkbox" id="saveAsPreset">
                            <label class="form-check-label" for="saveAsPreset">
                                保存为预设
                            </label>
                        </div>
                    </form>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">取消</button>
                    <button type="button" class="btn btn-primary" id="saveTimer">保存</button>
                </div>
            </div>
        </div>
    `;
    
    // 添加到文档
    document.body.appendChild(dialog);
    
    // 初始化Bootstrap模态框
    const modal = new bootstrap.Modal(dialog);
    modal.show();
    
    // 保存按钮事件
    document.getElementById('saveTimer').addEventListener('click', () => {
        const name = document.getElementById('timerName').value || '计时器';
        const minutes = parseInt(document.getElementById('timerMinutes').value);
        const saveAsPreset = document.getElementById('saveAsPreset').checked;
        
        if (isNaN(minutes) || minutes <= 0) {
            alert('请输入有效的时间！');
            return;
        }
        
        // 如果选择保存为预设
        if (saveAsPreset && window.presetManager) {
            window.presetManager.addPreset(name, minutes);
            window.presetManager.renderPresets();
        }
        
        // 创建并显示计时器
        createTimerUI(name, minutes);
        
        // 关闭对话框
        modal.hide();
        
        // 清理DOM
        setTimeout(() => {
            document.body.removeChild(dialog);
        }, 500);
    });
}

// 计时器预设管理
class TimerPresets {
    constructor() {
        this.presets = [];
        this.nextId = 1;
    }
    
    // 加载预设
    loadPresets() {
        // 从本地存储加载预设
        const savedPresets = localStorage.getItem('timer-presets');
        if (savedPresets) {
            try {
                this.presets = JSON.parse(savedPresets);
                
                // 如果没有预设或预设格式无效，添加默认预设
                if (!Array.isArray(this.presets) || this.presets.length === 0) {
                    this.presets = [];
                    this.addDefaultPresets();
                } else {
                    // 找到最大ID，用于设置nextId
                    this.nextId = Math.max(...this.presets.map(p => p.id), 0) + 1;
                }
            } catch (e) {
                console.error('解析预设数据失败:', e);
                this.presets = [];
                this.addDefaultPresets();
            }
        } else {
            // 如果没有保存的预设，添加默认预设
            this.addDefaultPresets();
        }
        
        // 渲染预设
        this.renderPresets();
    }
    
    // 添加默认预设
    addDefaultPresets() {
        // 添加一些默认常用的预设
        this.addPreset('快速冥想', 5);
        this.addPreset('番茄工作法', 25);
        this.addPreset('午休时间', 30);
        this.addPreset('长时阅读', 60);
        this.addPreset('运动健身', 45);
    }
    
    // 添加预设
    addPreset(name, minutes) {
        const preset = {
            id: this.nextId++,
            name: name,
            minutes: minutes
        };
        
        this.presets.push(preset);
        this.savePresets();
        return preset.id;
    }
    
    // 删除预设
    removePreset(id) {
        this.presets = this.presets.filter(preset => preset.id !== id);
        this.savePresets();
    }
    
    // 更新预设
    updatePreset(id, name, minutes) {
        const preset = this.presets.find(p => p.id === id);
        if (preset) {
            preset.name = name;
            preset.minutes = minutes;
            this.savePresets();
            return true;
        }
        return false;
    }
    
    // 保存预设到本地存储
    savePresets() {
        localStorage.setItem('timer-presets', JSON.stringify(this.presets));
    }
    
    // 渲染预设到界面
    renderPresets() {
        const presetContainer = document.getElementById('preset-container');
        if (!presetContainer) return;
        
        // 清空容器
        presetContainer.innerHTML = '';
        
        // 如果没有预设
        if (this.presets.length === 0) {
            presetContainer.innerHTML = '<div class="text-center text-muted py-3">暂无预设</div>';
            return;
        }
        
        // 添加每个预设
        this.presets.forEach(preset => {
            const presetElement = document.createElement('div');
            presetElement.className = 'preset-item';
            presetElement.dataset.id = preset.id;
            
            presetElement.innerHTML = `
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <h5 class="card-title mb-1">${preset.name}</h5>
                        <div class="preset-time">${preset.minutes} 分钟</div>
                    </div>
                    <div>
                        <button class="btn btn-sm btn-primary use-preset-btn me-2" data-id="${preset.id}">
                            使用
                        </button>
                        <button class="btn btn-sm btn-outline-secondary edit-preset-btn me-2" data-id="${preset.id}">
                            <i class="bi bi-pencil"></i>
                        </button>
                        <button class="btn btn-sm btn-outline-danger delete-preset-btn" data-id="${preset.id}">
                            <i class="bi bi-trash"></i>
                        </button>
                    </div>
                </div>
            `;
            
            presetContainer.appendChild(presetElement);
        });
        
        // 添加事件监听
        this.setupPresetButtons();
    }
    
    // 设置预设按钮的事件监听
    setupPresetButtons() {
        // "使用"按钮
        document.querySelectorAll('.use-preset-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const id = parseInt(e.currentTarget.getAttribute('data-id'));
                const preset = this.presets.find(p => p.id === id);
                if (preset && window.timer) {
                    window.timer.setTime(preset.minutes * 60);
                    // 切换到计时器屏幕
                    document.querySelector('#timer-btn').click();
                }
            });
        });
        
        // "编辑"按钮
        document.querySelectorAll('.edit-preset-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const id = parseInt(e.currentTarget.getAttribute('data-id'));
                const preset = this.presets.find(p => p.id === id);
                if (preset) {
                    showEditTimerDialog(preset.name, preset.minutes, preset);
                }
            });
        });
        
        // "删除"按钮
        document.querySelectorAll('.delete-preset-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const id = parseInt(e.currentTarget.getAttribute('data-id'));
                if (confirm('确定要删除此预设吗？')) {
                    this.removePreset(id);
                    this.renderPresets();
                }
            });
        });
    }
}

// 初始化应用
function initialize() {
    // 初始化导航
    initNavigation();
    
    // 初始化设置选项
    initializeSettingsOptions();
    
    // 初始化主题
    initTheme();
    
    // 初始化计时器预设
    const presetManager = new TimerPresets();
    window.presetManager = presetManager; // 存储到全局变量以便访问
    presetManager.loadPresets();
    
    // 初始化计时器
    const timer = new Timer();
    window.timer = timer;
    
    // 初始化秒表
    const stopwatch = new Stopwatch();
    window.stopwatch = stopwatch;
    initStopwatch(stopwatch); // 添加秒表初始化
    
    // 初始化区间计时器
    const intervalTimer = new IntervalTimer();
    window.intervalTimer = intervalTimer;
    
    // 初始化闹钟管理器
    console.log('初始化闹钟管理器');
    const alarmManager = new AlarmManager();
    window.alarmManager = alarmManager;
    
    // 确保闹钟列表加载
    try {
        alarmManager.loadAlarms();
    } catch (error) {
        console.error('加载闹钟失败:', error);
        // 出错时尝试强制加载默认闹钟
        localStorage.removeItem('alarms');
        console.log('已清除闹钟数据，将重新添加默认闹钟');
        alarmManager.addDefaultAlarms();
    }
    
    // 初始化添加闹钟按钮
    const addAlarmBtn = document.getElementById('add-alarm-btn');
    if (addAlarmBtn) {
        addAlarmBtn.addEventListener('click', () => {
            showAddAlarmDialog();
        });
    }
    
    // 初始化添加计时器按钮
    const addTimerBtn = document.getElementById('add-timer-btn');
    if (addTimerBtn) {
        addTimerBtn.addEventListener('click', () => {
            showAddTimerDialog();
        });
    }
    
    // 添加请求通知权限的代码
    requestNotificationPermission();
    
    console.log('应用初始化完成');
}

// 请求通知权限
function requestNotificationPermission() {
    if ("Notification" in window) {
        if (Notification.permission !== "granted" && Notification.permission !== "denied") {
            Notification.requestPermission();
        }
    }
}

// 初始化主题
function initTheme() {
    // 从本地存储获取主题偏好
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme) {
        document.body.setAttribute('data-bs-theme', savedTheme);
    } else {
        // 根据系统偏好设置主题
        const prefersDarkScheme = window.matchMedia('(prefers-color-scheme: dark)');
        const defaultTheme = prefersDarkScheme.matches ? 'dark' : 'light';
        document.body.setAttribute('data-bs-theme', defaultTheme);
        localStorage.setItem('theme', defaultTheme);
    }
    
    // 设置主题切换按钮状态
    const themeSwitch = document.getElementById('theme-switch');
    if (themeSwitch) {
        themeSwitch.checked = document.body.getAttribute('data-bs-theme') === 'dark';
        
        // 添加主题切换事件
        themeSwitch.addEventListener('change', function() {
            const theme = this.checked ? 'dark' : 'light';
            document.body.setAttribute('data-bs-theme', theme);
            localStorage.setItem('theme', theme);
        });
    }
}

// 文档加载完成后初始化
document.addEventListener('DOMContentLoaded', function() {
    console.log('DOM内容加载完成，开始初始化应用');
    
    // 强制清除本地存储中的闹钟数据，确保添加默认闹钟
    localStorage.removeItem('alarms');
    console.log('已清除闹钟数据，将重新添加默认闹钟');
    
    initialize();
});

// 备用方案，确保在页面完全加载后也能初始化
if (document.readyState === 'complete') {
    console.log('页面已完全加载，开始初始化应用');
    
    // 强制清除本地存储中的闹钟数据，确保添加默认闹钟
    localStorage.removeItem('alarms');
    console.log('已清除闹钟数据，将重新添加默认闹钟');
    
    initialize();
}

// 直接手动添加默认闹钟并渲染（用于调试）
console.log('=== 开始手动添加默认闹钟（调试用） ===');
setTimeout(() => {
    console.log('开始执行手动添加默认闹钟');
    
    // 确保有AlarmManager实例
    if (!window.alarmManager) {
        console.log('AlarmManager不存在，创建新实例');
        window.alarmManager = new AlarmManager();
    }
    
    // 强制清除本地存储中的闹钟数据
    localStorage.removeItem('alarms');
    console.log('已清除本地存储中的闹钟数据');
    
    // 添加默认闹钟
    window.alarmManager.addDefaultAlarms();
    console.log('已手动添加默认闹钟');
    
    // 检查闹钟数量
    console.log('闹钟总数:', window.alarmManager.alarm.alarms.length);
    console.log('置顶闹钟:', window.alarmManager.alarm.getPinnedAlarms().length);
    
    // 强制渲染闹钟列表
    window.alarmManager.renderAlarms();
    console.log('已强制重新渲染闹钟列表');
}, 2000);

// 秒表类
class Stopwatch {
    constructor() {
        this.centiseconds = 0;
        this.interval = null;
        this.isRunning = false;
        this.lapTimes = [];
    }
    
    // 开始秒表
    start() {
        if (this.isRunning) return;
        
        this.isRunning = true;
        const startTime = Date.now() - (this.centiseconds * 10);
        
        this.interval = setInterval(() => {
            const elapsed = Date.now() - startTime;
            this.centiseconds = Math.floor(elapsed / 10);
            this.updateDisplay();
        }, 10); // 每10毫秒更新一次，精确到厘秒
    }
    
    // 暂停秒表
    pause() {
        this.isRunning = false;
        clearInterval(this.interval);
    }
    
    // 重置秒表
    reset() {
        this.pause();
        this.centiseconds = 0;
        this.lapTimes = [];
        this.updateDisplay();
        this.updateLapDisplay();
    }
    
    // 记录分段时间
    lap() {
        const lapTime = this.centiseconds;
        const lastLapTime = this.lapTimes.length > 0 ? this.lapTimes[this.lapTimes.length - 1].total : 0;
        const lapDiff = lapTime - lastLapTime;
        
        this.lapTimes.push({
            number: this.lapTimes.length + 1,
            total: lapTime,
            diff: lapDiff
        });
        
        this.updateLapDisplay();
    }
    
    // 更新显示
    updateDisplay() {
        const display = this.formatTime(this.centiseconds);
        
        const stopwatchDisplay = document.querySelector('.stopwatch-display');
        if (stopwatchDisplay) {
            stopwatchDisplay.textContent = display;
        }
    }
    
    // 更新计次记录显示
    updateLapDisplay() {
        const lapContainer = document.querySelector('#stopwatch-screen .mt-4');
        if (!lapContainer) return;
        
        // 找到"记录"标题后的容器
        const recordsContainer = lapContainer.querySelector('div:not(.section-title)');
        if (!recordsContainer) return;
        
        // 清空现有记录
        recordsContainer.innerHTML = '';
        
        // 如果没有计次记录
        if (this.lapTimes.length === 0) {
            recordsContainer.innerHTML = '<div class="text-center text-muted py-3">暂无记录</div>';
            return;
        }
        
        // 添加每个计次记录
        this.lapTimes.forEach((lap, index) => {
            const lapElement = document.createElement('div');
            lapElement.className = 'preset-item';
            
            lapElement.innerHTML = `
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <h5 class="card-title mb-1">计次 #${lap.number}</h5>
                        <small class="text-muted">${this.formatTime(lap.total)}</small>
                    </div>
                    <span>+${this.formatTime(lap.diff)}</span>
                </div>
            `;
            
            recordsContainer.appendChild(lapElement);
        });
    }
    
    // 格式化时间显示（毫秒转为时:分:秒.厘秒）
    formatTime(centiseconds) {
        const hours = Math.floor(centiseconds / 360000);
        const minutes = Math.floor((centiseconds % 360000) / 6000);
        const seconds = Math.floor((centiseconds % 6000) / 100);
        const cs = centiseconds % 100;
        
        if (hours > 0) {
            return `${hours}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}.${cs.toString().padStart(2, '0')}`;
        } else {
            return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}.${cs.toString().padStart(2, '0')}`;
        }
    }
    
    // 获取当前时间（厘秒）
    getTime() {
        return this.centiseconds;
    }
    
    // 获取所有计次时间
    getLapTimes() {
        return this.lapTimes;
    }
    
    // 获取是否正在运行
    isActive() {
        return this.isRunning;
    }
}

// 闹钟管理器类
class AlarmManager {
    constructor() {
        this.alarm = new Alarm();
        this.alarms = [];
    }
    
    // 加载闹钟
    loadAlarms() {
        console.log('开始加载闹钟');
        
        // 从本地存储加载闹钟
        let needDefaultAlarms = true;
        
        const savedAlarms = localStorage.getItem('alarms');
        if (savedAlarms) {
            try {
                const parsedAlarms = JSON.parse(savedAlarms);
                
                // 检查数据是否有效
                if (Array.isArray(parsedAlarms) && parsedAlarms.length > 0) {
                    // 清空已有的闹钟
                    this.alarm.alarms = [];
                    this.alarms = parsedAlarms;
                    
                    // 将闹钟添加到Alarm类中
                    this.alarms.forEach(a => {
                        this.alarm.addAlarm(a.time, a.days, a.label, a.enabled, a.isPinned);
                    });
                    
                    console.log('成功从本地存储加载了', this.alarm.alarms.length, '个闹钟');
                    needDefaultAlarms = false;
                }
            } catch (e) {
                console.error('解析闹钟数据失败:', e);
            }
        }
        
        // 如果需要默认闹钟（本地存储中没有或解析失败）
        if (needDefaultAlarms) {
            console.log('需要加载默认闹钟');
            // 清空已有的闹钟
            this.alarm.alarms = [];
            this.alarms = [];
            // 添加默认闹钟
            this.addDefaultAlarms();
        } else {
            // 渲染闹钟
            this.renderAlarms();
            
            // 为置顶按钮添加事件
            this.setupPinButtons();
        }
        
        console.log('闹钟加载完成，列表长度:', this.alarm.alarms.length);
    }
    
    // 添加默认的常用置顶闹钟
    addDefaultAlarms() {
        console.log('开始添加默认闹钟');
        
        // 确保Alarm实例存在
        if (!this.alarm) {
            console.error('错误: Alarm实例不存在，创建新实例');
            this.alarm = new Alarm();
        }
        
        // 添加默认闹钟: 早上7点，工作日
        this.alarm.addAlarm('07:00', [1, 2, 3, 4, 5], '起床闹钟', true, true);
        
        // 添加默认闹钟: 早上8点，周末
        this.alarm.addAlarm('08:30', [0, 6], '周末起床', true, false);
        
        // 添加默认闹钟: 中午12点，每天
        this.alarm.addAlarm('12:00', [0, 1, 2, 3, 4, 5, 6], '午餐时间', true, false);
        
        // 保存到本地存储
        this.saveAlarms();
        
        // 渲染闹钟列表
        this.renderAlarms();
        
        // 为置顶按钮添加事件
        this.setupPinButtons();
        
        console.log('默认闹钟添加完成，总数:', this.alarm.alarms.length);
    }
    
    // 添加闹钟
    addAlarm(name, time, days, isPinned = false) {
        const id = this.alarm.addAlarm(time, days, name, true, isPinned);
        this.saveAlarms();
        return id;
    }
    
    // 切换闹钟置顶状态
    togglePinned(id) {
        const isPinned = this.alarm.togglePinned(id);
        this.saveAlarms();
        this.renderAlarms();
        return isPinned;
    }
    
    // 保存闹钟
    saveAlarms() {
        localStorage.setItem('alarms', JSON.stringify(this.alarm.alarms));
    }
    
    // 渲染闹钟列表
    renderAlarms() {
        const alarmScreen = document.getElementById('alarm-screen');
        if (!alarmScreen) return;
        
        // 获取置顶和非置顶闹钟
        const pinnedAlarms = this.alarm.getPinnedAlarms();
        const unpinnedAlarms = this.alarm.getUnpinnedAlarms();
        
        // 渲染置顶闹钟
        let pinnedHtml = '';
        if (pinnedAlarms.length === 0) {
            pinnedHtml = '<div class="text-center text-muted py-3">暂无置顶闹钟</div>';
        } else {
            pinnedAlarms.forEach(alarm => {
                pinnedHtml += this.createAlarmHtml(alarm, true);
            });
        }
        
        // 渲染非置顶闹钟
        let unpinnedHtml = '';
        if (unpinnedAlarms.length === 0) {
            unpinnedHtml = '<div class="text-center text-muted py-3">暂无闹钟</div>';
        } else {
            unpinnedAlarms.forEach(alarm => {
                unpinnedHtml += this.createAlarmHtml(alarm, false);
            });
        }
        
        // 更新DOM
        const pinnedContainer = alarmScreen.querySelector('.pinned-alarms');
        const unpinnedContainer = alarmScreen.querySelector('.other-alarms');
        
        if (pinnedContainer) {
            pinnedContainer.innerHTML = pinnedHtml;
        }
        
        if (unpinnedContainer) {
            unpinnedContainer.innerHTML = unpinnedHtml;
        }
        
        // 重新设置事件监听
        this.setupPinButtons();
        this.setupAlarmToggleButtons();
    }
    
    // 创建闹钟HTML
    createAlarmHtml(alarm, isPinned) {
        // 格式化重复天数
        const daysText = this.formatDays(alarm.days);
        
        return `
            <div class="preset-item${isPinned ? ' pinned-alarm' : ''}" data-id="${alarm.id}">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <div class="form-check form-switch">
                            <input class="form-check-input alarm-toggle" type="checkbox" id="alarm${alarm.id}" 
                                ${alarm.enabled ? 'checked' : ''} data-id="${alarm.id}">
                            <label class="form-check-label" for="alarm${alarm.id}">
                                <h5 class="card-title mb-1">
                                    ${isPinned ? '<i class="bi bi-pin-angle-fill text-primary me-1"></i>' : ''}
                                    ${alarm.label}
                                </h5>
                                <div class="alarm-time">${alarm.time}</div>
                                <small class="text-muted">${daysText}</small>
                            </label>
                        </div>
                    </div>
                    <div>
                        ${!isPinned ? `
                            <button class="btn btn-sm btn-outline-primary me-2 pin-alarm-btn" data-id="${alarm.id}">
                                <i class="bi bi-pin-angle"></i>
                            </button>
                        ` : `
                            <button class="btn btn-sm btn-outline-primary me-2 unpin-alarm-btn" data-id="${alarm.id}">
                                <i class="bi bi-pin-angle-fill"></i>
                            </button>
                        `}
                        <button class="btn btn-sm btn-outline-danger delete-alarm-btn" data-id="${alarm.id}">
                            <i class="bi bi-trash"></i>
                        </button>
                    </div>
                </div>
            </div>
        `;
    }
    
    // 格式化重复天数
    formatDays(days) {
        if (days.length === 0) {
            return '不重复';
        }
        
        if (days.length === 7) {
            return '每天';
        }
        
        if (days.length === 5 && days.includes(1) && days.includes(2) && 
            days.includes(3) && days.includes(4) && days.includes(5)) {
            return '工作日';
        }
        
        if (days.length === 2 && days.includes(0) && days.includes(6)) {
            return '周末';
        }
        
        const dayNames = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
        return days.map(d => dayNames[d]).join('、');
    }
    
    // 设置置顶按钮事件
    setupPinButtons() {
        // 置顶按钮
        document.querySelectorAll('.pin-alarm-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const id = parseInt(e.currentTarget.getAttribute('data-id'));
                this.togglePinned(id);
            });
        });
        
        // 取消置顶按钮
        document.querySelectorAll('.unpin-alarm-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const id = parseInt(e.currentTarget.getAttribute('data-id'));
                this.togglePinned(id);
            });
        });
        
        // 删除按钮
        document.querySelectorAll('.delete-alarm-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const id = parseInt(e.currentTarget.getAttribute('data-id'));
                if (confirm('确定要删除此闹钟吗？')) {
                    this.alarm.removeAlarm(id);
                    this.saveAlarms();
                    this.renderAlarms();
                }
            });
        });
    }
    
    // 设置闹钟启用/禁用按钮事件
    setupAlarmToggleButtons() {
        document.querySelectorAll('.alarm-toggle').forEach(toggle => {
            toggle.addEventListener('change', (e) => {
                const id = parseInt(e.target.getAttribute('data-id'));
                const enabled = e.target.checked;
                this.alarm.toggleAlarm(id, enabled);
                this.saveAlarms();
            });
        });
    }
}

// 显示添加闹钟对话框
function showAddAlarmDialog() {
    // 创建对话框
    const dialog = document.createElement('div');
    dialog.className = 'modal fade';
    dialog.id = 'addAlarmModal';
    dialog.innerHTML = `
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">添加闹钟</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <form>
                        <div class="mb-3">
                            <label for="alarmName" class="form-label">闹钟名称</label>
                            <input type="text" class="form-control" id="alarmName" placeholder="例如：起床闹钟">
                        </div>
                        <div class="mb-3">
                            <label for="alarmTime" class="form-label">时间</label>
                            <input type="time" class="form-control" id="alarmTime" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">重复</label>
                            <div class="d-flex justify-content-between">
                                <div class="form-check">
                                    <input class="form-check-input day-check" type="checkbox" value="0" id="day0">
                                    <label class="form-check-label" for="day0">日</label>
                                </div>
                                <div class="form-check">
                                    <input class="form-check-input day-check" type="checkbox" value="1" id="day1">
                                    <label class="form-check-label" for="day1">一</label>
                                </div>
                                <div class="form-check">
                                    <input class="form-check-input day-check" type="checkbox" value="2" id="day2">
                                    <label class="form-check-label" for="day2">二</label>
                                </div>
                                <div class="form-check">
                                    <input class="form-check-input day-check" type="checkbox" value="3" id="day3">
                                    <label class="form-check-label" for="day3">三</label>
                                </div>
                                <div class="form-check">
                                    <input class="form-check-input day-check" type="checkbox" value="4" id="day4">
                                    <label class="form-check-label" for="day4">四</label>
                                </div>
                                <div class="form-check">
                                    <input class="form-check-input day-check" type="checkbox" value="5" id="day5">
                                    <label class="form-check-label" for="day5">五</label>
                                </div>
                                <div class="form-check">
                                    <input class="form-check-input day-check" type="checkbox" value="6" id="day6">
                                    <label class="form-check-label" for="day6">六</label>
                                </div>
                            </div>
                        </div>
                        <div class="form-check mb-3">
                            <input class="form-check-input" type="checkbox" id="isPinned">
                            <label class="form-check-label" for="isPinned">
                                置顶闹钟
                            </label>
                        </div>
                    </form>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">取消</button>
                    <button type="button" class="btn btn-primary" id="saveAlarm">保存</button>
                </div>
            </div>
        </div>
    `;
    
    // 添加到文档
    document.body.appendChild(dialog);
    
    // 初始化Bootstrap模态框
    const modal = new bootstrap.Modal(dialog);
    modal.show();
    
    // 设置工作日复选框默认选中
    for (let i = 1; i <= 5; i++) {
        document.getElementById(`day${i}`).checked = true;
    }
    
    // 保存按钮事件
    document.getElementById('saveAlarm').addEventListener('click', () => {
        const name = document.getElementById('alarmName').value || '闹钟';
        const time = document.getElementById('alarmTime').value;
        
        if (!time) {
            alert('请设置闹钟时间！');
            return;
        }
        
        // 获取选中的星期几
        const days = [];
        document.querySelectorAll('.day-check').forEach(checkbox => {
            if (checkbox.checked) {
                days.push(parseInt(checkbox.value));
            }
        });
        
        if (days.length === 0) {
            alert('请至少选择一天！');
            return;
        }
        
        const isPinned = document.getElementById('isPinned').checked;
        
        // 添加闹钟
        if (window.alarmManager) {
            // 格式化时间 (HH:MM:SS -> HH:MM)
            const formattedTime = time.split(':').slice(0, 2).join(':');
            
            // 添加闹钟
            window.alarmManager.alarm.addAlarm(formattedTime, days, name, true, isPinned);
            
            // 保存到本地存储
            window.alarmManager.saveAlarms();
            
            // 重新渲染闹钟列表
            window.alarmManager.renderAlarms();
            
            // 重新设置按钮事件
            window.alarmManager.setupPinButtons();
        }
        
        // 关闭对话框
        modal.hide();
        
        // 清理DOM
        setTimeout(() => {
            document.body.removeChild(dialog);
        }, 500);
    });
}

// 闹钟类
class Alarm {
    constructor() {
        this.alarms = [];
        this.nextId = 1;
        this.alarmCheckInterval = null;
    }
    
    // 获取系统当前的格式化时间
    getCurrentTime() {
        const now = new Date();
        const hours = now.getHours().toString().padStart(2, '0');
        const minutes = now.getMinutes().toString().padStart(2, '0');
        return `${hours}:${minutes}`;
    }
    
    // 获取当前是星期几
    getCurrentDay() {
        const now = new Date();
        return now.getDay(); // 0 是周日，1-6 是周一到周六
    }
    
    // 添加闹钟
    addAlarm(time, days, label, enabled = true, isPinned = false) {
        const id = this.nextId++;
        
        this.alarms.push({
            id,
            time,
            days,
            label,
            enabled,
            isPinned
        });
        
        this.startAlarmCheck();
        
        return id;
    }
    
    // 删除闹钟
    removeAlarm(id) {
        this.alarms = this.alarms.filter(alarm => alarm.id !== id);
        
        if (this.alarms.length === 0) {
            this.stopAlarmCheck();
        }
        
        return true;
    }
    
    // 启用/禁用闹钟
    toggleAlarm(id, enabled) {
        const alarm = this.alarms.find(a => a.id === id);
        if (alarm) {
            alarm.enabled = enabled;
            
            if (enabled && !this.alarmCheckInterval) {
                this.startAlarmCheck();
            } else if (!enabled && this.alarms.every(a => !a.enabled)) {
                this.stopAlarmCheck();
            }
            
            return true;
        }
        return false;
    }
    
    // 切换置顶状态
    togglePinned(id) {
        const alarm = this.alarms.find(a => a.id === id);
        if (alarm) {
            alarm.isPinned = !alarm.isPinned;
            return alarm.isPinned;
        }
        return false;
    }
    
    // 获取所有置顶闹钟
    getPinnedAlarms() {
        return this.alarms.filter(a => a.isPinned);
    }
    
    // 获取所有非置顶闹钟
    getUnpinnedAlarms() {
        return this.alarms.filter(a => !a.isPinned);
    }
    
    // 启动闹钟检查
    startAlarmCheck() {
        if (this.alarmCheckInterval) {
            return;
        }
        
        // 每分钟检查一次所有闹钟
        this.alarmCheckInterval = setInterval(() => {
            this.checkAlarms();
        }, 60000); // 60秒检查一次
        
        // 立即进行一次检查
        this.checkAlarms();
    }
    
    // 停止闹钟检查
    stopAlarmCheck() {
        if (this.alarmCheckInterval) {
            clearInterval(this.alarmCheckInterval);
            this.alarmCheckInterval = null;
        }
    }
    
    // 检查闹钟是否应该触发
    checkAlarms() {
        const currentTime = this.getCurrentTime();
        const currentDay = this.getCurrentDay();
        
        console.log(`检查闹钟: 当前时间 ${currentTime}, 星期 ${currentDay}`);
        
        this.alarms.forEach(alarm => {
            if (alarm.enabled && alarm.time === currentTime && alarm.days.includes(currentDay)) {
                this.triggerAlarm(alarm);
            }
        });
    }
    
    // 触发闹钟
    triggerAlarm(alarm) {
        console.log(`闹钟触发: ${alarm.label} (${alarm.time})`);
        
        // 显示通知
        this.showNotification(alarm);
        
        // 播放声音
        this.playAlarmSound();
    }
    
    // 显示通知
    showNotification(alarm) {
        // 先使用系统通知
        if ('Notification' in window) {
            if (Notification.permission === 'granted') {
                try {
                    new Notification(alarm.label, {
                        body: alarm.label,
                        icon: 'icon-192.png',
                        vibrate: [200, 100, 200]
                    });
                } catch (e) {
                    console.error('通知创建失败:', e);
                    // 失败时使用alert作为备选方案
                    alert(`${alarm.label}: 时间到!`);
                }
            } else if (Notification.permission !== 'denied') {
                // 尝试请求权限
                Notification.requestPermission().then(permission => {
                    if (permission === 'granted') {
                        showNotification(alarm.label, alarm.label);
                    } else {
                        // 如果拒绝了权限，使用alert
                        alert(`${alarm.label}: 时间到!`);
                    }
                });
            } else {
                // 如果通知权限被拒绝，使用alert
                alert(`${alarm.label}: 时间到!`);
            }
        } else {
            // 如果浏览器不支持通知，使用alert
            alert(`${alarm.label}: 时间到!`);
        }
        
        // 同时播放声音
        playCompletionSound();
    }
    
    // 播放闹钟声音
    playAlarmSound() {
        const audio = document.createElement('audio');
        audio.src = 'audio/alarm.mp3';
        audio.loop = true;
        audio.id = 'alarm-sound';
        audio.play().catch(e => console.error('播放声音失败:', e));
        
        document.body.appendChild(audio);
    }
    
    // 停止闹钟声音
    stopAlarmSound() {
        const audio = document.getElementById('alarm-sound');
        if (audio) {
            audio.pause();
            audio.remove();
        }
    }
}

// 初始化导航功能
function initNavigation() {
    const navButtons = document.querySelectorAll('.nav-btn');
    const screens = document.querySelectorAll('.screen');
    
    navButtons.forEach(button => {
        button.addEventListener('click', () => {
            // 获取目标屏幕ID
            const targetScreenId = button.getAttribute('data-screen');
            const targetScreen = document.getElementById(targetScreenId);
            
            if (!targetScreen) return;
            
            // 隐藏所有屏幕
            screens.forEach(screen => {
                screen.classList.remove('active');
            });
            
            // 显示目标屏幕
            targetScreen.classList.add('active');
            
            // 更新导航按钮状态
            navButtons.forEach(btn => {
                btn.classList.remove('active');
            });
            button.classList.add('active');
        });
    });
}

// 初始化设置选项
function initializeSettingsOptions() {
    // 通知设置按钮
    const notificationSettingBtn = document.querySelector('.list-group-item:nth-child(2)');
    if (notificationSettingBtn) {
        notificationSettingBtn.addEventListener('click', () => {
            requestNotificationPermission();
            alert('已请求通知权限');
        });
    }
    
    // 提示音设置按钮
    const soundSettingBtn = document.querySelector('.list-group-item:nth-child(3)');
    if (soundSettingBtn) {
        soundSettingBtn.addEventListener('click', () => {
            alert('提示音设置功能开发中');
        });
    }
    
    // 帮助中心按钮
    const helpBtn = document.querySelector('.list-group-item:nth-child(4)');
    if (helpBtn) {
        helpBtn.addEventListener('click', () => {
            alert('帮助中心功能开发中');
        });
    }
    
    // 关于应用按钮
    const aboutBtn = document.querySelector('.list-group-item:nth-child(5)');
    if (aboutBtn) {
        aboutBtn.addEventListener('click', () => {
            alert('计时器 v1.0.0\n一个简单的时间管理工具');
        });
    }
}

// 播放完成声音
function playCompletionSound() {
    const audio = new Audio('audio/completion-sound.mp3');
    audio.play().catch(e => console.error('播放完成提示音失败:', e));
}

// 显示通知
function showNotification(title, body) {
    // 先使用系统通知
    if ('Notification' in window) {
        if (Notification.permission === 'granted') {
            try {
                new Notification(title, {
                    body: body,
                    icon: 'icon-192.png',
                    vibrate: [200, 100, 200]
                });
            } catch (e) {
                console.error('通知创建失败:', e);
                // 失败时使用alert作为备选方案
                alert(`${title}: ${body}`);
            }
        } else if (Notification.permission !== 'denied') {
            // 尝试请求权限
            Notification.requestPermission().then(permission => {
                if (permission === 'granted') {
                    showNotification(title, body);
                } else {
                    // 如果拒绝了权限，使用alert
                    alert(`${title}: ${body}`);
                }
            });
        } else {
            // 如果通知权限被拒绝，使用alert
            alert(`${title}: ${body}`);
        }
    } else {
        // 如果浏览器不支持通知，使用alert
        alert(`${title}: ${body}`);
    }
    
    // 同时播放声音
    playCompletionSound();
}

// 添加秒表初始化函数
function initStopwatch(stopwatch) {
    const stopwatchScreen = document.getElementById('stopwatch-screen');
    if (!stopwatchScreen) return;
    
    // 获取按钮元素
    const resetBtn = stopwatchScreen.querySelector('.action-btn:nth-child(1)');
    const startPauseBtn = stopwatchScreen.querySelector('.action-btn:nth-child(2)');
    const lapBtn = stopwatchScreen.querySelector('.action-btn:nth-child(3)');
    
    if (!resetBtn || !startPauseBtn || !lapBtn) return;
    
    // 重置按钮事件
    resetBtn.addEventListener('click', () => {
        stopwatch.reset();
        
        // 更新开始/暂停按钮状态
        startPauseBtn.innerHTML = '<i class="bi bi-play-fill"></i>';
        startPauseBtn.classList.remove('btn-secondary');
        startPauseBtn.classList.add('btn-primary');
        
        // 清空计次记录区域
        const recordsContainer = stopwatchScreen.querySelector('.mt-4 div:not(.section-title)');
        if (recordsContainer) {
            recordsContainer.innerHTML = '<div class="text-center text-muted py-3">暂无记录</div>';
        }
    });
    
    // 开始/暂停按钮事件
    startPauseBtn.addEventListener('click', () => {
        if (stopwatch.isActive()) {
            stopwatch.pause();
            startPauseBtn.innerHTML = '<i class="bi bi-play-fill"></i>';
            startPauseBtn.classList.remove('btn-secondary');
            startPauseBtn.classList.add('btn-primary');
        } else {
            stopwatch.start();
            startPauseBtn.innerHTML = '<i class="bi bi-pause-fill"></i>';
            startPauseBtn.classList.remove('btn-primary');
            startPauseBtn.classList.add('btn-secondary');
        }
    });
    
    // 计次按钮事件
    lapBtn.addEventListener('click', () => {
        if (stopwatch.isActive()) {
            stopwatch.lap();
        }
    });
    
    // 确保初始状态正确
    stopwatch.updateDisplay();
    
    // 创建记录区域的容器
    const recordsSection = stopwatchScreen.querySelector('.mt-4');
    if (recordsSection) {
        // 检查是否已经有记录容器
        if (!recordsSection.querySelector('div:not(.section-title)')) {
            const recordsContainer = document.createElement('div');
            recordsContainer.innerHTML = '<div class="text-center text-muted py-3">暂无记录</div>';
            recordsSection.appendChild(recordsContainer);
        }
    }
}
