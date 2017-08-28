function degPerV = calibrateEOG(offsetsDeg, posAvg, numSummed)

%calibrateEOG: Compute the calibration for the EOG based on averaged position
%traces
%   Detailed explanation goes here

if sum(numSummed) < length(numSummed)
    degPerV = 0.0;
    return;
end
endPointsV = mean(posAvg(end - 50:end, :));             % average trace ends to get each endpoint
degPerV = mean(offsetsDeg ./ endPointsV);

end

