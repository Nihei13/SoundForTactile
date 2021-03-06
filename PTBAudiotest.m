close all
clear all
Screen('Preference', 'SkipSyncTests', 1);

deviceid = -1;

% Request latency mode 2, which used to be the best one in our measurement:
% classes 3 and 4 didn't yield any improvements, sometimes they even caused
% problems.
reqlatencyclass = 2;
latbias = [];
waitframes = [];
exactstart = 1;
buffersize = 0;     % Pointless to set this. Auto-selected to be optimal.
suggestedLatencySecs = [];

% Requested output frequency, may need adaptation on some audio-hw:
freq = 44100;       % Must set this. 96khz, 48khz, 44.1khz.

NumLength = 1;
stimulationTime = 5; % secs

t = [0:1/freq:NumLength];

bf = 100;

by = sin(2*pi*bf*t);

soundfreq = [14 20 30];

squarewave = (square(2*pi*soundfreq'*t)+1)/2;
sinewave = sin(2*pi*soundfreq'*t);

sound{1} = sinewave;
sound{2} = squarewave;

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

if isempty(latbias)
    % Unknown system: Assume zero bias. User can override with measured
    % values:
    fprintf('No "latbias" provided. Assuming zero bias. You''ll need to determine this via measurement for best results...\n');
    latbias = 0;
end

% Open audio device for low-latency output:
pahandle = PsychPortAudio('Open', deviceid, [], reqlatencyclass, freq, 2, buffersize, suggestedLatencySecs);

% Tell driver about hardwares inherent latency, determined via calibration
% once:
prelat = PsychPortAudio('LatencyBias', pahandle, latbias) %#ok<NOPRT,NASGU>
postlat = PsychPortAudio('LatencyBias', pahandle) %#ok<NOPRT,NASGU>


for n_stim = 1:length(sound)
    for n_freq = 1:size(sound{n_stim}, 1)
        mynoise(1,:) = sound{n_stim}(n_freq, :);
        mynoise(2,:) = sound{n_stim}(n_freq, :);
        
        bufferhandle{n_stim, n_freq} = PsychPortAudio('CreateBuffer', [], mynoise);
    end
end

% Setup display:
screenid = max(Screen('Screens'));

win = Screen('OpenWindow', screenid, 0);

ifi = Screen('GetFlipInterval', win);

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

% Ten measurement trials:
for i = 1:2
    for n = 1:3
        PsychPortAudio('FillBuffer', pahandle, bufferhandle{i, n});
        % This flip clears the display to black and returns timestamp of black onset:
        % It also triggers start of audio recording by the DataPixx, if it is
        % used, so the DataPixx gets some lead-time before actual audio onset.
        [vbl1 visonset1]= Screen('Flip', win);
        
        % Prepare black white transition:
        Screen('FillRect', win, 255);
        Screen('DrawingFinished', win);
        
        % Compute tWhen onset time for wanted visual onset at >= tWhen:
        tWhen = vbl1 + (waitframes - 0.5) * ifi;
        
        if exactstart
            % Schedule start of audio at exactly the predicted visual stimulus
            % onset caused by the next flip command.
            tPredictedVisualOnset = PredictVisualOnsetForTime(win, tWhen);
            PsychPortAudio('Start', pahandle, stimulationTime, tPredictedVisualOnset, 0);
        end
        
        % Ok, the next flip will do a black-white transition...
        [vbl visual_onset t1] = Screen('Flip', win, tWhen);
        
        if ~exactstart
            % No test of scheduling, but of absolute latency: Start audio
            % playback immediately:
            PsychPortAudio('Start', pahandle, 1, 0, 0);
        end
        
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
        
        %fprintf('Expected visual onset at %6.6f secs.\n', visual_onset);
        %fprintf('Sound started between %6.6f and  %6.6f\n', t1, t2);
        %fprintf('Expected latency sound - visual = %6.6f\n', t2 - visual_onset);
        %fprintf('First sound buffer played at %6.6f\n', t3);
        fprintf('Flip delay = %6.6f secs.  Flipend vs. VBL %6.6f\n', vbl - vbl1, t1-vbl);
        fprintf('Delay start vs. played: %6.6f secs, offset %f\n', t3 - t2, offset);
        
        fprintf('Buffersize %i, xruns = %i, playpos = %6.6f secs.\n', status.BufferSize, status.XRuns, status.PositionSecs);
        fprintf('Screen    expects visual onset at %6.6f secs.\n', visual_onset);
        fprintf('PortAudio expects audio onset  at %6.6f secs.\n', audio_onset);
        fprintf('Expected audio-visual delay    is %6.6f msecs.\n', (audio_onset - visual_onset)*1000.0);
        
        % Stop playback:
        PsychPortAudio('Stop', pahandle, 1);
        
        % Wait a bit...
        WaitSecs(0.3);
        
        Screen('FillRect', win, 0);
        telapsed = Screen('Flip', win) - visual_onset;
        WaitSecs(0.6);
    end
end

% Done, close driver and display:
Priority(0);

PsychPortAudio('Close');
Screen('CloseAll');

% Done. Bye.
return;
