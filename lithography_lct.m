function out = lithography_lct(in,x,y,lambda,A,B,D)
% Collins integral evaluated by two Bluestein transforms, on metre axes.
if abs(B)<1e-15, error('Lithography:LCT','Use conjugate-plane transform when B is zero.'); end
dx=x(2)-x(1);
[X,Y]=meshgrid(x,x);
data=in.*exp(1i*pi*A*(X.^2+Y.^2)/(lambda*B));
data=scaledDFT(data,x,y,lambda*B);
data=scaledDFT(data.',x,y,lambda*B).';
[Xo,Yo]=meshgrid(y,y);
out=data.*exp(1i*pi*D*(Xo.^2+Yo.^2)/(lambda*B))*dx^2/(1i*lambda*B);
end
function out=scaledDFT(in,x,y,scale)
N=numel(x); M=numel(y); n=(0:N-1)'; m=(0:M-1)';
theta=(x(2)-x(1))*(y(2)-y(1))/scale;
pre=exp(-1i*2*pi*x(:)*y(1)/scale-1i*pi*theta*n.^2);
k=(-N+1:M-1)'; kernel=exp(1i*pi*theta*k.^2);
P=2^nextpow2(2*N+M-2);
full=ifft(fft(in.*pre,P,1).*fft(kernel,P),[],1);
out=full(N:N+M-1,:).*exp(-1i*pi*theta*m.^2-1i*2*pi*x(1)*(y(2)-y(1))*m/scale);
end
