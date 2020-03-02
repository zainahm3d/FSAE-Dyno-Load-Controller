close all;
clear all;

%% variables
s = serialport("com7", 921600);
str = zeros(2, 1);

logging = 1; %toggles logging

%Plotting Vars
torqueData = 1; %I may have broken something by starting all the vars as 1 (an int?)
hpData = 1;
rpmData = 1;
count = 1;
time = 0;

%Solenoid Valve Ctrl Vars
ServoPos = 0; %Commanded angle of the servo
RPMTarget = 8000; %Targeted RPM
RPMBuffer = 50;%Distance from targeted RPM when valve opens

%PID vars
Kp = 1; %Proportional Constant
Ki = 0; %Integral Constant
Kd = 0; %Derivative Constant
looprate = 8; %PID loop rate = 80HZ / looprate
fudge = 0; %additive "fudge factor" for pid controller

errorC = 0;
errorP = 0;
error = 0;
count2 = 1;
Maxerror = Kp * RPMTarget;


%% set up plot

plotGraph = plot(time, torqueData, '-r'); % every read needs to be on its own Plotgraph
hold on%hold on makes sure all of the channels are plotted
plotGraph1 = plot(time, hpData, '-b');
title('HP and Torque vs time', 'FontSize', 15);
xlabel('Elapsed Time', 'FontSize', 15);
ylabel('Output', 'FontSize', 15);
legend('Crank Torque', 'Crank HP');
axis([0 100 0 100]);
grid('on');

set(plotGraph, 'XData', time, 'YData', torqueData);
set(plotGraph1, 'XData', time, 'YData', hpData);
axis([(time(count) - 100) time(count) 0 100]);

%% run once when logging is toggled
if (logging == 1)%so logging can be toggleable in the future
    
    disp("logging started");
    tic%starts timer for time axis
    
    %% run continuously while logging
    while (1)
        
        if s.BytesAvailableFcnCount > 0
            data = readline(s);
            
            rpm = extractAfter(data, "r");
            rpm = extractBefore(rpm, "l");
            forceRaw = extractAfter(data, "l");
            
            rpm = str2double(rpm);
            forceRaw = str2double(forceRaw) / 1000;
            torqueBrake = (0.0201 * (forceRaw)); %calibration function (raw input --> Torque)
            torqueCrank = torqueBrake / 1.092952; %accounts for gearing from crank to brake
            
            % runs continously to update plot
            
            torqueData(count) = torqueCrank; %makes big table bois
            hpData(count) = (torqueCrank * rpm) / 5252;
            rpmData(count) = rpm;
            time(count) = toc;
            
            set(plotGraph, 'XData', time, 'YData', torqueData);
            set(plotGraph1, 'XData', time, 'YData', hpData);
            axis([(time(count) - 100) time(count) 0 100]); %sets axes to plot last 100 seconds on x and 0 to 100 on y
            
        end
        
        % Load Control Loop
        if mod(count, looprate) == 0
            error = error(count2);
            errorC = errorC(count2);
            errorP = errorP(count2);
            
            
            error = RPMTarget - rpmData;
            errorC = errorC + error; % cumulative error term
            output = error*Kp + (error-errorP)/0.1 *Kd + errorC*Ki;
            
            ServoPos = (output * (90 / Maxerror)) + fudge;
            write(s, ServoPos, 'char');
            
            
            errorP = error; % at the end of the code you
            % will store the previous error
            
            count2 = count2 + 1;
            
            
        end
        if mod(count, 20) == 0 %spits out rpm in the command window
            rpm
        end
        
        count = count + 1;
        
    end
    
end

%% Some shitty code some guy wrote
% figure(1);
% forceDataAsMat = cell2mat(torqueData);
% rpmDataAsMat = cell2mat(rpmData);
% hpDataAsMat = cell2mat(horsePower);

% subplot(3,1,1); plot(forceDataAsMat);
% title("Force");
% subplot(3,1,2); plot(hpDataAsMat);
% title("Horse Power");
% subplot(3,1,3); plot(rpmDataAsMat);
% title("RPM");
