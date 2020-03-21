function [Ysmooth] = VoteFiltering(Yhat,filtSize, remove_single)

Ysmooth = Yhat;
for i = 1:(length(Yhat) - (filtSize-1))
    if(Yhat(i) && Yhat(i + (filtSize-1)))
        Ysmooth(i:(i + (filtSize-1))) = 1;
    end
end

if remove_single
    for i = 2:(length(Ysmooth)-1)
        if ((Ysmooth(i-1)==0) && (Ysmooth(i)==1) && (Ysmooth(i+1)==0))   
            Ysmooth(i) = 0;
        end
    end
    
end

end

