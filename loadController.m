close all;
clear all;

%% variables
s = serialport("COM7", 921600);
str = zeros(2, 1);

logging = 1; %toggles logging

torqueData = 1; %I may have broken something by starting all the vars as 1 (an int?)
hpData = 1;
rpmData = 1;
torquezero = 0;
count = 1;
time = 0;

ValvePos = 0; %1 = open
RPMTarget = 8000; %Targeted RPM
RPMBuffer = 100;%Distance from targeted RPM when valve opens

%PID vars
Kp = 1; %Proportional Constant
Ki = 0; %Integral Constant
Kd = 0; %Derivative Constant
errorC = 0;
errorP = 0;
error = 0;

%% set up plot

plotGraph = plot(time, torqueData, '-r'); % every read needs to be on its own Plotgraph
hold on%hold on makes sure all of the channels are plotted
plotGraph1 = plot(time, hpData, '-b');
title('HP and Torque vs time', 'FontSize', 15);
xlabel('Elapsed Time', 'FontSize', 15);
ylabel('Output', 'FontSize', 15);
legend('Crank Torque', 'Crank HP')
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
            torqueBrake = (0.0201 * (forceRaw - torquezero)); %calibration function (raw input --> Torque)
            torqueCrank = torqueBrake / 1.092952; %accounts for gearing from crank to brake
            forceRaw
            % runs continously to update plot
            
            torqueData(count) = torqueCrank; %makes big table bois
            hpData(count) = (torqueCrank * rpm) / 5252;
            rpmData(count) = rpm;
            time(count) = toc;
            
            set(plotGraph, 'XData', time, 'YData', torqueData);
            set(plotGraph1, 'XData', time, 'YData', hpData);
            axis([(time(count) - 100) time(count) 0 100]); %sets axes to plot last 100 seconds on x and 0 to 100 on y
            
            
                        %% Load Control Loop
                        if mod(count, 2) == 0
                            if rpm >= (RPMTarget - RPMBuffer)
                                ValvePos = 1;
                            else
                                ValvePos = 0;
                            end
                            write(s, ValvePos, 'char');
                        end
            
%             if mod(count, 4) == 0
%                 error = RPMTarget - rpmData;
%                 errorC = int16(errorC) + int16(error); % cumulative error term
%                 output = int16(error)*Kp + (int16(error)-int16(errorP))/0.1 *Kd + int16(errorC)*Ki;
%                 
%                 if output >= (200)
%                     ValvePos = 0;
%                 else
%                     ValvePos = 1;
%                 end
%                 write(s, ValvePos, 'char');
%                 
%                 
%                 errorP = error; % at the end of the code you
%                 will store the previous error
%                 count = count + 1;
%             end
            
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
