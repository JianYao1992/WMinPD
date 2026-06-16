function LabelSignificantPositions(SignificantPositions,TimeGain,LabelUpperYvalue,LabelColor)

if ~isempty(SignificantPositions)
    for i = 1:numel(SignificantPositions)
        patch([SignificantPositions(i)-0.5 SignificantPositions(i)-0.5 SignificantPositions(i)+0.5 SignificantPositions(i)+0.5]./TimeGain,[LabelUpperYvalue-1 LabelUpperYvalue LabelUpperYvalue LabelUpperYvalue-1],LabelColor,'edgecolor','none');
        hold on
    end
end