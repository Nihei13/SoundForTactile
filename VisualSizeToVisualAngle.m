function [ VisualAngle ] = VisualSizeToVisualAngle( StimulusSize, Distance)
%For VIEWpixx, to calculate VisualAngle from SitmulusSize(pixel) 
%   詳細説明をここに記述

VisualAngle(1) = rad2deg(2*atan(StimulusSize(1)/(2*Distance)));
VisualAngle(2) = rad2deg(2*atan(StimulusSize(2)/(2*Distance)));

end

