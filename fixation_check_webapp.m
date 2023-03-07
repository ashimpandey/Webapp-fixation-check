%% continous eye monitoring and sending feedback to webapp for training CVI patient

%% set eyelink default values

PsychDefaultSetup(1);
ListenChar(2);
dummymode=0;
stopkey=KbName('space');
firstRun = 1;
infix=0;
dotSize = 10;
fixWinSize = 100;
SpaceKey= KbName('space');

%% get file name
prompt = {'Enter tracker EDF file name (1 to 8 letters or numbers)'};
        dlg_title = 'Create EDF file';
        num_lines= 1;
        def     = {'DEMO'};
        answer  = inputdlg(prompt,dlg_title,num_lines,def);
        edfFile = answer{1};
        fprintf('EDFFile: %s\n', edfFile );


screenNumber=1;
[winWidth, winHeight] = WindowSize(screenNumber);
wRect=[0,0,winWidth,winHeight];
windowRect=wRect;

%% create fixation dot and fixation window rectangles
    fixationDot = [-dotSize -dotSize dotSize dotSize];
    fixationDot = CenterRect(fixationDot, wRect);    
    fixationWindow = [-fixWinSize -fixWinSize fixWinSize fixWinSize];
    fixationWindow = CenterRect(fixationWindow, wRect);

     el=EyelinkInitDefaults();
    if ~EyelinkInit(dummymode)
        fprintf('Eyelink Init aborted.\n');
        cleanup;  % cleanup function
        return;
    end
    eye_used = Eyelink('EyeAvailable');
 
    [v ,vs]=Eyelink('GetTrackerVersion');
    fprintf('Running experiment on a ''%s'' tracker.\n', vs );
    
    % open file for recording data
    edfFile =datestr(now, 'HH_MM');
    Eyelink('Openfile', edfFile);
    
    % EyelinkDoTrackerSetup(el);
     
     Eyelink('StartRecording');
     WaitSecs(0.5);
     [xCenter, yCenter] = RectCenter(windowRect);
     TargetWindow = 2; %%% window to maintain fixation at.
     brokenFixation = false;
     ppd=40;
       
 while(1)  
          if ~dummymode
                if Eyelink( 'NewFloatSampleAvailable') > 0
                    % get the sample in the form of an event structure
                    evt = Eyelink( 'NewestFloatSample');
                    if eye_used ~= -1 % do we know which eye to use yet?
                        % if we do, get current gaze position from sample
                        x = evt.gx(eye_used+1); % +1 as we're accessing MATLAB array
                        y = evt.gy(eye_used+1);
                        
                        if abs(x - xCenter)>TargetWindow  * ppd ...
                                || abs(y - yCenter)>TargetWindow * ppd
%                             trcount = trcount - 1;
%                             timerZero = GetSecs;
                            brokenFixation = true;
%                             break;
%                             Beeper(600,0.7,0.15);
                        else
                             brokenFixation = false;
                        end
                    end
                end
          end
          
        if brokenFixation
            Beeper(600,0.7,0.15);
            web('https://blindsight-eyetracker.herokuapp.com/notfocusing'); %%%send fixation broken message to webapp
            continue;
        else
            web('https://blindsight-eyetracker.herokuapp.com/focusing');    %%%%send fixation maintained message to webapp
        end         
 end
      

        
