function fieldOut = lithography_wave_propagate(fieldIn, lambda, dx, dz, padFactor)
if nargin < 5 || isempty(padFactor)
    padFactor = 4;
end

if abs(dz) < 1e-15
    fieldOut = fieldIn;
    return;
end

if dz < 0
    error('Lithography:Propagation','RS propagation requires a nonnegative distance.');
end
% Linear convolution of the RS kernel, without periodic wraparound.
maxTransverse = sqrt(2)*size(fieldIn,1)*dx;
kernelSampling = dx*maxTransverse/(lambda*hypot(maxTransverse,dz));
if dz >= 4*dx && kernelSampling < 0.45
    N = size(fieldIn,1);
    offsets = (-N+1:N-1)*dx;
    [X,Y] = meshgrid(offsets,offsets);
    r = sqrt(X.^2+Y.^2+dz^2);
    h = dz./r.^2.*(1./(2*pi*r)-1i/lambda).*exp(1i*2*pi*r/lambda)*dx^2;
    P = 2^nextpow2(3*N-2);
    data = ifft2(fft2(fieldIn,P,P).*fft2(h,P,P));
    fieldOut = data(N:2*N-1,N:2*N-1);
    return;
end
N = size(fieldIn, 1);
padN = padFactor * N;

fieldPad = zeros(padN, padN);
insertStart = floor(padN/2)-floor(N/2)+1;
insertStop = insertStart + N - 1;
fieldPad(insertStart:insertStop, insertStart:insertStop) = fieldIn;

freq = ((0:padN-1) - padN/2) / (padN * dx);
[FX, FY] = meshgrid(freq, freq);
kzSquared = (1 / lambda)^2 - FX.^2 - FY.^2;
transfer = exp(1i * 2 * pi * dz * sqrt(complex(kzSquared)));
if dz>=4*dx
    % Nyquist limits for transfer-phase gradients, not a cosmetic blur.
    transfer=transfer.*double(kzSquared >= (2*dz*FX/(padN*dx)).^2 & ...
        kzSquared >= (2*dz*FY/(padN*dx)).^2);
end

spectrum = fftshift(fft2(ifftshift(fieldPad)));
propagatedPad = fftshift(ifft2(ifftshift(spectrum .* transfer)));

cropStart = floor(padN / 2) - floor(N / 2) + 1;
cropStop = cropStart + N - 1;
fieldOut = propagatedPad(cropStart:cropStop, cropStart:cropStop);
end
