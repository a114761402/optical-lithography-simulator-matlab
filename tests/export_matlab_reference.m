% Reproducible numerical fixtures from the original MATLAB model.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(root);lithography_setup;
p=lithography_default_params();p.gridSize=64;p.sourceGridSize=201;
p.maxSourceSamples=49;p.propagationPadding=2;p.enforceLimits=false;
cases={};
for j=1:8
    q=p;
    switch j
        case 1, name='circular source image';z=450;
        case 2, name='point source image';q.sourceType='Point';z=450;
        case 3, name='defocus';q.sourceType='Point';q.defocusUm=15;z=450.015;
        case 4, name='near mask';q.sourceType='Point';q.maskType='Circular Aperture';q.maskSizeUm=20;z=200.001;
        case 5, name='before pupil';q.sourceType='Point';z=350;
        case 6, name='after pupil';q.sourceType='Point';z=410;
        case 7, name='continuous source plane';z=0;
        case 8, name='condenser exit';z=100;
    end
    r=lithography_run_physics(q);s=lithography_compute_xy_slice(q,r,z);
    c=struct('name',name,'params',q,'z',z,'screenAxis',s.axisM(:)',...
        'screenRaw',reshape(s.rawIntensity.',1,[]),'pupilRaw',reshape(r.pupilRaw.',1,[]),...
        'mask',reshape(r.mask.',1,[]),'samples',numel(r.sourceWeights));
    cases{end+1}=c;
end
fid=fopen(fullfile(fileparts(mfilename('fullpath')),'matlab-reference.json'),'w');
fprintf(fid,'%s',jsonencode(cases));fclose(fid);
fprintf('Exported %d MATLAB optical reference cases.\n',numel(cases));
