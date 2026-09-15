function report=lithography_physicality_report(displayReport)
% Independent grid / window / source refinements on MATCHING metre axes.
if nargin<1,displayReport=true;end
cases={'Point','Circular','Annular'};
rows=struct('name',{},'imageError',{},'pupilError',{},'imageAbsoluteError',{},'pupilAbsoluteError',{},'pass',{});
for c=1:numel(cases)
    % Preserve the historical 256-pixel refinement fixtures. The current
    % practical startup has its own convergence suite and source limits.
    p=lithography_reference_params();p.sourceType=cases{c};p.sourceOuter=.7;
    if c==3,p.maskType='Circular Aperture';p.maskSizeUm=6;end
    p=lithography_check_settings(p);a=lithography_run_physics(p);
    for variation=1:3
        q=p;q.enforceLimits=false; % Deliberate numerical refinement of an admitted case.
        switch variation
            case 1,q.gridSize=384;label='pixel grid';
            case 2,q.propagationPadding=2*p.propagationPadding;label='window';
            case 3,q.maxSourceSamples=4*p.maxSourceSamples;label='source quadrature';
        end
        b=lithography_run_physics(q);
        [ei,ai]=physicalDifference(a.imageRaw,a.imageAxisM,b.imageRaw,b.imageAxisM,p.fieldSizeUm*1e-6/(2*p.reduction));
        [ep,ap]=physicalDifference(a.pupilRaw,a.pupilAxisM,b.pupilRaw,b.pupilAxisM,a.geometry.relayFocal2Mm*1e-3*p.projNA*1.1);
        rows(end+1)=struct('name',[cases{c} ' / ' label],'imageError',ei,'pupilError',ep,...
            'imageAbsoluteError',ai,'pupilAbsoluteError',ap,'pass',max([ei,ep,ai,ap])<.05);
        if displayReport,fprintf('%s: image %.5f, pupil %.5f; absolute %.5f / %.5f\n',rows(end).name,ei,ep,ai,ap);end
    end
end
report=struct('convergence',rows,'pass',all([rows.pass]),'passCount',sum([rows.pass]),'totalCount',numel(rows));
if displayReport
    fprintf('Numerical convergence: %d/%d within 5%%. This does not validate high-NA physical optics.\n',report.passCount,report.totalCount);
end
end
function [err,absoluteError]=physicalDifference(a,xa,b,xb,half)
inside=abs(xa)<=half;
axis=xa(inside);[X,Y]=meshgrid(axis,axis);
a=a(inside,inside);b=interp2(xb,xb,b,X,Y,'linear',0);
absoluteError=norm(a(:)-b(:))/max(norm(b(:)),realmin);
a=a/max(max(a(:)),eps);b=b/max(max(b(:)),eps);
err=norm(a(:)-b(:))/max(norm(b(:)),eps);
end
