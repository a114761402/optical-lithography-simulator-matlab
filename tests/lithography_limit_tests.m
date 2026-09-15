function report=lithography_limit_tests()
% Accepted extreme combinations, including nonzero defocus after grid padding.
% Rows: wavelength nm, window um, mask um, R, NA, absolute defocus um.
rows=[50,8,2,4,.25,3;193,8,2,4,.25,5;2000,32,12,1,.3,20;1000,100,50,20,.3,20;193,8,2,1,.05,20];
passed=true;count=0;
for j=1:size(rows,1)
    for sign=[-1,0,1]
        p=lithography_default_params();p.sourceType='Point';p.maskType='Square Aperture';
        p.wavelengthNm=rows(j,1);p.fieldSizeUm=rows(j,2);p.maskSizeUm=rows(j,3);
        p.reduction=rows(j,4);p.projNA=rows(j,5);p.defocusUm=sign*rows(j,6);
        p=lithography_check_settings(p);r=lithography_run_physics(p);g=r.geometry;
        for z=[g.zField,g.zField+.001,g.zField+.1,g.zProjection1,g.zPupil,g.zProjection2,g.zImage,g.zImage+.001,g.zSliceMax]
            s=lithography_compute_xy_slice(p,r,z);
            good=all(isfinite(s.intensity(:))) && all(s.intensity(:)>=0) && max(s.rawIntensity(:))>0;
            assert(good,'Invalid extreme case %d at z %g',j,z);count=count+1;
        end
    end
end
% Full-path wave preview also respects closed condenser and shared normalization.
p=lithography_check_settings(lithography_default_params());p.sourceType='Point';p.condenserAperture=0;
r=lithography_run_physics(p);y=lithography_compute_yz_intensity(p,r);
assert(all(y.rawIntensity(:,y.zMm>=r.geometry.zCondenser)==0,'all'));count=count+1;
assert(strcmp(y.normalizationMode,'XYZ') && isfield(y,'axisHalfWidthMm'));count=count+1;
report=struct('pass',passed,'passCount',count,'totalCount',count);
fprintf('Accepted-limit tests: %d/%d passed.\n',count,count);
end
