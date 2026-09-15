function [field,power]=lithography_gaussian_mode(beam,x,y,u,v)
% Stable completed-square evaluation; global phase of each incoherent mode omitted.
qx=beam.sourceScaleM*u; qy=beam.sourceScaleM*v;
power=beam.powerPrefactor*exp(2*beam.beta*(qx^2+qy^2));
[X,Y]=meshgrid(x,y);
envelope=sqrt(power*2*beam.alpha/pi)*...
    exp(-beam.alpha*((X-beam.eta*qx).^2+(Y-beam.eta*qy).^2));
field=envelope.*exp(1i*(-imag(beam.a)*(X.^2+Y.^2)+imag(beam.b)*(qx*X+qy*Y)));
end
