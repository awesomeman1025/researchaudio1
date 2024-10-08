% Psychtoolbox Setup
PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 1); % Only way to make this work on my mac

% Window
PsychImaging('OpenWindow', 0, [0,0,0]); % please adjust based on screen #
HideCursor(); 

% --- LOADING AUDIO + AUDIO SETUP ---
nrchannels = 2;
Fs = 44100; 
InitializePsychSound(1); 
pahandle = PsychPortAudio('Open', [], 1, 1, Fs, nrchannels); 

% male_tone = audio file path for male tone
% female_tone = audio file path for female tone

% --- EXP DESIGN --- 
% Defining m, f, direction, and trial repetition variables
n_tones = 2; % tone 1 = male, tone 2 = female
n_dir = 2; % direction 1 = left to right, direction 2 = right to left 
n_repeat = 3; % For now we will say that the experiment is repeated n_repeat * 4 times
% Creating the trial experiment matrix, setting the number of trials,
% randomizing the trials, sorting matrix so it is easier to understand
e_mat = expmat(1:n_tones, 1:n_dir);
rep_emat = repmat(emat, n_repeat, 1); % Repeats the matrix n_repeat number of times
[e_seq, rep_emat] = randseq(rep_emat); % Randomizes replicated experimental matrix
% I also want to point out that I do not like using e_seq since it actually
% provides trial numbers in a different order than how they are listed in
% the randomized matrix
sorted_rep_emat = sortrows(rep_emat, 1); % Sorts the experimental matrix by trial (makes visualization easier)
response_array = [sorted_rep_emat(:,1), zeros(size(sorted_rep_emat, 1), 1)]; % Makes an empty array where we can store our keyboard input responses
% column 1 will be the trial number and column 2 will be the keyboard input

% ---This next segment enables us to predefine the second column values of our
% experimental matrix (male/female voice) with a specific audio file PATH
% this way, we can avoid repetitive if-else statements inside of our
% experiment's main for loop (both work, this is more effective)---

audio_file_mat = cell(size(sorted_rep_emat, 1), 1); % Creates a cell as large as number of trials. Cell lets us store variables of different primitive types.
% This way we can associate the audio file path with the trial number. 
for i = 1:size(sorted_rep_emat, 1) % Loop from 1 to the first column of our experimental matrix (each trial)
    if sorted_rep_emat(i, 2) == 1 % If the value in the trial (located in the second column of our experimental matrix) equals 1
        audio_file_mat{i} = male_tone; % then we can store the male_tone audio file path into that trial 
    else 
        audio_file_mat{i} = female_tone; % otherwise, we store the female_tone into that trial (b/c it has to be 2)
    end
end % Now our audio_info_mat cell array should store audio files respective to the trial number.

% --- LOADING AUDIO FILE ---
% Even though we technically associated the audio file path with the trial
% number, we still need to load each audio file in the trial so that we can
% read it during the actual experiment. In order to do so, we would need arother 
% array that could access each audio file path (the array above would be a reference list)
% and the array below actually lets us read each audio file. 

audio_data_mat = cell(size(audio_file_mat)); % Creating a new array which will be the same size as our previously defined audio_file_mat
for x = 1:length(audio_file_mat, 1) % So for each value in our audio_file_mat (use length b/c non int value)
    [audio_data_mat{x}, ~] = audioread(audio_file_mat{x}); % We fill each column value of audio_data_mat with read audio data from audio_file_mat
end 

% --- MAIN EXPERIMENT ---
for trial_number = 1:size(sorted_rep_emat, 1)
    % Load the proper audio file tone based on our previously created audio
    % arrays
    audio_stim = audio_data_mat{trial_number}; % Reading the audio file of the respective trial
    
    % We still have to deal with direction but that's easier to do as in
    % if-else statement in the for loop itself.
    if sorted_rep_emat(trial_number, 3) == 1 % So if our third column for direction = 1 (defaulting 1 to be left to right)
        panning = linspace(-1, 1, length(audio_stim)); % Pans our audio from -1 to 1 (L -> R) 
    else 
        panning = linspace(1, -1, length(audio_stim)); % Else, pan audio from 1 to -1 (R -> L)
    end

    % Now we actually have to play the audio
    for time = 1:length(audio_stim)
        l_volume = max(0, 1 - (panning(time) + 1) / 2); % Apply panning effect to audio
        r_volume = max(0, (panning(time)+1) / 2);
        % We can finally then create the final panned audio signal 
        % The line below applies the proper volume to each panning
        finalpannedaudio = [audio_stim(time, 1) * l_volume; audio_stim(time, 2) * r_volume];
        % Buffer audio, wait for a split second, and then play
        PsychPortAudio('FillBuffer', pahandle, finalpannedaudio');
        PsychPortAudio('Start', pahandle, 1, 0, 1);
        WaitSecs(1/44100);
    end 

    % Keyboard Input, Only f and j are allowed, reset key_input if it is
    % not a part of f and j group. 
    key_input = '';
    keys_allowed = {'f', 'j'};
    while isempty(key_input) % While no keystroke has been registered
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown
            key_input = KbName(find(keyCode)); % Stores the key that has been pressed
            if ~ismember(key_input, keys_allowed)
                key_input = '';
            end
        end

    % store key input into our response matrix
    response_array{trial_number} = key_input; 

    % Stop audio and clear screen
    PsychPortAudio('Stop', pahandle);
    Screen('Flip', WindowCenter);
    end
end

PsychPortAudio('Close', pahandle);
Screen('CloseAll');
ShowCursor();

% PLEASE ADD WAY TO MAKE RESPONSES INTO A TXT FILE FOR FURTHER USE
% NEED TO DOWNLOAD AUDIO FILES
% NEED TO PIVOT AUDIO FROM loudness to audio tool box
% add text, display text, etc. 


