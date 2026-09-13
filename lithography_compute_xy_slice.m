function slice=lithography_compute_xy_slice(p,r,z,peak)
if nargin<2 || isempty(r), r=lithography_run_physics(p); end
if nargin<3, z=r.geometry.zImage; end
if nargin<4, peak=[]; end
validateattributes(z,{'numeric'},{'scalar','finite'});
g=r.geometry;
if z<0 || z>g.zSliceMax
    error('Lithography:SliceRange','z must lie between 0 and %.3f mm.',g.zSliceMax);
end
if z>=g.zField
    slice=lithography_projection_slice(p,r,z,peak);
elseif isfield(r,'maskIllumination')
    slice=lithography_illumination_wave_slice(p,r,z,peak);
else
    g.sourceHalf=max(.08,p.sourceOuter);
    slice=lithography_compute_illumination_xy_slice(p,g,z,p.yzMode,201);
    slice.titleText='Geometrical illumination schematic (not diffraction)';
    slice.model='Schematic'; slice.normalizationMode='Local';
    schematic=p;schematic.intensityNorm='Local';
    [slice.intensity,slice.normalizationPeak]=lithography_normalize_intensity(slice.rawIntensity,schematic,r,[]);
end
% Retain the physical reference independently of the selected display scale.
if isfield(r,'xyzReferencePeak'),slice.xyzReferencePeak=r.xyzReferencePeak;end
end
