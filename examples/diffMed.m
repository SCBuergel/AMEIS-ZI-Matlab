function [r] = diffMed(ca)
r=median(1./diff(ca));
end

