function z=lithography_preview_z_grid(p,g)
% Bounded overview sampling, refined on BOTH sides of thin elements/foci.
% Distances in mm. The observation plane is not a finite propagation slab.
z=linspace(0,g.zSliceMax,121);
offsets=logspace(-7,0,8);
for plane=[g.zCondenser g.zField g.zPupil]
    z=[z plane plane-offsets plane+offsets]; %#ok<AGROW>
end
for plane=[g.zProjection1 g.zProjection2]
    z=[z plane plane+[-1 -.1 -.01 -.001 .001 .01 .1 1]]; %#ok<AGROW>
end
% Resolve focus at an optical, not a millimetre, distance scale.
focusScaleMm=p.wavelengthNm*1e-6/p.projNA^2;
offsets=unique([logspace(-7,0,12),focusScaleMm*[.01 .1 .5 1 2 5 10]]);
z=[z g.zImage g.zImage-offsets g.zImage+offsets,...
    g.zImageNominal,g.zImageNominal-offsets,g.zImageNominal+offsets,...
    logspace(-7,0,8),g.zField+.001,g.zField+.1];
z=unique(z(z>=0 & z<=g.zSliceMax));
end
