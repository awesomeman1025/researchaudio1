% --- SETUP ---
PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 1);
InitializePsychSound(1);

Fs = 44100; 
nrchannels = 2; 
pahandle = PsychPortAudio('Open', [], 1, 1, Fs, nrchannels);

% --- SETUP --- 
n_ref = 7; % Ref sounds -> planning to keep this the same
random_sounds = [3, 4, 5, 6, 8]; % Our hardcoded array for picking random sounds -> will change soon
n_trials = 10; % Total number of trials -> can always change
p.dur = 0.5; % Duration of each sound in seconds -> need to mess around with this
screen_duration = 1; % Time interval for each set of sounds (seconds)

% trial setup
trial_order = randi([1, 2], n_trials, 1); % this randomizes the indices = randomize trial order
response_array = cell(n_trials, 2); % stores participant response, interval order 


% --- MAIN EXPERIMENT LOOP ---
for trial_number = 1:n_trials
    % interval order for trial
    interval_order = trial_order(trial_number);
    % picks an index from our hardcoded array for the number of random
    % sounds
    n_random = random_sounds(randi(length(random_sounds)));
    % timing for playback
    ref_times = linspace(0, screen_duration - p.dur, n_ref); 
    rand_times = linspace(0, screen_duration - p.dur, n_random); 


% The idea here is that we are essentially splitting the experiment into
% two intervals-- 1 and 2. As you can see, both of the if-else statements
% in the intervals are same except for whether they deal with n_ref sounds
% or the random number of sounds. The interval order dictates which sounds
% are played in each interval. For instance, if the interval order is 1, 
% interval 1 will force itself to play the n_ref sounds, and interval 2 
% will force the random number of sounds to be played.  

    % --- INTERVAL 1 ---
    if interval_order == 1 % so n_ref will be first 
        % play sounds simultaneously 
        disp('Playing n_ref sounds in interval 1.');
        audio_buffer = zeros(nrchannels, Fs * screen_duration);  % creating a buffer so that sounds are actually played
            % simultaneously
        for i = 1:n_ref % here, we are going ahead and adding each instance of the stimulus (7) to the buffer to be played at the same time
            audio_stim = MakeAuditoryNoise(p); % generate noise
            audio_stim = repmat(audio_stim', nrchannels, 1); % stereo
            starting = round(ref_times(i) * Fs) + 1;
            ending = starting + size(audio_stim, 2) - 1;
            audio_buffer(:, starting:ending) = audio_buffer(:, starting:ending) + audio_stim;
        end
        PsychPortAudio('FillBuffer', pahandle, audio_buffer);
        PsychPortAudio('Start', pahandle, 1, 0, 1);
        WaitSecs(screen_duration); % waits for the interval to finish
    else
        % same concept as above, but deals with the random sounds instead 
        disp('Playing random sounds in interval 1.');
        audio_buffer = zeros(nrchannels, Fs * screen_duration);
        for i = 1:n_random
            audio_stim = MakeAuditoryNoise(p); 
            audio_stim = repmat(audio_stim', nrchannels, 1);  
            starting = round(rand_times(i) * Fs) + 1;
            ending = starting + size(audio_stim, 2) - 1;
            audio_buffer(:, starting:ending) = audio_buffer(:, starting:ending) + audio_stim;
        end
        PsychPortAudio('FillBuffer', pahandle, audio_buffer);
        PsychPortAudio('Start', pahandle, 1, 0, 1);
        WaitSecs(screen_duration); 
    end
    WaitSecs(1);

    % --- INTERVAL 2 ---
    if interval_order == 1
        disp('Playing random sounds in interval 2.');
        audio_buffer = zeros(nrchannels, Fs * screen_duration);
        for i = 1:n_random
            audio_stim = MakeAuditoryNoise(p); 
            audio_stim = repmat(audio_stim', nrchannels, 1); 
            starting = round(rand_times(i) * Fs) + 1;
            ending = starting + size(audio_stim, 2) - 1;
            audio_buffer(:, starting:ending) = audio_buffer(:, starting:ending) + audio_stim;
        end
        PsychPortAudio('FillBuffer', pahandle, audio_buffer);
        PsychPortAudio('Start', pahandle, 1, 0, 1);
        WaitSecs(screen_duration); 
    else
        disp('Playing n_ref sounds in interval 2.');
        audio_buffer = zeros(nrchannels, Fs * screen_duration);
        for i = 1:n_ref
            audio_stim = MakeAuditoryNoise(p); 
            audio_stim = repmat(audio_stim', nrchannels, 1); 
            starting = round(ref_times(i) * Fs) + 1;
            ending = starting + size(audio_stim, 2) - 1;
            audio_buffer(:, starting:ending) = audio_buffer(:, starting:ending) + audio_stim;
        end
        PsychPortAudio('FillBuffer', pahandle, audio_buffer);
        PsychPortAudio('Start', pahandle, 1, 0, 1);
        WaitSecs(screen_duration); 
    end

    % --- PARTICIPANT RESPONSE ---
    disp('Waiting for participant response (f = wrong, j = right).');
    key_input = '';
    while isempty(key_input)
        [keyIsDown, ~, keyCode] = KbCheck; % check to see if key is pressed
        if keyIsDown
            keyName = KbName(keyCode); 
            if ismember(keyName, {'f', 'j'}) % only f or j is accepted
                key_input = keyName; % records response
            end
        end
    end

    % storing response
    response_array{trial_number, 1} = interval_order; % stores interval order
    response_array{trial_number, 2} = key_input; % stores f or j
end

% --- CLEAN UP ---
KbQueueStop();
KbQueueRelease();
PsychPortAudio('Close', pahandle);
Screen('CloseAll');
ShowCursor();

disp('The experiment has been finished.');
