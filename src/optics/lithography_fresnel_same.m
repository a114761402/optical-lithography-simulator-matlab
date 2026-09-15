function out = lithography_fresnel_same(in,lambda,dx,z)
% Linear-convolution Fresnel integral; small z uses an oversampled transfer.
if abs(z)<1e-15, out=in; return; end
N=size(in,1);
if abs(z) < 4*N*dx^2/lambda || N>512
    % Bound every FFT, including propagation of an already padded image.
    P=min(4*N,2048); a=floor(P/2)-floor(N/2)+1;
    padded=zeros(P,P); padded(a:a+N-1,a:a+N-1)=in;
    f=((0:P-1)-floor(P/2))/(P*dx); [FX,FY]=meshgrid(f,f);
    H=exp(-1i*pi*lambda*z*(FX.^2+FY.^2));
    cutoff=P*dx/(2*lambda*abs(z));
    H=H.*double(abs(FX)<=cutoff & abs(FY)<=cutoff);
    data=fftshift(ifft2(ifftshift(fftshift(fft2(ifftshift(padded))).*H)));
    out=data(a:a+N-1,a:a+N-1);
else
    x=(-N+1:N-1)*dx; [X,Y]=meshgrid(x,x);
    h=exp(1i*pi*(X.^2+Y.^2)/(lambda*z))*dx^2/(1i*lambda*z);
    P=2^nextpow2(3*N-2);
    data=ifft2(fft2(in,P,P).*fft2(h,P,P));
    out=data(N:2*N-1,N:2*N-1);
end
end
