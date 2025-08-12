classdef automotiveANCApp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                   matlab.ui.Figure
        LoadNoiseButton            matlab.ui.control.Button
        LoadEngineNoiseButton      matlab.ui.control.Button
        ApplyANCButton             matlab.ui.control.Button
        PlayOriginalButton         matlab.ui.control.Button
        PlayEngineButton           matlab.ui.control.Button
        PlayProcessedButton        matlab.ui.control.Button
        PauseOriginalButton        matlab.ui.control.Button
        PauseEngineButton          matlab.ui.control.Button
        PauseProcessedButton       matlab.ui.control.Button
        OriginalSignalAxes         matlab.ui.control.UIAxes
        EngineSignalAxes           matlab.ui.control.UIAxes
        ProcessedSignalAxes        matlab.ui.control.UIAxes
    end

    % Properties for internal data storage
    properties (Access = private)
        cabinNoise                 % Cabin noise signal
        engineNoise                % Engine noise signal (reference)
        processedSignal            % Signal after ANC
        Fs                         % Sampling frequency
        originalPlayer             % Audio player for original noise
        enginePlayer               % Audio player for engine noise
        processedPlayer            % Audio player for processed signal
    end

    methods (Access = private)

        % Button pushed function: LoadNoiseButton
        function LoadNoiseButtonPushed(app, ~)
            [file, path] = uigetfile({'*.wav;*.mp3', 'Audio Files (*.wav, *.mp3)'}, 'Select Cabin Noise');
            if isequal(file, 0)
                return;
            end
            [audioData, app.Fs] = audioread(fullfile(path, file));
            if size(audioData, 2) > 1
                audioData = audioData(:,1); % Select first channel if stereo
            end
            app.cabinNoise = audioData;
            plot(app.OriginalSignalAxes, app.cabinNoise);
            title(app.OriginalSignalAxes, 'Cabin Noise Signal');
            xlabel(app.OriginalSignalAxes, 'Time (s)');
            ylabel(app.OriginalSignalAxes, 'Amplitude');
            app.originalPlayer = audioplayer(app.cabinNoise, app.Fs);
        end

        % Button pushed function: LoadEngineNoiseButton
        function LoadEngineNoiseButtonPushed(app, ~)
            [file, path] = uigetfile({'*.wav;*.mp3', 'Audio Files (*.wav, *.mp3)'}, 'Select Engine Noise (Reference)');
            if isequal(file, 0)
                return;
            end
            [audioData, ~] = audioread(fullfile(path, file));
            if size(audioData, 2) > 1
                audioData = audioData(:,1); % Select first channel if stereo
            end
            app.engineNoise = audioData;
            app.enginePlayer = audioplayer(app.engineNoise, app.Fs);
            plot(app.EngineSignalAxes, app.engineNoise);
            title(app.EngineSignalAxes, 'Engine Noise Signal');
            xlabel(app.EngineSignalAxes, 'Time (s)');
            ylabel(app.EngineSignalAxes, 'Amplitude');
        end

        % Button pushed function: ApplyANCButton
        function ApplyANCButtonPushed(app, ~)
            if isempty(app.cabinNoise) || isempty(app.engineNoise)
                uialert(app.UIFigure, 'Please load both cabin and engine noise signals.', 'Input Required');
                return;
            end
            % Adjust signals to the same length
            len = min(length(app.cabinNoise), length(app.engineNoise));
            d = app.cabinNoise(1:len);
            x = app.engineNoise(1:len);
            
            % Ensure d and x are column vectors
            if isrow(d)
                d = d';
            end
            if isrow(x)
                x = x';
            end
            
            % Apply Adaptive Noise Cancellation
            mu = 0.001; % Step size
            filterOrder = 64;
            [y, ~] = app.lmsFilter(d, x, mu, filterOrder); % Corrected call
            app.processedSignal = y;
            plot(app.ProcessedSignalAxes, app.processedSignal);
            title(app.ProcessedSignalAxes, 'Processed Signal after ANC');
            xlabel(app.ProcessedSignalAxes, 'Time (s)');
            ylabel(app.ProcessedSignalAxes, 'Amplitude');
            app.processedPlayer = audioplayer(app.processedSignal, app.Fs);
        end

        % Button pushed function: PlayOriginalButton
        function PlayOriginalButtonPushed(app, ~)
            if isempty(app.originalPlayer)
                uialert(app.UIFigure, 'Please load the cabin noise signal.', 'No Signal Loaded');
                return;
            end
            play(app.originalPlayer);
        end

        % Button pushed function: PlayEngineButton
        function PlayEngineButtonPushed(app, ~)
            if isempty(app.enginePlayer)
                uialert(app.UIFigure, 'Please load the engine noise signal.', 'No Signal Loaded');
                return;
            end
            play(app.enginePlayer);
        end

        % Button pushed function: PlayProcessedButtonPushed
        function PlayProcessedButtonPushed(app, ~)
            if isempty(app.processedPlayer)
                uialert(app.UIFigure, 'Please apply ANC first.', 'No Processed Signal');
                return;
            end
            play(app.processedPlayer);
        end

        % Button pushed function: PauseOriginalButtonPushed
        function PauseOriginalButtonPushed(app, ~)
            if ~isempty(app.originalPlayer) && strcmp(app.originalPlayer.Running, 'on')
                pause(app.originalPlayer);
            end
        end

        % Button pushed function: PauseEngineButtonPushed
        function PauseEngineButtonPushed(app, ~)
            if ~isempty(app.enginePlayer) && strcmp(app.enginePlayer.Running, 'on')
                pause(app.enginePlayer);
            end
        end

        % Button pushed function: PauseProcessedButtonPushed
        function PauseProcessedButtonPushed(app, ~)
            if ~isempty(app.processedPlayer) && strcmp(app.processedPlayer.Running, 'on')
                pause(app.processedPlayer);
            end
        end

        % Adaptive LMS filter function
        function [y, e] = lmsFilter(app, d, x, mu, filterOrder)
            nIterations = length(d);
            y = zeros(nIterations, 1);
            e = zeros(nIterations, 1);
            w = zeros(filterOrder, 1);
            
            % Initialize Progress Dialog
            progressDlg = uiprogressdlg(app.UIFigure, 'Title', 'Processing', ...
                'Message', 'Applying ANC...', 'Cancelable', 'off', ...
                'Indeterminate', 'on');
            
            for n = filterOrder:nIterations
                x_vec = x(n:-1:n-filterOrder+1);
                
                % Ensure x_vec is a column vector
                if isrow(x_vec)
                    x_vec = x_vec';
                end
                
                y(n) = w' * x_vec;
                e(n) = d(n) - y(n);
                w = w + 2 * mu * e(n) * x_vec;
                
                % Update progress every 1000 iterations or at the end
                if mod(n, 1000) == 0 || n == nIterations
                    progressDlg.Value = n / nIterations;
                    progressDlg.Message = sprintf('Applying ANC... %.2f%%', (n / nIterations)*100);
                    drawnow;
                end
            end
            
            % Close Progress Dialog
            close(progressDlg);
        end

    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1000 800];
            app.UIFigure.Name = 'Automotive ANC Application';

            % Create OriginalSignalAxes
            app.OriginalSignalAxes = uiaxes(app.UIFigure);
            title(app.OriginalSignalAxes, 'Cabin Noise Signal');
            xlabel(app.OriginalSignalAxes, 'Time (s)');
            ylabel(app.OriginalSignalAxes, 'Amplitude');
            app.OriginalSignalAxes.Position = [50 500 400 250];

            % Create EngineSignalAxes
            app.EngineSignalAxes = uiaxes(app.UIFigure);
            title(app.EngineSignalAxes, 'Engine Noise Signal');
            xlabel(app.EngineSignalAxes, 'Time (s)');
            ylabel(app.EngineSignalAxes, 'Amplitude');
            app.EngineSignalAxes.Position = [500 500 400 250];

            % Create ProcessedSignalAxes
            app.ProcessedSignalAxes = uiaxes(app.UIFigure);
            title(app.ProcessedSignalAxes, 'Processed Signal after ANC');
            xlabel(app.ProcessedSignalAxes, 'Time (s)');
            ylabel(app.ProcessedSignalAxes, 'Amplitude');
            app.ProcessedSignalAxes.Position = [275 50 450 250];

            % Create LoadNoiseButton
            app.LoadNoiseButton = uibutton(app.UIFigure, 'push');
            app.LoadNoiseButton.ButtonPushedFcn = createCallbackFcn(app, @LoadNoiseButtonPushed, true);
            app.LoadNoiseButton.Position = [175 460 180 30];
            app.LoadNoiseButton.Text = 'Load Cabin Noise';
            app.LoadNoiseButton.Tooltip = 'Select an audio file representing cabin noise (e.g., inside car recording).';

            % Create LoadEngineNoiseButton
            app.LoadEngineNoiseButton = uibutton(app.UIFigure, 'push');
            app.LoadEngineNoiseButton.ButtonPushedFcn = createCallbackFcn(app, @LoadEngineNoiseButtonPushed, true);
            app.LoadEngineNoiseButton.Position = [600 460 180 30];
            app.LoadEngineNoiseButton.Text = 'Load Engine Noise';
            app.LoadEngineNoiseButton.Tooltip = 'Select an audio file representing engine noise (e.g., running engine).';

            % Create ApplyANCButton
            app.ApplyANCButton = uibutton(app.UIFigure, 'push');
            app.ApplyANCButton.ButtonPushedFcn = createCallbackFcn(app, @ApplyANCButtonPushed, true);
            app.ApplyANCButton.Position = [750 200 150 30];
            app.ApplyANCButton.Text = 'Apply ANC';

            % Create PlayOriginalButton
            app.PlayOriginalButton = uibutton(app.UIFigure, 'push');
            app.PlayOriginalButton.ButtonPushedFcn = createCallbackFcn(app, @PlayOriginalButtonPushed, true);
            app.PlayOriginalButton.Position = [175 430 180 30];
            app.PlayOriginalButton.Text = 'Play Cabin Noise';

            % Create PlayEngineButton
            app.PlayEngineButton = uibutton(app.UIFigure, 'push');
            app.PlayEngineButton.ButtonPushedFcn = createCallbackFcn(app, @PlayEngineButtonPushed, true);
            app.PlayEngineButton.Position = [600 430 180 30];
            app.PlayEngineButton.Text = 'Play Engine Noise';

            % Create PlayProcessedButton
            app.PlayProcessedButton = uibutton(app.UIFigure, 'push');
            app.PlayProcessedButton.ButtonPushedFcn = createCallbackFcn(app, @PlayProcessedButtonPushed, true);
            app.PlayProcessedButton.Position = [750 170 150 30];
            app.PlayProcessedButton.Text = 'Play Processed Signal';

            % Create PauseOriginalButton
            app.PauseOriginalButton = uibutton(app.UIFigure, 'push');
            app.PauseOriginalButton.ButtonPushedFcn = createCallbackFcn(app, @PauseOriginalButtonPushed, true);
            app.PauseOriginalButton.Position = [175 400 180 30];
            app.PauseOriginalButton.Text = 'Pause Cabin Noise';

            % Create PauseEngineButton
            app.PauseEngineButton = uibutton(app.UIFigure, 'push');
            app.PauseEngineButton.ButtonPushedFcn = createCallbackFcn(app, @PauseEngineButtonPushed, true);
            app.PauseEngineButton.Position = [600 400 180 30];
            app.PauseEngineButton.Text = 'Pause Engine Noise';

            % Create PauseProcessedButton
            app.PauseProcessedButton = uibutton(app.UIFigure, 'push');
            app.PauseProcessedButton.ButtonPushedFcn = createCallbackFcn(app, @PauseProcessedButtonPushed, true);
            app.PauseProcessedButton.Position = [750 140 150 30];
            app.PauseProcessedButton.Text = 'Pause Processed Signal';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end

    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = automotiveANCApp

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end

    end
end

