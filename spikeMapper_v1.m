%% spikeMapper.m
%  Author: Kaveh Karbasi
%  The Miller Lab, University of California, Berkeley.
%  Created: October 2015
%---------------------------------------------------------------------
% This script:
% - Reads a tif stack
% - Detects the spikes and finds the number of spikes in each pixel of the stack
% - Shows the results in a heat map
% - Asks for a ROI
% - Plots the selected ROI's mean trace (both original and bleach corrected)
% - Has the option to save the traces into an Excel file
% - And finally draws a raster plot of the selected ROIs
%---------------------------------------------------------------------
warning('off' , 'all');
close all;

% ------------ Configuration Variables------------
    polynomial_order = 10;
    sd_treshold = 3;
    re_arm_factor = 1;
%-------------------------------------------------


% Open file
[FileName,PathName] = uigetfile('*.tif;*.tiff','Select a .tif file');

% Read the tif stack in the opened file
tic
disp('----------Reading input file...');
tiffStack  = tiffStackReaderFast([PathName,FileName]);
tiffStackOriginal = tiffStack;
toc

frameX = size(tiffStack , 1);
frameY = size(tiffStack , 2);

% Prompt user for calculation resolution
prompt = {['Frame size is ' , num2str(size(tiffStack , 1)), 'X' , ...
    num2str(size(tiffStack,2)) , '. Enter block size (3 means 3X3):']};
    dlg_title = 'Enter calculation block size';
    num_lines = 1;
    defaultBlockSize = floor(sqrt(size(tiffStack,1)*size(tiffStack,2))*0.04);
    if defaultBlockSize == 0
        defaultBlockSize = 1;
    end
    defaultans = {num2str(defaultBlockSize)}; 
    answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
    res = answer{1};
    res = str2double(res);

% Divide the frame into blocks
disp('----------Processing...')
tic
if (res ~= 1)
    fun = @(blocMatrix) mean(mean(blocMatrix.data));
    tiffStack = blockproc(tiffStack , [res res] , fun);
end

% Loop over all pixels and count the number of spikes in each one. Save the
% results in matrix spikeMap (same size as the video fraame size).
h = waitbar(0 , 'Processing...');
spikeMap = zeros (size(tiffStack , 1) , size(tiffStack , 2));
for i = 1 : size(tiffStack , 1)
    for j = 1:size(tiffStack , 2)
        tmp  = tiffStack(i,j,:);
        tmp = reshape(tmp , [1,numel(tmp)]);
        spikeMap(i , j) = spike_counter(tmp , polynomial_order , sd_treshold , re_arm_factor);
    end
    waitbar(i/size(tiffStack , 1) , h);
end

% Change the frame size to its original size by repeating elements
if (res~=1)
    spikeMap = repelem(spikeMap , res ,res);
    spikeMap = spikeMap(1:frameX , 1:frameY);
end
close(h);
toc

% Show the results as a heat map
colormap('jet');
mapH = image(spikeMap,'CDataMapping','scaled');
colorbar;


% Add close button
closebtn = uicontrol('Style', 'pushbutton', 'String', 'Close All',...
        'Position', [20 20 50 20],...
        'Callback', 'close(''all'')');   


title({['Color map of spike frequency for "', FileName ,...
    '"'],'Please select a ROI:'} , 'interpreter' , 'none');
pbaspect([frameY frameX 1]);

rasterSpikeTimes = {};
raster_index = 1;
% An infinite loop for choosing ROIs
while (true)
    if(~isempty(get(mapH , 'parent')))
        h=imfreehand(get(mapH , 'parent'));
        binarybgimg=h.createMask();
        pos = h.getPosition();
        textX = (max(pos(: , 1)) + min(pos(: , 1)))/2;
        textY = (max(pos(: , 2)) + min(pos(: , 2)))/2;
                
    else
        break;
    end
    pause(0.1)
    
    % Applying the selected ROI to the tiff stack to calculate the trace of
    % average intensities of the ROI pixels 
    maskedTiffStack = applyMask2TiffStack(tiffStackOriginal , binarybgimg);
    meanTrace = sum(sum(maskedTiffStack,1),2);
    meanTrace = meanTrace/nnz(binarybgimg);
    meanTrace = reshape(meanTrace , [1 numel(meanTrace)]);
    
    % Plotting the traces (original and bleach corrected) of the selected ROI
    figure;
    movegui('east');
    subplot(2,1,1);
    plot(meanTrace);
    title('ROI mean trace');
    flatTrace = traceFlattener(meanTrace , polynomial_order);
    subplot(2,1,2)
    plot(flatTrace);
    title('ROI bleach corrected trace')
    
    [~,spikeTimes] = spike_counter(flatTrace , polynomial_order , sd_treshold , re_arm_factor);
    
    savebtn = uicontrol('Style', 'pushbutton', 'String', 'Save the latest trace',...
        'Position', [5 5 200 20],...
        'Callback', 'save_traces( FileName , meanTrace , flatTrace , spikeTimes )');   

%     addtrbtn = uicontrol('Style', 'pushbutton', 'String', 'Add this trace to raster plot',...
%         'Position', [210 5 200 20],...
%         'Callback', 'rasterSpikeTimes(raster_index) = spikeTimes;raster_index = raster_index + 1;');   
%     
    rasterChoice = questdlg('Add to raster plot?' ,'Add to raster plot?' , 'Yes' , 'No' , 'Yes');
    switch rasterChoice
        case 'Yes'
        text('position',[textX textY],'fontsize',20 , 'Parent' , ...
            get(mapH , 'parent') , 'Color' , 'white' ,'string',num2str(raster_index))

        rasterSpikeTimes{raster_index} = spikeTimes;
        raster_index = raster_index + 1;
    end
    % Ask user if he/she wants to continue, stop, or conntinue while saving
    % the latest trace
    choice = questdlg('Continue drawing ROIs?' , 'Another ROI?' , ...
        'Continue' , 'Stop and Plot Raster' , 'Save and Continue', ...
        'Continue');
    switch choice
        case 'Stop and Plot Raster'
            break;
        case 'Save and Continue'
            save_traces(FileName , meanTrace , flatTrace , spikeTimes);
    end
end

% Drawing Raster Plot
figure;
movegui('west');
ntrials = numel(rasterSpikeTimes); % number of trials
for jj = 1:ntrials
    t       = rasterSpikeTimes{jj}; % Spike timings in the jjth trial
    nspikes   = numel(t); % number of elemebts / spikes
    for ii = 1:nspikes % for every spike
      line([t(ii) t(ii)],[jj-0.5 jj+0.5],'Color','k'); 
      % draw a black vertical line of length 1 at time t (x) and at trial jj (y)
    end
end
xlabel('Time');
ylabel('ROI number');
set(gca,'ytick', 1:ntrials); 

disp('----------done!')
