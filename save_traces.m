function save_traces(FileName , meanTrace , flatTrace , spikeTimes)
    wh = waitbar(0 , 'Saving files...');
    
    now_time = datestr(clock ,'mmddyy-HHMMSS');
    
    xlswrite( [FileName ,  '_saved_bleach_corrected_trace_', now_time ,'.xlsx'], meanTrace');
    
    waitbar(0.4 , wh);
    
    xlswrite([FileName ,  '_saved_mean_trace_', now_time ,'.xlsx'] , flatTrace');
    
    waitbar(0.7 , wh);
    
    fileID = fopen([FileName , '_ROI_detected_spike_times_' , now_time , '.txt'],'w');
    fprintf(fileID ,'%d\n', spikeTimes);
    fclose(fileID);
    
    waitbar(1 , wh);
    close(wh)

end