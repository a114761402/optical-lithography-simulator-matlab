function pupil = lithography_pupil_amplitude(U,V,p)
r = hypot(U,V);
switch p.lensType
    case 'Circular', pupil = double(r<=1);
    case 'Annular', pupil = double(r<=1 & r>=p.lensInner);
    case 'Square', pupil = double(abs(U)<=1/sqrt(2) & abs(V)<=1/sqrt(2));
    case 'Diamond', pupil = double(abs(U)+abs(V)<=1);
    case 'Horizontal Slit'
        s=max(p.lensInner,.03);a=1/sqrt(1+s^2);pupil=double(abs(U)<=a & abs(V)<=a*s);
    case 'Vertical Slit'
        s=max(p.lensInner,.03);a=1/sqrt(1+s^2);pupil=double(abs(V)<=a & abs(U)<=a*s);
    case 'Freeform', pupil = lithography_custom_pupil_values(U,V,p);
    otherwise, error('Lithography:Pupil','Unknown pupil shape.');
end
% NA is the largest transmitted sine angle, including noncircular pupils.
pupil = pupil.*double(r<=1);
end
