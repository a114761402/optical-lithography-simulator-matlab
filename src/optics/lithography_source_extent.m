function extent=lithography_source_extent(p)
% Source-grid support depends only on the active shape, not hidden stale controls.
switch p.sourceType
    case 'Point',extent=max(abs([p.pointSourceU,p.pointSourceV]))+.12;
    case {'Circular','Square','Annular'},extent=1.08*p.sourceOuter;
    case {'Dipole X','Dipole Y'},extent=1.08*(p.quadSeparation/2+p.sourceOuter);
    case 'Quadrupole',extent=p.quadSeparation/sqrt(2)+.6; % Gaussian lobes: six sigma margin.
    case 'Freeform',extent=1.08*lithography_custom_source_half(p);
    otherwise,error('Lithography:Settings','Unknown source shape.');
end
extent=max(extent,.1);
end
