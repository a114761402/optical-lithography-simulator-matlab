function items=lithography_plane_sizes(p,r)
% Transverse dimensions of model elements, not inferred mechanical diameters.
g=r.geometry;
template=struct('name','','zMm',0,'caption',{{}},'thumbnail',[],'widthXY',[],'unit','mm');
items=repmat(template,1,6);
names={'Condenser','Mask patch','Lens 1','Pupil','Lens 2','Image ROI'};
z=[g.zCondenser g.zField g.zProjection1 g.zPupil g.zProjection2 g.zImage];
for j=1:6,items(j).name=names{j};items(j).zMm=z(j);end
radius=p.condenserFocalMm*p.projNA/p.reduction*p.condenserAperture;
[U,V]=meshgrid(linspace(-1.4,1.4,65));
items(1).thumbnail=exp(-2*(U.^2+V.^2))*double(radius>0);
items(1).widthXY=[2 2]*radius;
items(1).caption={'Gaussian',sprintf('1/e² I Ø %.3g mm',2*radius),'No hard edge'};
if radius==0,items(1).caption={'Condenser closed','No transmitted light'};end
maskInside=abs(r.objectAxisM*1e6)<=.6*p.maskSizeUm;
items(2).thumbnail=r.mask(maskInside,maskInside);items(2).widthXY=[1 1]*p.maskSizeUm;items(2).unit='um';
items(2).caption={p.maskType,sprintf('Box %.3g x %.3g um',p.maskSizeUm,p.maskSizeUm)};
if any(strcmp(p.maskType,{'Circular Aperture','Annular Aperture'}))
    items(2).caption{2}=sprintf('Outer diam. %.3g um',p.maskSizeUm);
end
if contains(p.maskType,'Grating'),items(2).caption{3}=sprintf('Pitch %.3g um',p.gratingPitchUm);end
for j=[3 5]
    focal=g.relayFocal1Mm;if j==5,focal=g.relayFocal2Mm;end
    items(j).widthXY=[Inf Inf];
    items(j).caption={sprintf('f = %.3g mm',focal),'Ideal, unbounded'};
end
diameter=2*g.relayFocal2Mm*p.projNA;
[U,V]=meshgrid(linspace(-1.1,1.1,81));
items(4).thumbnail=lithography_pupil_amplitude(U,V,p);
width=[diameter diameter];
switch p.lensType
    case 'Square',width=width/sqrt(2);
    case {'Horizontal Slit','Vertical Slit'}
        s=max(p.lensInner,.03);width=diameter*[1 s]/sqrt(1+s^2);
        if strcmp(p.lensType,'Vertical Slit'),width=fliplr(width);end
end
items(4).widthXY=width;
items(4).caption={p.lensType,sprintf('%.3g x %.3g mm',width)};
if any(strcmp(p.lensType,{'Circular','Annular'}))
    items(4).caption{2}=sprintf('Outer diam. %.3g mm',diameter);
end
if strcmp(p.lensType,'Annular'),items(4).caption{3}=sprintf('Inner diam. %.3g mm',diameter*p.lensInner);end
if strcmp(p.lensType,'Freeform'),items(4).caption{2}=sprintf('NA envelope %.3g mm',diameter);end
roi=p.fieldSizeUm/p.reduction;
axisUm=r.imageAxisM*1e6;inside=abs(axisUm)<=roi/2;
items(6).thumbnail=r.image(inside,inside);
items(6).widthXY=[roi roi];items(6).unit='um';
items(6).caption={sprintf('View %.3g x %.3g um',roi,roi),'Not spot size'};
end
