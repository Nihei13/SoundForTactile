function [color] = getVPixxTriggerValue(value)

bits = dec2bin(value);


bit_r = [];
bit_g = [];

len = length(bits);

for i = 1:len
    if i <= 4
        bit_r = [bits(len+1-i) bit_r];
        bit_r = ['0' bit_r];
    else
        bit_g = [bits(len+1-i) bit_g];
        bit_g = ['0' bit_g];
    end
end

if isempty(bit_g)
    bit_g = '0000';
end

r = bin2dec(bit_r);
g = bin2dec(bit_g);
b = 0;

color= [r, g, b];

end
