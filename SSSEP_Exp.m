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

samplerate = 500;

%% COLLECT SOME INFO
% Construct a questdlg with three options
choice = questdlg('実験を開始しますか?', ...
    '参加者情報', ...
    'デモ','本番','キャンセル','キャンセル');
% Handle response
eye_flag = 1;
switch choice
    case 'デモ'
        demo_flag = 1;
        if eye_flag == 2
            return;
        end
    case '本番'
        demo_flag = 2;
        
        gender = QuestionDlgForGender();
        age = choosedialogForAge([20 40]);
        
    case 'キャンセル'
        demo_flag = 1;
        return;
end

%% Load the iViewX API library and connect to the server
if eye_flag
    addpath('SMI/');
    InitAndConnectiViewXAPI
end
%% --- 前準備:
load('newPairdata.mat');

dat_dir = 'data/';
% 実験変数
% 各条件の試行数xセット数が各条件の全試行数
N_trial = size(Pairdata, 2);          % 1setあたり何試行するか
N_set = size(Pairdata, 1);      % 何セットやるか

% set KeyInfo
escapeKey = KbName('ESCAPE');
spaceKey = KbName('space');
returnKey = KbName('return');
NumKey4 = KbName('4');
NumKey5 = KbName('5');
NumKey6 = KbName('6');

%%

Task_label = {
    'like';
    'dislike';
    };

%% make order-data
numStim = 1;
tmp_order = [];
for i_set = 1:size(Pairdata, 1)
    for i_stim = 1:size(Pairdata, 2)
        tmp_order{i_set}(i_stim).ID = numStim;
        tmp_order{i_set}(i_stim).Condition = i_set;
        tmp_order{i_set}(i_stim).Source = Pairdata{i_set, i_stim};
        numStim = numStim + 1;
    end
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
StimulusSize = 10; % degree

StimtoStimDistance = 15; % degree
StimDistanceFromCenter = StimtoStimDistance/2; % degree

%% --- subject data
switch demo_flag
    case 1
        subject.name = 'demo';
        subject.sex = 0;    % male:0, female:1
    case 2
        EXPID = 'E02_EXP03_S08_';
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
    %     [window, windowRect] = Screen('OpenWindow', screenNumber, gray);
    copyWindow = Screen('OpenOffscreenWindow', screenNumber, windowRect);
    
    % Coordinates of the center of the screen
    [centerPos(1), centerPos(2)] = RectCenter(windowRect);
    
    [width, height] = Screen('WindowSize', window);
    
    %
    StimSize = VisualAngleToVisualSize(StimulusSize, VisualDistance, device_type, [width, height]);
    stim_X1 = centerPos(1) - StimSize(1)/2;
    stim_Y1 = centerPos(2) - StimSize(2)/2;
    
    Stim_cor = [stim_X1 stim_Y1 stim_X1 stim_Y1];
    
    %
    StimtoStimDistance = VisualAngleToVisualSize(StimDistanceFromCenter, VisualDistance, device_type, [width, height]);
    stim_centerpos(1, 1) = centerPos(1) - StimtoStimDistance(1) - StimSize(1)/2;
    stim_centerpos(1, 2) = centerPos(2) - StimSize(2)/2;
    stim_centerpos(1, 3) = centerPos(1) - StimtoStimDistance(1) + StimSize(1)/2;
    stim_centerpos(1, 4) = centerPos(2) + StimSize(2)/2;
    
    stim_centerpos(2, 1) = centerPos(1) + StimtoStimDistance(1) - StimSize(1)/2;
    stim_centerpos(2, 2) = centerPos(2) - StimSize(2)/2;
    stim_centerpos(2, 3) = centerPos(1) + StimtoStimDistance(1) + StimSize(1)/2;
    stim_centerpos(2, 4) = centerPos(2) + StimSize(2)/2;
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
            if strcmpi(allFonts(idx).name, 'Hiragino Kaku Gothic Pro W3')
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
    
    % Use realtime priority for better timing precision:
    priorityLevel = MaxPriority(window);
    Priority(priorityLevel);
    
    %% --- 呈示開始
    disp('=================== Questionarie ===================');
    fprintf('date    : %s\n',date);
    fprintf('subject : %s\n',subject.name);
    tic;
    tstart = tic;
    
    for i_set = 1:N_set
        
        %% --- セッションの始め:
        disp('====================');
        fprintf('\n---------- Set%d ----------\n' , i_set);
        if eye_flag
            disp('==========CALIBRATION START==========');
            if connected
                
                disp('Get System Info Data')
                ret_sys = iView.iV_GetSystemInfo(pSystemInfoData);
                
                if (ret_sys == 1 )
                    
                    disp(pSystemInfoData.Value)
                    samplerate = pSystemInfoData.Value.samplerate;
                else
                    
                    msg = 'System Information could not be retrieved';
                    disp(msg);
                    
                end
                
                %% Calibration
                disp('Calibrate iViewX')
                ret_setCal = iView.iV_SetupCalibration(pCalibrationData);
                
                if (ret_setCal == 1 )
                    
                    ret_cal = iView.iV_Calibrate();
                    
                    if (ret_cal == 1 )
                        
                        disp('Validate Calibration')
                        ret_val = iView.iV_Validate();
                        
                        if (ret_val == 1 )
                            
                            disp('Show Accuracy')
                            ret_acc = iView.iV_GetAccuracy(pAccuracyData, int32(0));
                            
                            if (ret_acc == 1 )
                                
                                disp(pAccuracyData.Value)
                                
                            else
                                
                                msg = 'Accuracy could not be retrieved';
                                disp(msg);
                            end
                            
                        else
                            msg = 'Error during validation';
                            disp(msg);
                            
                        end
                        
                    else
                        
                        msg = 'Error during calibration';
                        disp(msg);
                    end
                else
                    msg = 'Calibration data could not be set up';
                    disp(msg);
                end
            end
            disp('==========CALIBRATION END==========');
            
        end
        set_tstart = tic;
        
        %% --- message
        Screen('TextSize', window, fontSize);
        Screen('FillRect', window, gray); % 背景
        DrawFormattedText(window, double(['Please press to start the session.\nwhich one do you ', Task_label{i_set}, '?']), 'center', 'center', white);
        Screen('Flip', window); % To present a message on the screen
        %         ListenChar(2); % Disable the key input to the Matlab
        
        face_list = tmp_order{i_set};
        order = face_list(randperm(length(face_list)));
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
        for i_trial = 1:N_trial
            
            fprintf('%3d/%d\n', i_trial, N_trial);
            
            %% 顔を描画
            
            for i_face = 1:length(order(i_trial).Source)
                Screen('FillRect', copyWindow, gray); % 背景
                Screen('FillRect', window, gray); % 背景
                Screen('FrameOval', window, [0 0 0], order(i_trial).Source(i_face).Position{1}.* repmat(StimSize, [1 2]) + Stim_cor, 3, 3);
                
                for i_cir = 2:size(order(i_trial).Source(i_face).Position, 2)
                    Screen('FillOval', window, [0 0 0], order(i_trial).Source(i_face).Position{i_cir}.* repmat(StimSize, [1 2]) + Stim_cor);
                end
                
                Screen('CopyWindow',window, copyWindow)
                % 描画された画像を配列に
                imageArray = Screen('GetImage', copyWindow, order(i_trial).Source(i_face).Position{1}.* repmat(StimSize, [1 2]) + Stim_cor);
                facetex{i_face} = Screen('MakeTexture', window, imageArray);
            end
            
            %% Presentation of the fixation point
            count=1;
            L = [];
            R = [];
            timeStamp = [];
            fixData=[];
            
            Screen('FillRect', window, gray); % 背景
            Screen('DrawLines', window, fixApex, 4, white, centerPos, 0);
            vbl1 = Screen('Flip', window);
            timeforfix = GetSecs;
            if eye_flag
                FirstGetSample
            end
            while GetSecs - timeforfix < fixTime
                if eye_flag
                    %% Get Gaze Samples
                    if connected
                        GetSampleEye
                        pause(1/samplerate);
                    end
                end
            end
            if eye_flag
                fixData.L = L;
                fixData.R = R;
                fixData.time = timeStamp;
                tmp_time = timeStamp - repmat(timeStamp(1), size(timeStamp));
                fixData.correctedTime = round(tmp_time/1000, 0)/1000;
            end
            %% 刺激onset
            Screen('FillRect', window, gray); % 背景
            face_posi = randperm(length(order(i_trial).Source));
            for i_face = 1:length(order(i_trial).Source)
                Screen('DrawTexture', window, facetex{face_posi(i_face)}, [], stim_centerpos(i_face, :), order(i_trial).Source(i_face).Orientation * 180);
            end
            vbl2 = Screen('Flip', window);
            
            Res = 0;
            count=1;
            L = [];
            R = [];
            timeStamp = [];
            if eye_flag
                FirstGetSample
            end
            while 1
                if eye_flag
                    GetSampleEye
                end
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
                elseif ( keyCode(NumKey4) )
                    Res = 1;
                    break;
                elseif ( keyCode(NumKey5) )
                    Res = 2;
                    break;
                end
                
            end
            
            %%
            vbl3 = Screen('Flip', window);
            
            order_data(i_trial).Res = Res;
            order_data(i_trial).Fix = vbl2 - vbl1;
            order_data(i_trial).RT = vbl3 - vbl2;                 % リアクションタイム
            if eye_flag
                order_data(i_trial).L_eye = L;
                order_data(i_trial).R_eye = R;
                order_data(i_trial).fixData = fixData;
                order_data(i_trial).time = timeStamp;
                tmp_time = timeStamp - repmat(timeStamp(1), size(timeStamp));
                order_data(i_trial).correctedTime = round(tmp_time/1000, 0)/1000;
            end
            Screen('FillRect', window, gray); % 背景
            %             DrawFormattedText(window, double('Please press to start the session.'), 'center', 'center', white);
            while KbCheck; end
            KbWait;
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
        GetClicks;
    end
    
    %% Unload the iViewX API library and disconnect from the server
    if eye_flag
        UnloadiViewXAPI
    end
    Screen('CloseAll');
    Priority(0);
catch
    %this "catch" section executes in case of an error in the "try" section
    %above.  Importantly, it closes the onscreen window if its open.
    Screen('CloseAll');
    Priority(0);
    psychrethrow(psychlasterror);
    %% Unload the iViewX API library and disconnect from the server
    if eye_flag
        UnloadiViewXAPI
    end
end %try..catch..
%%
if demo_flag == 2
    save(char(strcat(new_dirname,'/subject')), 'subject');
end

disp('======================================================');
toc(tstart);

