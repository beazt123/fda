function [lowerLim, upperLim] = twoAdjDates(listOfSortedDates,selectedDateIndex)
%TWOADJDATES Returns the 2 dates between which lies the selected date
% Takes in a list of sorted dates in increasing order. Given the index of
% the selected date, it finds the 2 dates that are adjacent to the selected
% date. If the selcted date happens to be the 1st or last on the list, then
% lowerLim or upperLim will be a date that is very much
% earlier or later than the selectedDate respectively.
% I.e. 
% [a b] = twoAdjDates([01-01-2019, 02-01-2019, 03-01-2019], 1)
% a will be 01-01-1019, whereas b will be 02-01-2019

    lowerIndex = selectedDateIndex - 1;
    upperIndex = selectedDateIndex + 1;
    numDates = numel(listOfSortedDates);
    selectedDate = listOfSortedDates(selectedDateIndex);
    
    if numDates == 1
        lowerLim = selectedDate - years(1000);
        upperLim = selectedDate + years(1000);
        
    elseif selectedDateIndex == 1
        upperLim = listOfSortedDates(upperIndex);
        lowerLim = selectedDate - years(1000);
        
    elseif selectedDateIndex == numDates
        lowerLim = listOfSortedDates(lowerIndex);
        upperLim = selectedDate + years(1000);
        
    else
        upperLim = listOfSortedDates(upperIndex);
        lowerLim = listOfSortedDates(lowerIndex);
        
    end
        
end
