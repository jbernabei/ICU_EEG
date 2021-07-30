function [IsolateInstances,TPrate,TNrate,Precision,Recall,F1,AdvRecall] = JustMetrics(Yhat,patientLabels)


IsolateInstances = sum(Yhat)./length(patientLabels);

TPrate = sum((Yhat + patientLabels)==2)./sum(patientLabels);

TNrate = sum((Yhat + patientLabels)==0)./sum(patientLabels == 0);

Precision = sum((Yhat + patientLabels)==2)./sum(Yhat);

Recall = sum((Yhat + patientLabels)==2)./(sum((Yhat + patientLabels)==2) + sum(((Yhat == 0)+ (patientLabels==1))==2));

F1 = 2.*Precision.*Recall/(Recall + Precision);

AdvRecall = AdvancedRecallMeasure(Yhat,patientLabels');

end

