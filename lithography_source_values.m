function value=lithography_source_values(U,V,p)
% Continuous source intensity definition shared by wave and schematic views.
switch p.sourceType
    case 'Point'
        value=zeros(size(U));[~,i]=min((U(:)-p.pointSourceU).^2+(V(:)-p.pointSourceV).^2);value(i)=1;
    case 'Circular',value=double(hypot(U,V)<=p.sourceOuter);
    case 'Square',value=double(max(abs(U),abs(V))<=p.sourceOuter);
    case 'Annular',value=double(hypot(U,V)<=p.sourceOuter & hypot(U,V)>=p.sourceInner);
    case 'Dipole X'
        value=double(hypot(U-p.quadSeparation/2,V)<=p.sourceOuter)+double(hypot(U+p.quadSeparation/2,V)<=p.sourceOuter);
    case 'Dipole Y'
        value=double(hypot(U,V-p.quadSeparation/2)<=p.sourceOuter)+double(hypot(U,V+p.quadSeparation/2)<=p.sourceOuter);
    case 'Quadrupole'
        value=zeros(size(U));d=p.quadSeparation/sqrt(2);
        for x=[-d,d],for y=[-d,d],value=value+exp(-((U-x).^2+(V-y).^2)/(2*.10^2));end,end
    case 'Freeform',value=lithography_custom_source_values(U,V,p);
    otherwise,error('Lithography:Source','Unknown source shape.');
end
end
