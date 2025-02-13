% --- SETUP ---
PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 1);
InitializePsychSound(1);

Fs = 44100; 
nrchannels = 2; 
pahandle = PsychPortAudio('Open', [], 1, 1, Fs, nrchannels);

% --- PARAMETERS --- 
n_ref = 7; % Reference sounds
random_sounds = [3, 4, 5, 6, 8]; % Possible comparison sounds
n_trials = 10; % Total number of trials
p.dur = 0.5; % Duration of each sound in seconds
screen_duration = 1; % Time interval for each set of sounds
percent_values = [0.3, 0.5, 0.7]; % Percentage manipulations for comparison sounds
p.Fs = Fs; % Sampling frequency
p.Fc = 500; % Center frequency (adjustable)
p.width = 100; % Bandwidth
p.noiseType = 'Gaussian'; % Define noise type

% Trial setup
trial_order = randi([1, 2], n_trials, 1); % Randomize trial order
percent_order = percent_values(randi(length(percent_values), n_trials, 1)); % Randomize percentage per trial
response_array = cell(n_trials, 2); % Store participant responses

% --- LOAD AUDIO BUFFER ---
audio_buffers = struct();
for trial_number = 1:n_trials
    interval_order = trial_order(trial_number);
    percent_value = percent_order(trial_number);
    
    % Compute n_comparison using percentage manipulation
    n_comparison = round(n_ref * (1 - percent_value));
    
    % Timing for sounds
    ref_times = linspace(0, screen_duration - p.dur, n_ref);
    comp_times = linspace(0, screen_duration - p.dur, n_comparison);
    
    % Generate reference sound buffer
    ref_buffer = zeros(nrchannels, Fs * screen_duration);
    for i = 1:n_ref
        audio_stim = MakeAuditoryNoise(p);
        expected_length = round(p.dur * Fs);
        audio_stim = audio_stim(1:min(end, expected_length));
        if length(audio_stim) < expected_length
            audio_stim = [audio_stim; zeros(expected_length - length(audio_stim), 1)];
        end
        audio_stim = repmat(audio_stim', 2, 1);
        starting = round(ref_times(i) * Fs) + 1;
        ending = min(starting + size(audio_stim, 2) - 1, size(ref_buffer, 2));
        ref_buffer(:, starting:ending) = ref_buffer(:, starting:ending) + audio_stim(:, 1:(ending - starting + 1));
    end
    
    % Generate comparison sound buffer
    comp_buffer = zeros(nrchannels, Fs * screen_duration);
    for i = 1:n_comparison
        audio_stim = MakeAuditoryNoise(p);
        expected_length = round(p.dur * Fs);
        audio_stim = audio_stim(1:min(end, expected_length));
        if length(audio_stim) < expected_length
            audio_stim = [audio_stim; zeros(expected_length - length(audio_stim), 1)];
        end
        audio_stim = repmat(audio_stim', 2, 1);
        starting = round(comp_times(i) * Fs) + 1;
        ending = min(starting + size(audio_stim, 2) - 1, size(comp_buffer, 2));
        comp_buffer(:, starting:ending) = comp_buffer(:, starting:ending) + audio_stim(:, 1:(ending - starting + 1));
    end
    
    % Insert zero matrix between ref and comparison
    zero_matrix = zeros(nrchannels, Fs * screen_duration);
    combined_buffer = ref_buffer + zero_matrix + comp_buffer;
    
    % Store buffers in struct
    audio_buffers(trial_number).ref = ref_buffer;
    audio_buffers(trial_number).comp = comp_buffer;
    audio_buffers(trial_number).combined = combined_buffer;
    audio_buffers(trial_number).interval_order = interval_order;
end

% --- MAIN EXPERIMENT LOOP ---
for trial_number = 1:n_trials
    interval_order = audio_buffers(trial_number).interval_order;
    combined_buffer = audio_buffers(trial_number).combined;
    
    % Play combined buffer
    PsychPortAudio('FillBuffer', pahandle, combined_buffer);
    PsychPortAudio('Start', pahandle, 1, 0, 1);
    WaitSecs(screen_duration);
    
    % --- PARTICIPANT RESPONSE ---
    disp('Waiting for participant response (f = wrong, j = right).');
    key_input = '';
    while isempty(key_input)
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown
            keyName = KbName(keyCode);
            if ismember(keyName, {'f', 'j'})
                key_input = keyName;
            end
        end
    end
    
    % Store response
    response_array{trial_number, 1} = interval_order;
    response_array{trial_number, 2} = key_input;
end

% --- CLEAN UP ---
KbQueueStop();
KbQueueRelease();
PsychPortAudio('Close', pahandle);
Screen('CloseAll');
ShowCursor();

disp('The experiment has been finished.');
