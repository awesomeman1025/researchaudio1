% Psychtoolbox setup
PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 1); 

% --- AUDIO SETUP ---
nrchannels = 2;
Fs = 44100;
InitializePsychSound(1);
pahandle = PsychPortAudio('Open', [], 1, 1, Fs, nrchannels); 

% --- DISPLAY SETUP  ---
display.dist = 80; % Subject to screen distance, can adjust (cm)
display.width = 44.5; % Screen width (cm)
[window, windowRect] = Screen('OpenWindow', 1, [128 128 128]); % Gray
[screenXpixels, screenYpixels] = Screen('WindowSize', window);
display.resolution = [screenXpixels, screenYpixels];

dotRadius = 10; % dot radius, can adjust

% using provided angle2pix function to convert visual degrees to pixels
function [pix] = angle2pix(display, ang)
    pixSize = display.width / display.resolution(1); 
    sz = 2 * display.dist * tan(pi * ang / (2 * 180)); 
    pix = round(sz / pixSize); 
end


devIndex = -1;
KbQueueCreate(devIndex);
KbQueueStart();

% --- EXPERIMENT DESIGN ---
n_tones = 2; % tone 1 = male, tone 2 = female
n_dir = 2; % direction 1 = left to right, direction 2 = right to left 
n_repeat = 3; 
e_mat = expmat(1:n_tones, 1:n_dir);
rep_emat = repmat(e_mat, n_repeat, 1); 
[e_seq, rep_emat] = randseq(rep_emat); 
sorted_rep_emat = sortrows(rep_emat, 1); 
response_array = cell(size(sorted_rep_emat, 1), 2); 
response_array(:, 1) = num2cell(sorted_rep_emat(:, 1));

% --- MAIN EXPERIMENT LOOP ---
for trial_number = 1:size(sorted_rep_emat, 1)
    % Setup MakeAuditoryNoise
    p.Fs = Fs; % since Fs is already made 
    p.dur = 1; % Duration of noise in seconds -> might have to adjust down to 0.5
    p.width = 100; % Width of the filter -> need to adjust most likely 
    p.noiseType = 'Gaussian'; % I choose gaussian even though example chooses notch
    
    if sorted_rep_emat(trial_number, 2) == 1 % lets define male tone to be low frequency
        p.Fc = 150; % apparent average frequency for a male tone...
    else % lets do female tone
        p.Fc = 500; % definitely more than the average for the female tone but ensures significant difference
    end

    % Generate audio_stim
    audio_stim = MakeAuditoryNoise(p); % Straightforward, generate auditory stimulus 

    % Using MakeTrajectory to define a trajectory rather than changing
    % amplitude based on time
    if sorted_rep_emat(trial_number, 3) == 1 
        p.startxy = [-1, 0]; % -1 to 1 is left to right 
        p.endxy = [1, 0]; 
    else % Right to Left
        p.startxy = [1, 0]; % 1 to -1 is right to left
        p.endxy = [-1, 0]; % 
    end
    
    % Auditory Cue -> slightly confused on this part. By default, all of
    % these are true so I am setting them to true until I can fix black
    % screen of death 
    p.doppler = true; 
    p.itd = true; 
    p.ild = true; 
    p.inverseSquareLaw = true; 
    p.orbital = true;
    % MakeTrajectory
    [x, y] = MakeTrajectory(p);
    
    % Using auditoryCueIntegrator to combine all variables
    finalstimulus = auditoryCueIntegrator(p, audio_stim, x, y);
    
    % Play the audio
    PsychPortAudio('FillBuffer', pahandle, finalstimulus');
    PsychPortAudio('Start', pahandle, 1, 0, 1);

    % Black or White dot (randomize based on trial)
    dotColor = randi([0, 1]) * 255; 

    % visual angle code
    visual_angle = 5; % degrees
    dot_displacement = angle2pix(display, visual_angle); % uses angle2pix to convert degrees to pixels

    % attempting to match dot direction to trial direction, so audio as
    % well?
    if sorted_rep_emat(trial_number, 3) == 1 % Left to Right
        startPos = screenXpixels / 2 - dot_displacement; % displacement comes from visual angle conversion
        endPos = screenXpixels / 2 + dot_displacement;
    else % Right to Left
        startPos = screenXpixels / 2 + dot_displacement;
        endPos = screenXpixels / 2 - dot_displacement;
    end

    % Manually trying to match
    frames = 60; % frames
    if sorted_rep_emat(trial_number, 3 == 1)
        xval = linspace(-1, 1, frames);
    else 
        xval = linspace(1, -1, frames);
    end

    for i = 1:length(xval)
        % Calculate dot position in pixels based on audio trajectory (but
        % manually.. might have to change lin space if we adjust audio x, y
        dotXpos = startPos + (endPos - startPos) * (xval(i) + 1) / 2; 
        dotYpos = screenYpixels / 2; 
        % Render dot
        Screen('FillOval', window, dotColor, [dotXpos - dotRadius, dotYpos - dotRadius, dotXpos + dotRadius, dotYpos + dotRadius]);
        Screen('Flip', window);
        WaitSecs(1 / 60); % adjusting for refresh rate (60 hz)
    end
    % Stop Audio
    PsychPortAudio('Stop', pahandle);
    % Clear screen after each trial
    Screen('Flip', window);
    % Check for key press
    key_input = '';
    keys_allowed = {'f', 'j'};  % making sure f and j are the only allowed keys
    while isempty(key_input)
        [press, pressKey] = KbQueueCheck();
        if press
            keyCode = find(pressKey);
            key_input = KbName(keyCode);
            if ismember(key_input, keys_allowed)
                break;
            else
                key_input = '';
            end
        end
    end
    % Store response in response array
    response_array{trial_number, 2} = key_input;    
end
% clean
KbQueueStop();
KbQueueRelease();
PsychPortAudio('Close', pahandle);
Screen('CloseAll');
ShowCursor();

