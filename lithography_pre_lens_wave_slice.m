function slice=lithography_pre_lens_wave_slice(p,r,z,peak)
if nargin<4, peak=[]; end
slice=lithography_projection_slice(p,r,z,peak);
end
