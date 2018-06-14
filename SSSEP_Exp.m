%% --- Experiment for SSSEP
% Author: Yuji NIHEI

clear;
close all;
clc;
warning('off', 'all');
Screen('Preference', 'SkipSyncTests', 1);
KbName('UnifyKeyNames');
myKeyCheck;

device_type = 1; %1:viewpixx, 2:desktop(dr.room), 3:surface, 4:dell(SMI)

stimulationTime = 10



; % secs

NumRepTrial = 3;

P_SIZE = 1;                     % ViewPixx用トリガー用の左上正方形の大きさ設定

%% For Audio output
reqlatencyclass = 2;
latbias = [];
waitframes = [];
exactstart = 1;
buffersize = 0;     % Pointless to set this. Auto-selected to be optimal.
suggestedLatencySecs = [];

%% COLLECT SOME INFO
% Construct a questdlg with three options
choice = questdlg('実験を開始しますか?', ...
    '参加者情報', ...
    'デモ','本番','キャンセル','キャンセル');
% Handle response
switch choice
    case 'デモ'
        demo_flag = 1;
    case '本番'
        demo_flag = 2;
        gender = QuestionDlgForGender();
        age = choosedialogForAge([20 40]);
        
    case 'キャンセル'
        demo_flag = 1;
        return;
end

%% --- 前準備:

dat_dir = 'data/';
% 実験変数
% 各条件の試行数xセット数が各条件の全試行数

% set KeyInfo
escapeKey = KbName('ESCAPE');
spaceKey = KbName('space');
returnKey = KbName('return');
NumKey4 = KbName('4');
NumKey5 = KbName('5');
NumKey6 = KbName('6');

%%

Position_label = {
    'Finger';
    'Hand';
    'List';
    };

Stimulation_label = {
    'Sine';
    'Square';
    };

Frequency_label = [
    14;
    20;
    30;
    ];

%%

% Requested output frequency, may need adaptation on some audio-hw:
freq = 44100;       % Must set this. 96khz, 48khz, 44.1khz.
buffersize = 0;     % Pointless to set this. Auto-selected to be optimal.
suggestedLatencySecs = [];

NumLength = 1;

t = [0:1/freq:NumLength];

bf = 100;

by = sin(2*pi*bf*t);

squarewave = (square(2*pi*Frequency_label*t)+1)/2;
sinewave = sin(2*pi*Frequency_label*t);

soundwave{1} = sinewave;
soundwave{2} = squarewave;

for n_stim = 1:length(Stimulation_label)
    for n_freq = 1:length(Frequency_label)
        mynoise{n_stim, n_freq}(1,:) = soundwave{n_stim}(n_freq, :);
        mynoise{n_stim, n_freq}(2,:) = soundwave{n_stim}(n_freq, :);
        
        % bufferhandle{n_stim, n_freq} = PsychPortAudio('CreateBuffer', [], mynoise);
    end
end

new_mynoise = reshape(mynoise, 1, length(Frequency_label)*length(Stimulation_label));

%% make order-data
numStim = 1;
NumOfCondtion = length(Frequency_label)*length(Stimulation_label);
tmp_order = [];
for i_set = 1:length(Position_label)
    for i_stim = 1:NumOfCondtion
        tmp_order(i_stim).ID = i_stim;
        tmp_order(i_stim).Condition = i_stim+i_set*10;
        tmp_order(i_stim).sounds = new_mynoise{i_stim};
        tmp_order(i_stim).trgcol = getVPixxTriggerValue(tmp_order(i_stim).Condition);
    end
    tmp_order2{i_set} = repmat(tmp_order, [1, NumRepTrial]);
end

%% --- fixation point
fixLength = 30; %fixation line length?pixel?
% coordinate of fixation
fixApex = [
    fixLength/2, -fixLength/2, 0, 0;
    0, 0, fixLength/2, -fixLength/2];

fontSize = 30; % fontsize
fixTime = 0.5;
%% Stimuli infomation

VisualDistance = 60; % cm


%% --- subject data
switch demo_flag
    case 1
        subject.name = 'demo';
        subject.sex = 0;    % male:0, female:1
    case 2
        EXPID = 'E02_EXP04_S01_';
        datenum = fix(clock);
        %         datestr = sprintf('%d%02d%02d%02d%02d',datenum(1), datenum(2), datenum(3), datenum(4), datenum(5));
        datestr = sprintf('%s%d%02d%02d',EXPID, datenum(1)-2000, datenum(2), datenum(3));
        subject.name = datestr;
        subject.sex = gender;    % male:1, female:0
        subject.age = age;    % male:1, female:0
        new_dirname = strcat('data/', datestr);
        mkdir(new_dirname);
end

%% CREATE DIRECTORIES
save_dir='DATA/';               %be careful putting the slash at the end
subject_path=[subject.name '/'];                %be careful putting the slash at the end

if isempty(dir(save_dir))
    mkdir(save_dir)
end

if isempty(dir([save_dir subject_path]))
    mkdir([save_dir subject_path])
end

%% --- PTB 実験開始:
try
    %% Initilize
    AssertOpenGL;
    PsychDefaultSetup(2);
    %     HideCursor;
    %% --- Open Graphic window:
    
    screens = Screen('Screens');
    screenNumber = max(screens);
    %     screenNumber = 1;
    
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    
    gray = round((white+black)/2);
    
    if gray == white
        gray = white / 2;
    end
    
    [window, windowRect]  =  PsychImaging('OpenWindow', screenNumber, gray);
    
    ifi = Screen('GetFlipInterval', window);
    
    % Coordinates of the center of the screen
    [centerPos(1), centerPos(2)] = RectCenter(windowRect);
    
    [width, height] = Screen('WindowSize', window);
    
    %
    %% --- フォント設定:
    % Font setting
    if IsWin
        %Screen('TextFont', windowPtr, 'meiryo');
        Screen('TextFont', window, 'Courier New');
    end
    
    if IsOSX
        % See DrawHighQualityUnicodeTextDemo
        allFonts = FontInfo('Fonts');
        foundfont = 0;
        for idx = 1:length(allFonts)
            %if strcmpi(allFonts(idx).name, 'Hiragino Mincho Pro W3')
            if strcmpi(allFonts(idx).name, 'Hiragino Maru Gothic ProN W4')
                foundfont = 1;
                break;
            end
        end
        if ~foundfont
            error('Could not find wanted japanese font on OS/X !');
        end
        Screen('TextFont', window, allFonts(idx).number);
    end
    % ------------------------------
    if IsARM
        % ARM processor, probably the RaspberryPi SoC. This can not quite handle the
        % low latency settings of a Intel PC, so be more lenient:
        suggestedLatencySecs = 0.025;
        if isempty(latbias)
            latbias = 0.000593;
            fprintf('Choosing a latbias setting of 0.000593 secs or 0.593 msecs, assuming this is a RaspberryPi ARM SoC.\n');
        end
        fprintf('Choosing a high suggestedLatencySecs setting of 25 msecs to account for lower performing ARM SoC.\n');
    end
    
    if IsWin
        % Hack to accomodate bad Windows systems or sound cards. By default,
        % the more aggressive default setting of something like 5 msecs can
        % cause sound artifacts on cheaper / less pro sound cards:
        suggestedLatencySecs = 0.015;
        fprintf('Choosing a high suggestedLatencySecs setting of 15 msecs to account for shoddy Windows operating system.\n');
        fprintf('For low-latency applications, you may want to tweak this to lower values if your system works better than average timing-wise.\n');
    end
    
    % Open audio device for low-latency output:
    pahandle = PsychPortAudio('Open', -1, [], reqlatencyclass, freq, 2, buffersize, suggestedLatencySecs);
    
    % Tell driver about hardwares inherent latency, determined via calibration
    % once:
    prelat = PsychPortAudio('LatencyBias', pahandle, latbias);
    postlat = PsychPortAudio('LatencyBias', pahandle);
    
    % Use realtime priority for better timing precision:
    priorityLevel = MaxPriority(window);
    Priority(priorityLevel);
    
    % Set waitframes to a good default, if none is provided by user:
    if isempty(waitframes)
        % We try to choose a waitframes that maximizes the chance of hitting
        % the onset deadline. We are conservative in our estimate, because a
        % few video refresh cycles hardly matter for this test, but increase
        % our chance of success without need for manual tuning by user:
        if isempty(suggestedLatencySecs)
            % Let's assume 12 msecs on Linux and OSX as a achievable latency by
            % default, then double it:
            waitframes = ceil((2 * 0.012) / ifi) + 1;
        else
            % Whatever was provided, then double it:
            waitframes = ceil((2 * suggestedLatencySecs) / ifi) + 1;
        end
    end
    
    %% --- 呈示開始
    disp('=================== Questionarie ===================');
    fprintf('date    : %s\n',date);
    fprintf('subject : %s\n',subject.name);
    tic;
    tstart = tic;
    
    for i_set = 1:length(Position_label)
        
        %% --- セッションの始め:
        disp('====================');
        fprintf('\n---------- Set%d ----------\n Device position is %sn' , i_set, Position_label{i_set});
        
        set_tstart = tic;
        
        %% --- message
        Screen('TextSize', window, fontSize);
        Screen('FillRect', window, gray); % 背景
        DrawFormattedText(window, double(['Please press to start the session.']), 'center', 'center', white);
        Screen('Flip', window); % To present a message on the screen
        %         ListenChar(2); % Disable the key input to the Matlab
        
        stim_list = tmp_order2{i_set};
        order = stim_list(randperm(length(stim_list)));
        order_data = order;
        
        while 1
            
            [x, y, buttons] = GetMouse;
            if buttons(1) || buttons(2) || buttons(3)
                while any(buttons)
                    [x, y, buttons] = GetMouse;
                end
                break;
            end
            
            clear keyCode;
            [keyIsDown,secs,keyCode] = KbCheck;
            % ESCEPEで中断
            if (keyCode(escapeKey) )
                Screen('CloseAll');
                ListenChar(0);
                return
            elseif ( keyCode(returnKey) )
                break;
            end
            
        end
        
        %% 呈示
        for i_trial = 1:length(order)
            fprintf('%3d/%d\n', i_trial, length(order));
            
            PsychPortAudio('FillBuffer', pahandle, order(i_trial).sounds);
            
            Screen('FillRect', window, gray); % 背景
            
            vbl1 = Screen('Flip', window);
            
            tWhen = vbl1 + (waitframes - 0.5) * ifi;
            
            tPredictedVisualOnset = PredictVisualOnsetForTime(window, tWhen);
            PsychPortAudio('Start', pahandle, stimulationTime, tPredictedVisualOnset, 0);
            
            %% 刺激onset
            Screen('FillRect', window, gray); % 背景
            Screen('DrawLines', window, fixApex, 4, white, centerPos, 0);
            Screen('FillRect', window, order(i_trial).trgcol ,[0,0, P_SIZE,P_SIZE]);
            
            [vbl2 visual_onset t1] = Screen('Flip', window, tWhen);
            
            t2 = GetSecs;
            
            % Spin-Wait until hw reports the first sample is played...
            offset = 0;
            while offset == 0
                status = PsychPortAudio('GetStatus', pahandle);
                offset = status.PositionSecs;
                t3=GetSecs;
                plat = status.PredictedLatency;
                fprintf('Predicted Latency: %6.6f msecs.\n', plat*1000);
                if offset>0
                    break;
                end
                WaitSecs('YieldSecs', 0.001);
            end
            
            audio_onset = status.StartTime;
            
            % Stop playback:
            PsychPortAudio('Stop', pahandle, 1);
            
            Screen('FillRect', window, gray);
            telapsed = Screen('Flip', window) - visual_onset;
            
            order_data(i_trial).vbl = vbl2 - vbl1;
            order_data(i_trial).Flipdelay = vbl2 - vbl1;                 % リアクションタイム
            
            Screen('FillRect', window, gray); % 背景
            
            GetClicks;
        end
        toc(set_tstart);
        
        tmp_all{i_set} = order_data;
        
        if demo_flag == 2
            save(char(strcat(new_dirname,'/set',num2str(i_set))), 'order_data', 'stim_centerpos');
            save(char(strcat(new_dirname,'/order_set',num2str(i_set))), 'order');
        end
        clear order_data;
        
        Screen('FillRect', window, gray); % 背景
        DrawFormattedText(window, double('finish the this session'), 'center', 'center', white);
        Screen('Flip', window); % To present a message on the screen
        
        while 1
            
            [x, y, buttons] = GetMouse;
            if buttons(1) || buttons(2) || buttons(3)
                while any(buttons)
                    [x, y, buttons] = GetMouse;
                end
                break;
            end
            
            clear keyCode;
            [keyIsDown,secs,keyCode] = KbCheck;
            % ESCEPEで中断
            if (keyCode(escapeKey) )
                Screen('CloseAll');
                ListenChar(0);
                return
            elseif ( keyCode(returnKey) )
                break;
            end
            
        end
        
    end
    
    PsychPortAudio('Close');
    Screen('CloseAll');
    Priority(0);
catch
    %this "catch" section executes in case of an error in the "try" section
    %above.  Importantly, it closes the onscreen window if its open.
    PsychPortAudio('Close');
    Screen('CloseAll');
    Priority(0);
    psychrethrow(psychlasterror);
end %try..catch..
%%
if demo_flag == 2
    save(char(strcat(new_dirname,'/subject')), 'subject');
end

disp('======================================================');
toc(tstart);

