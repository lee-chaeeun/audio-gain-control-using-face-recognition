clear all; close all; clc;

right=imread('RIGHT.jpg');
left=imread('LEFT.jpg');
noface=imread('no_face.jpg');
straight=imread('STRAIGHT.jpg');


info = audioinfo('Peggy Gou - Starry Night.mp3')
totalsampled = 1;  total = 0;

%% A. Create input and output objects
fileReader = dsp.AudioFileReader(...
    'Peggy Gou - Starry Night.mp3', ...
    'SamplesPerFrame',64, ...
    'ReadRange', [totalsampled info.TotalSamples]);
deviceWriter = audioDeviceWriter(...
    'SampleRate', fileReader.SampleRate);
scope = dsp.TimeScope( ...                        %<--- new lines of code
    'SampleRate',fileReader.SampleRate, ...       %<---
    'TimeSpanSource','Auto');

%% B. Create an object of a handle class
x = parameterRef;
x.name  = 'gain';
x.value = 1; %Initialize gain value 

center = zeros(1,2); % ?? ???
cam=webcam;
detector = vision.CascadeObjectDetector(); % ?? ?? detector ??
init = tic;
analyzetime = 0;
audio_time = 0;

left_out = 0;
right_out = 0;
straight_out = 0;
count = 0;
output = 0;
max_count = 5;

while true

%%
while analyzetime < 1
    analyzetime = toc(init);
    count = count + 1;
%% ?? ? ??? ?? ??    
    vid=snapshot(cam);
    vid = rgb2gray(vid);
    img = flip(vid, 2);
    
    bbox = step(detector, img);
    
    if ~ isempty(bbox)
       
        biggest_box=1;
        if rank(bbox)>1
            for i=1:rank(bbox) 
                if bbox(i,3)>bbox(biggest_box,3)
                    biggest_box=i;
                end
            end
        end
        
        
        bbox = bbox(biggest_box,:);
        subplot(2,1,1),imshow(img); hold on;
        
        for i=1:size(bbox,1)    %draw all the regions that contain face
            rectangle('position', bbox(i, :), 'lineWidth', 2, 'edgeColor', 'y');
        end
        
        %% ?? ???? ?? ??? ?? ?? 
        if center(1)==0
            center=[bbox(1,1) bbox(1,2)];
            widt = bbox(1,3);
            higt = bbox(1,4);
            continue
        end
        
        
        %% ?? ?? 
        newx=bbox(1,1); % ?? ?? x?
        diffx=newx-center(1); % ?? ??
        N=65; % ??? = ?? ??
      
        if diffx>N 
                right_out = right_out + 3; %right
        else if diffx<-N
                left_out = left_out + 3; %left       
            else
                straight_out = straight_out + 1; %straight

            end
         end
        
        subplot(2,1,2)
        output = max([ right_out,left_out,straight_out]);
        if count > max_count
            if output == right_out
                imshow(right); 
                x.value = x.value/5; 
            else if output == left_out
                imshow(left);   
                if x.value > 40
                    x.value = x.value +0; 
                else
                    x.value = x.value*5;
                end
                else
                    imshow(straight); 
                     x.value = x.value +0;                   
                end
                    
        end    
        
        %% ? ??, ??
        center=[bbox(1,1) bbox(1,2)];
        widt = bbox(1,3);
        higt = bbox(1,4);
        
        bbox=zeros(6,4);
        clear vid;
        clear biggest_box;
    end  
     
    end 
                
end      

analyzetime = 0;

output = 0;
if count > max_count
    count = 0;
    left_out = 0;
    right_out = 0;
    straight_out = 0;
end

while audio_time< 3
init3 = tic;
if total ~= totalsampled
    audioIn = fileReader();

    drawnow limitrate
    audioOut = audioIn.*x.value;
       
       
    deviceWriter(audioOut);
    
    scope(audioOut);
    total = total + 1;
end
audio_time = audio_time + toc(init3);   
totalsampled = total*1024;
end
audio_time = 0;

end    
% Release input and output objects
release(fileReader)
release(deviceWriter)
release(scope)
