function fields = lithography_coherent_fields(p, result, u, v)
% Ideal scalar 4f relay. Physical amplitudes and axes; NA is image-side.
N = p.gridSize;
padding = 4;
if isfield(p,'propagationPadding'), padding = p.propagationPadding; end
P = padding*N;
lambda = p.wavelengthNm*1e-9;
dx = p.fieldSizeUm*1e-6/N;
g = result.geometry;
f1 = g.relayFocal1Mm*1e-3;
R = p.reduction;
x = result.objectAxisM;
[X,Y] = meshgrid(x,x);
curvature = (p.condenserFocalMm-p.sourceToCondenserMm)*1e3/p.condenserFocalMm^2;
% Source u,v are normalized object-side illumination angles at nominal focus.
cutoff = p.projNA/(R*lambda);
if isfield(result,'maskIllumination')
    fields.incident=lithography_gaussian_mode(result.maskIllumination,x,x,u,v);
else
    fields.incident=exp(1i*2*pi*cutoff*(u*X+v*Y)).*exp(1i*pi*curvature*(X.^2+Y.^2)/lambda);
end
fields.mask = result.mask.*fields.incident;
padded = zeros(P,P);
first = floor(P/2)-floor(N/2)+1;
padded(first:first+N-1,first:first+N-1) = fields.mask;
freq = ((0:P-1)-floor(P/2))/(P*dx);
[FX,FY] = meshgrid(freq,freq);
amp = lithography_pupil_amplitude(FX/cutoff,FY/cutoff,p);
detune = (p.fieldToPupilMm-p.projectionFocalMm)*1e-3;
phase = exp(-1i*pi*lambda*detune*(FX.^2+FY.^2));
spectrum = fftshift(fft2(ifftshift(padded)));
fields.pupil = spectrum.*amp.*phase*dx^2/(1i*lambda*f1);
fields.pupilAxis = lambda*f1*freq;
imageField = fftshift(ifft2(ifftshift(spectrum.*amp.*phase)))*R;
fields.image = flip(flip(imageField,1),2);
fields.imageAxis = flip(-((0:P-1)-floor(P/2))*dx/R);
end
