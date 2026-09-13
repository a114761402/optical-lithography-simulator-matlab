function report=lithography_illumination_corner_tests()
% Tight-waist/off-axis views, wavelength/divergence extremes and runtime rejection.
count=0;
for lambda=[50,2000]
    for divergence=[.02,.15]
        for side=[-1,1]
            p=lithography_reference_params();p.sourceType='Point';p.wavelengthNm=lambda;
            p.sourceEmissionNA=divergence;p.pointSourceU=side;p.pointSourceV=-side;
            r=struct('sourceExtent',1.12,'sourceRaw',1);
            for aperture=[1,lambda*1e-9/(pi*.1)/(p.condenserFocalMm*1e-3*p.projNA/p.reduction)]
                p.condenserAperture=aperture;
                for z=[0,.001,59.999999,60,60.000001,119.999]
                    s=lithography_illumination_wave_slice(p,r,z);
                    b=lithography_gaussian_illumination(p,z);
                    [~,power]=lithography_gaussian_mode(b,0,0,side,-side);
                    peak=power*2*b.alpha/pi;
                    assert(all(isfinite(s.rawIntensity(:))) && abs(max(s.rawIntensity(:))/peak-1)<1e-7);
                    measured=sum(s.rawIntensity(:))*(s.axisXM(2)-s.axisXM(1))*(s.axisYM(2)-s.axisYM(1));
                    assert(abs(measured/power-1)<1e-7,'Off-axis beam escaped the plotted physical axes.');
                    count=count+1;
                end
            end
        end
    end
end
p=lithography_check_settings(lithography_reference_params());p.condenserAperture=.01;
rejected=false;
try,lithography_run_physics(p);catch e,rejected=strcmp(e.identifier,'Lithography:Settings') && contains(e.message,'continuous');end
assert(rejected,'Under-resolved source/condenser combination was not rejected.');count=count+1;
p.sourceType='Point';r=lithography_run_physics(p);
assert(r.illuminationQuadratureError<1e-12 && max(r.imageRaw(:))>0);count=count+1;
report=struct('pass',true,'passCount',count,'totalCount',count);
fprintf('Full illumination corner cases: %d/%d passed.\n',count,count);
end
