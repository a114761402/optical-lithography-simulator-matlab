function fieldOut = lithography_wave_propagate(fieldIn, lambda, dx, dz, padFactor)
if nargin < 5 || isempty(padFactor)
    padFactor = 4;
end

if abs(dz) < 1e-15
    fieldOut = fieldIn;
    return;
end

N = size(fieldIn, 1);
padN = padFactor * N;

fieldPad = zeros(padN, padN);
insertStart = floor((padN - N) / 2) + 1;
insertStop = insertStart + N - 1;
fieldPad(insertStart:insertStop, insertStart:insertStop) = fieldIn;

freq = ((0:padN-1) - padN/2) / (padN * dx);
[FX, FY] = meshgrid(freq, freq);
kzSquared = max((1 / lambda)^2 - FX.^2 - FY.^2, 0);
transfer = exp(1i * 2 * pi * dz * sqrt(kzSquared));
transfer = transfer .* double(FX.^2 + FY.^2 <= (1 / lambda)^2);

spectrum = fftshift(fft2(ifftshift(fieldPad)));
propagatedPad = fftshift(ifft2(ifftshift(spectrum .* transfer)));

cropStart = floor(padN / 2) - floor(N / 2) + 1;
cropStop = cropStart + N - 1;
fieldOut = propagatedPad(cropStart:cropStop, cropStart:cropStop);
end
