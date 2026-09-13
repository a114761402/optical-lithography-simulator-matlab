function beam = lithography_gaussian_illumination(p,zMm)
% Incoherent displaced Gaussian waists; exact paraxial Gaussian propagation.
% U_q(r)=gain*exp(-a*r^2+b*q.r+c*q^2). Each incident mode has unit power.
lambda=p.wavelengthNm*1e-9;
w0=lambda/(pi*p.sourceEmissionNA);
beam=struct('a',1/w0^2,'b',2/w0^2,'c',-1/w0^2,...
    'gain',sqrt(2/(pi*w0^2)),'waistM',w0,...
    'sourceScaleM',p.condenserFocalMm*1e-3*p.projNA/p.reduction);
beam.apertureRadiusM=beam.sourceScaleM*p.condenserAperture;
zC=p.sourceToCondenserMm;
beam=propagate(beam,lambda,min(zMm,zC)*1e-3);
if zMm>=zC
    beam.a=beam.a+1i*pi/(lambda*p.condenserFocalMm*1e-3);
    if beam.apertureRadiusM==0
        beam.gain=0;
    else
        beam.a=beam.a+1/beam.apertureRadiusM^2;
    end
    beam=propagate(beam,lambda,(zMm-zC)*1e-3);
end
beam.alpha=real(beam.a);
beam.eta=real(beam.b)/(2*beam.alpha);
% Complete the square. beta is nonpositive for this passive optical system.
beam.beta=min(0,real(beam.c)+real(beam.b)^2/(4*beam.alpha));
beam.powerPrefactor=abs(beam.gain)^2*pi/(2*beam.alpha);
end

function b=propagate(b,lambda,d)
D=1+1i*lambda*d*b.a/pi;
b.c=b.c+1i*lambda*d*b.b^2/(4*pi*D);
b.b=b.b/D;
b.a=b.a/D;
b.gain=b.gain/D;
end
