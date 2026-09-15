function report=lithography_settings_tests(verbose)
% Guarded-input tests are separate from unrestricted mathematical benchmarks.
if nargin<1,verbose=true;end
names={};ok=[];
p=lithography_reference_params();p.sourceType='Point';
p=lithography_check_settings(p);r=lithography_run_physics(p);g=r.geometry;
% Uniform circle: no clipped sides, no checkerboard, correct radius.
c=p;c.sourceType='Circular';s=lithography_illumination_wave_slice(c,sourceOnly(c),0);
[X,Y]=meshgrid(s.axisM,s.axisM);radius=c.sourceOuter*c.condenserFocalMm*1e-3*c.projNA/c.reduction;
interior=s.rawIntensity(hypot(X,Y)<.8*radius);
record('source wave has physical axes',strcmp(s.mode,'Wave') && strcmp(s.xlabelText,'x (um)'));
record('circle interior uniform',std(interior)/mean(interior)<1e-10);
record('circle is not truncated at 85 percent',max(abs(X(s.rawIntensity>.5*max(s.rawIntensity(:)))))>.97*radius);
sources={'Point','Circular','Square','Annular','Dipole X','Dipole Y','Quadrupole','Freeform'};
for j=1:numel(sources)
    c.sourceType=sources{j};
    for z=[0,g.zCondenser/2,g.zCondenser,g.zField-.001]
        s=lithography_illumination_wave_slice(c,sourceOnly(c),z);
        record([sources{j} ' wave illumination'],all(isfinite(s.rawIntensity(:))) && all(s.rawIntensity(:)>=0));
    end
end
c.sourceType='Freeform';c.customSourceMask=zeros(129);
for z=[0,g.zCondenser/2,g.zCondenser,g.zField-.001]
    s=lithography_illumination_wave_slice(c,sourceOnly(c),z);
    record('empty wave source stays dark',max(s.rawIntensity(:))==0);
end
% Valid zero aperture must block even the exactly on-axis point source.
c=p;c.condenserAperture=0;r0=lithography_run_physics(c);record('zero aperture dark',max(r0.imageRaw(:))==0);
bad={{'projNA',.31},{'projNA',NaN},{'projNA',Inf},{'sourceOuter',-.1},...
    {'condenserAperture',1.1},{'gratingDuty',.99},{'maskSizeUm',8},...
    {'wavelengthNm',2000},{'reduction',20},{'defocusUm',20},...
    {'fieldToPupilMm',86},{'customPupilMask',NaN},{'customSourceMask',ones(2,3)}};
for j=1:numel(bad)
    c=p;c.(bad{j}{1})=bad{j}{2};rejected=false;
    try,lithography_check_settings(c);catch e,rejected=strcmp(e.identifier,'Lithography:Settings');end
    record(['reject ' bad{j}{1}],rejected);
end
% Reproducible combinations: admission/explicit rejection, never silent clamp.
previous=rng;cleanup=onCleanup(@()rng(previous));rng(413);
accepted=0;rejected=0;
for j=1:2000
    c=p;c.projNA=.05+.25*rand;c.reduction=1+19*rand;c.wavelengthNm=50+1950*rand;
    c.fieldSizeUm=1+99*rand;c.maskSizeUm=.1+74.9*rand;c.gratingPitchUm=.1+49.9*rand;c.gratingDuty=.1+.8*rand;
    try
        c=lithography_check_settings(c);accepted=accepted+1;
        assert(c.gridSize<=512 && c.gridSize*c.propagationPadding<=2048);
        rr=lithography_run_physics(c);
        assert(all(isfinite(rr.imageRaw(:))) && max(rr.imageRaw(:))>0);
        for z=[rr.geometry.zField+.001,rr.geometry.zPupil,rr.geometry.zImage]
            ss=lithography_compute_xy_slice(c,rr,z);
            assert(all(isfinite(ss.rawIntensity(:))) && all(ss.rawIntensity(:)>=0));
        end
    catch e
        if ~strcmp(e.identifier,'Lithography:Settings'),rethrow(e);end
        rejected=rejected+1;
    end
end
record('2000 combinations, every admitted case propagated',accepted>0 && accepted+rejected==2000);
% Changing the numerical window at fixed dx must not move the physical grating.
c=p;c.enforceLimits=false;c.gratingPitchUm=.73;r1=lithography_run_physics(c);
c.fieldSizeUm=16;c.gridSize=512;r2=lithography_run_physics(c);
record('grating phase independent of numerical window',max(abs(r1.mask-r2.mask(129:384,129:384)),[],'all')<1e-12);
% All numeric entry fields reject NaN, infinity and complex values.
fields={'sourceOuter','sourceInner','quadSeparation','pointSourceU','pointSourceV','condenserAperture','sourceEmissionNA',...
    'maskSizeUm','maskInnerRatio','gratingPitchUm','gratingDuty','projNA','lensInner','reduction',...
    'wavelengthNm','fieldSizeUm','defocusUm','condenserFocalMm','projectionFocalMm'};
for j=1:numel(fields)
    for v=[NaN,Inf,1i]
        c=p;c.(fields{j})=v;failed=false;
        try,lithography_check_settings(c);catch e,failed=strcmp(e.identifier,'Lithography:Settings');end
        record(['invalid numeric ' fields{j}],failed);
    end
end
function r=sourceOnly(p)
extent=lithography_source_extent(p);[U,V]=meshgrid(linspace(-extent,extent,201));
r=struct('sourceExtent',extent,'sourceRaw',lithography_source_values(U,V,p));
end
% Every mask/pupil combination under an admitted common sampling configuration.
base=p;base.fieldSizeUm=16;base.maskSizeUm=4;base.gratingPitchUm=1.6;base.reduction=2;
masks={'Circular Aperture','Square Aperture','Diamond Aperture','Annular Aperture','1D Grating','2D Grating','Cross'};
pupils={'Circular','Annular','Square','Diamond','Horizontal Slit','Vertical Slit','Freeform'};
for m=1:numel(masks)
    for j=1:numel(pupils)
        c=base;c.maskType=masks{m};c.lensType=pupils{j};c=lithography_check_settings(c);rr=lithography_run_physics(c);gg=rr.geometry;
        good=all(isfinite(rr.image(:))) && max(rr.image(:))>0;
        for z=[gg.zField,gg.zField+.001,gg.zField+.1,gg.zPupil,gg.zImage]
            s=lithography_compute_xy_slice(c,rr,z);good=good && all(isfinite(s.intensity(:))) && all(s.intensity(:)>=0);
        end
        record([masks{m} '/' pupils{j}],good);
    end
end
for j=1:numel(sources)
    c=base;c.sourceType=sources{j};c=lithography_check_settings(c);rr=lithography_run_physics(c);
    record(['guarded wave source ' sources{j}],all(isfinite(rr.image(:))) && max(rr.image(:))>0);
end
for library={lithography_preset_library(),lithography_showcase_library()}
    entries=library{1};
    for j=2:numel(entries)
        c=lithography_check_settings(entries(j).params);
        record(['preset admitted ' entries(j).name],c.enforceLimits);
    end
end
% Original full-red example: absolute reference and a crop label are mandatory.
c=lithography_check_settings(lithography_reference_params());rr=lithography_run_physics(c);
s=lithography_compute_xy_slice(c,rr,rr.geometry.zField+.1);
record('near field uses shared brightness reference',s.normalizationPeak==rr.xyzReferencePeak);
record('cropped near field labelled',contains(s.viewNote,'Cropped'));
report=struct('names',{names},'passed',ok,'pass',all(ok),'passCount',sum(ok),'totalCount',numel(ok),...
    'randomAccepted',accepted,'randomRejected',rejected);
if verbose
    fprintf('Guarded settings: %d/%d passed; randomized settings: %d admitted, %d explicitly rejected.\n',sum(ok),numel(ok),accepted,rejected);
    for j=find(~ok),fprintf('FAIL: %s\n',names{j});end
end
    function record(name,value)
        names{end+1}=name;ok(end+1)=logical(value);
    end
end
