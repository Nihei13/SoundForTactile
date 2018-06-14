function [ StimulusSize ] = VisualAngleToVisualSize( VisualAngle, Distance, device_type, Resolution)
%For VIEWpixx, to calculate VisualAngle from SitmulusSize(pixel) 
%   è⁄ç◊ê‡ñæÇÇ±Ç±Ç…ãLèq
    
if length(VisualAngle) == 1
    VisualAngle(2) = VisualAngle;
end

switch device_type
    case 1
        PPCM(1) = Resolution(1) / 52.25;
        PPCM(2) = Resolution(2) / 29.39;
    case 2
        PPCM(1) = Resolution(1) / 52.2;
        PPCM(2) = Resolution(2) / 32.5;
    case 3
        PPCM(1) = Resolution(1) / 26;
        PPCM(2) = Resolution(2) / 17.5;
        
end

StimulusSize(1) = 2*Distance*tan(deg2rad(VisualAngle(1)/2));
StimulusSize(2) = 2*Distance*tan(deg2rad(VisualAngle(2)/2));

StimulusSize(1) = round(StimulusSize(1) * PPCM(1));
StimulusSize(2) = round(StimulusSize(2) * PPCM(2));

end

