function [AdvancedRecall, num_sz_true, num_sz_detect] = AdvancedRecallMeasure(Yhat,Ytrue)

lastVal = 0;
onSeizureBody = false;
SeizureBodyCounter = 0;
SeizureAccountedForCounter = 0;
ThisSzAccountedFor = false;
for i = 1:size(Ytrue,1)
    curVal = Ytrue(i);
    if(~lastVal && curVal)
        SeizureBodyCounter = SeizureBodyCounter + 1;
        onSeizureBody = true;
    end
    
    if(lastVal && ~curVal)
        ThisSzAccountedFor = false;
        onSeizureBody = false;
    end
    
    if(onSeizureBody)
        if(Yhat(i) && ~ThisSzAccountedFor)
            SeizureAccountedForCounter = SeizureAccountedForCounter + 1;
            ThisSzAccountedFor = true;
        end
    end
    
    lastVal = Ytrue(i);  
end

AdvancedRecall = SeizureAccountedForCounter./SeizureBodyCounter;
num_sz_true = SeizureBodyCounter;
num_sz_detect = SeizureAccountedForCounter;

end

