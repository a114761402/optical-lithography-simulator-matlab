function result = lithography_run_physics(params)
if isfield(params,'enforceLimits') && params.enforceLimits
    planned=lithography_check_settings(params);
    if planned.gridSize~=params.gridSize || planned.propagationPadding~=params.propagationPadding || ...
            planned.sourceGridSize~=params.sourceGridSize || planned.maxSourceSamples~=params.maxSourceSamples
        error('Lithography:Settings','Sampling needs adjustment. First use p = lithography_check_settings(p).');
    end
end
validateattributes(params.gridSize, {'numeric'}, {'scalar','integer','>=',16,'<=',2048});
validateattributes(params.fieldSizeUm, {'numeric'}, {'scalar','positive','finite'});
validateattributes(params.wavelengthNm, {'numeric'}, {'scalar','positive','finite'});
validateattributes(params.reduction, {'numeric'}, {'scalar','>=',1,'finite'});
validateattributes(params.projNA, {'numeric'}, {'scalar','>',0,'<=',1});
validateattributes(params.sourceGridSize, {'numeric'}, {'scalar','integer','>=',3});
validateattributes(params.maxSourceSamples, {'numeric'}, {'scalar','integer','>=',1});
if isfield(params,'propagationPadding')
    validateattributes(params.propagationPadding,{'numeric'},{'scalar','integer','>=',1,'<=',8});
    if params.gridSize*params.propagationPadding>2048
        error('Lithography:GridBudget','Padded grid must not exceed 2048. Reduce grid or padding.');
    end
end
N=params.gridSize;
dx=params.fieldSizeUm*1e-6/N;
x=((0:N-1)-floor(N/2))*dx;
[X,Y]=meshgrid(x,x);
extent=sourceCoordinateExtent(params);
if isfield(params,'illuminationModel') && strcmp(params.illuminationModel,'Incoherent Gaussian emitters')
    extent=lithography_source_extent(params);
end
[U,V]=meshgrid(linspace(-extent,extent,params.sourceGridSize));
displaySource=makeSource(U,V,params);
fullWave=isfield(params,'illuminationModel') && strcmp(params.illuminationModel,'Incoherent Gaussian emitters');
samplingParams=params;
if fullWave
    source=displaySource;
    samplingParams.condenserAperture=Inf; % Weights describe emitters BEFORE condenser loss.
else
    source=displaySource.*double(params.condenserAperture>0 & hypot(U,V)<=params.condenserAperture);
end
[u,v,w,active,used]=sampleSource(U,V,source,samplingParams);
if any(hypot(u,v).*double(w>0)*params.projNA/params.reduction>=1)
    error('Lithography:SourceAngle','Illumination direction must be a propagating wave in air.');
end
if ~strcmp(params.sourceType,'Point')
    w=w*sum(source(:))/max(sum(displaySource(:)),eps);
end
result=struct('mask',makeMask(X,Y,params),'objectAxisM',x,...
    'sourceRaw',displaySource,'source',safeNormalize(displaySource),...
    'sourceSamplesU',u,'sourceSamplesV',v,'sourceWeights',w,...
    'sourceCount',numel(w),'sourceActiveCount',active,'sourceUsedCount',used,...
    'sourceSamplingClipped',used<active,'sourceExtent',extent,...
    'maskExtentUm',params.fieldSizeUm/2,'projectionRelay',buildProjectionRelay(params));
result.geometry=lithography_projection_geometry(params,result.projectionRelay);
if fullWave
    result.maskIllumination=lithography_gaussian_illumination(params,result.geometry.zField);
    checkAxis=linspace(-params.maskSizeUm*.5e-6,params.maskSizeUm*.5e-6,7);
    reference=lithography_illumination_wave_slice(params,result,result.geometry.zField,[],checkAxis);
    sampled=zeros(numel(checkAxis));
    for j=1:numel(w)
        input=lithography_gaussian_mode(result.maskIllumination,checkAxis,checkAxis,u(j),v(j));
        sampled=sampled+w(j)*abs(input).^2;
    end
    result.illuminationQuadratureError=norm(sampled(:)-reference.rawIntensity(:))/max(norm(reference.rawIntensity(:)),realmin);
    if params.enforceLimits && result.illuminationQuadratureError>.02
        error('Lithography:Settings','Source quadrature differs from the continuous illumination integral by %.2f%% (limit 2%%). Enlarge the Gaussian condenser radius or reduce source extent; this result is not displayed.',100*result.illuminationQuadratureError);
    end
end
result.maskIncidentRaw=zeros(N); result.maskExitRaw=zeros(N);
result.pupilRaw=[]; result.imageRaw=[];
for k=1:numel(w)
    f=lithography_coherent_fields(params,result,u(k),v(k));
    if isempty(result.pupilRaw)
        result.pupilRaw=zeros(size(f.pupil)); result.imageRaw=zeros(size(f.image));
    end
    if w(k)==0, continue; end
    result.maskIncidentRaw=result.maskIncidentRaw+w(k)*abs(f.incident).^2;
    result.maskExitRaw=result.maskExitRaw+w(k)*abs(f.mask).^2;
    result.pupilRaw=result.pupilRaw+w(k)*abs(f.pupil).^2;
    field=lithography_fresnel_same(f.image,params.wavelengthNm*1e-9,...
        f.imageAxis(2)-f.imageAxis(1),params.defocusUm*1e-6);
    result.imageRaw=result.imageRaw+w(k)*abs(field).^2;
end
result.pupilAxisM=f.pupilAxis; result.imageAxisM=f.imageAxis;
if any(~isfinite(result.pupilRaw(:))) || any(~isfinite(result.imageRaw(:)))
    error('Lithography:Numerics','Nonfinite field; no image is shown. Check sampling and geometry.');
end
result.imageExtentUm=max(abs(f.imageAxis))*1e6;
result.pupilSampledRaw=result.pupilRaw;
result.pupilSampled=safeNormalize(result.pupilRaw);
result.pupil=result.pupilSampled;
result.image=safeNormalize(result.imageRaw);
result.pupilNativeExtent=max(abs(f.pupilAxis))/(result.geometry.relayFocal2Mm*1e-3*params.projNA);
result.pupilDisplayExtent=1.1;
result.freqExtent=result.pupilNativeExtent;
result.pupilConsistencyError=0; % Shared result, NOT an independent accuracy check.
result.illuminationDetuneMm=params.sourceToCondenserMm-params.condenserFocalMm;
result.focusDetuneMm=params.fieldToPupilMm-params.projectionFocalMm;
result.xyzReferencePeak=max([max(result.pupilRaw(:)),max(result.imageRaw(:)),max(result.maskIncidentRaw(:)),eps]);
if fullWave
    sourceSlice=lithography_illumination_wave_slice(params,result,0,[]);
    result.sourceReferencePeak=max(sourceSlice.rawIntensity(:));
    result.xyzReferencePeak=max(result.xyzReferencePeak,result.sourceReferencePeak);
    b=result.maskIllumination;
    result.condenserTransmission=sum(w.*(b.powerPrefactor*exp(2*b.beta*b.sourceScaleM^2*(u.^2+v.^2))));
    result.sourcePower=sum(w);
end
end
function source = makeSource(U,V,params)
source=safeNormalize(lithography_source_values(U,V,params));
end

function source = applyCondenserAperture(U, V, source, params)
apertureMask = double(sqrt(U.^2 + V.^2) <= params.condenserAperture);
source = source .* apertureMask;
source = safeNormalize(source);
end

function mask = makeMask(X, Y, params)
% Pixel-area quadrature avoids grid-dependent extra rows on aperture edges.
dx=X(1,2)-X(1,1);
mask=zeros(size(X));
for sx=[-.375,-.125,.125,.375]
    for sy=[-.375,-.125,.125,.375]
        mask=mask+binaryMask(X+sx*dx,Y+sy*dx,params)/16;
    end
end
end

function mask = binaryMask(X,Y,params)
featureSize = params.maskSizeUm * 1e-6;

switch params.maskType
    case 'Circular Aperture'
        mask = double(X.^2 + Y.^2 <= (featureSize / 2)^2);

    case 'Square Aperture'
        mask = double(abs(X) <= featureSize / 2 & abs(Y) <= featureSize / 2);

    case 'Diamond Aperture'
        mask = double(abs(X) + abs(Y) <= featureSize / 2);

    case 'Annular Aperture'
        outerRadius = featureSize / 2;
        innerRadius = params.maskInnerRatio * outerRadius;
        radius = sqrt(X.^2 + Y.^2);
        mask = double(radius <= outerRadius & radius >= innerRadius);

    case '1D Grating'
        pitch = params.gratingPitchUm * 1e-6;
        duty = params.gratingDuty;
        gratingEnvelope = double(abs(X) <= featureSize / 2 & abs(Y) <= featureSize / 2);
        gratingPattern = double(abs(mod(X+pitch/2,pitch)-pitch/2) < duty*pitch/2);
        mask = gratingEnvelope .* gratingPattern;

    case '2D Grating'
        pitch = params.gratingPitchUm * 1e-6;
        duty = params.gratingDuty;
        gratingEnvelope = double(abs(X) <= featureSize / 2 & abs(Y) <= featureSize / 2);
        xPass = abs(mod(X+pitch/2,pitch)-pitch/2) < duty*pitch/2;
        yPass = abs(mod(Y+pitch/2,pitch)-pitch/2) < duty*pitch/2;
        mask = gratingEnvelope .* double(xPass & yPass);

    case 'Cross'
        armWidth = featureSize / 3;
        mask = double((abs(X) <= armWidth / 2 & abs(Y) <= featureSize / 2) | ...
                      (abs(Y) <= armWidth / 2 & abs(X) <= featureSize / 2));

    otherwise
        mask = double(X.^2 + Y.^2 <= (featureSize / 2)^2);
end
end

function pupil = makeProjectionPupil(freqRadius, Ufreq, Vfreq, params)
switch params.lensType
    case 'Circular'
        pupil = double(freqRadius <= 1);

    case 'Annular'
        pupil = double(freqRadius <= 1 & freqRadius >= params.lensInner);

    case 'Square'
        pupil = double(abs(Ufreq) <= 1 & abs(Vfreq) <= 1);

    case 'Diamond'
        pupil = double(abs(Ufreq) + abs(Vfreq) <= 1);

    case 'Horizontal Slit'
        slitHalf = max(params.lensInner, 0.03);
        pupil = double(abs(Vfreq) <= slitHalf & abs(Ufreq) <= 1);

    case 'Vertical Slit'
        slitHalf = max(params.lensInner, 0.03);
        pupil = double(abs(Ufreq) <= slitHalf & abs(Vfreq) <= 1);

    case 'Freeform'
        pupil = lithography_custom_pupil_values(Ufreq, Vfreq, params);

    otherwise
        pupil = double(freqRadius <= 1);
end
end

function [sampleU, sampleV, sampleW, activeCount, usedCount] = sampleSource(U, V, source, params)
if strcmp(params.sourceType, 'Point')
    sampleU = params.pointSourceU;
    sampleV = params.pointSourceV;
    sampleW = double(params.condenserAperture>0 && hypot(sampleU,sampleV) <= params.condenserAperture);
    activeCount = 1;
    usedCount = 1;
    return;
end

selectionMask = source > 0;
activeCount = nnz(selectionMask);
if activeCount == 0
    sampleU = 0;
    sampleV = 0;
    sampleW = 0;
    activeCount = 0;
    usedCount = 0;
    return;
end

if activeCount <= params.maxSourceSamples
    indices = find(selectionMask);
    sampleU = U(indices);
    sampleV = V(indices);
    sampleW = source(indices);
    sampleW = sampleW / sum(sampleW);
    usedCount = numel(sampleW);
    return;
end

binCount = ceil(sqrt(params.maxSourceSamples));
rowEdges = round(linspace(1, size(source, 1) + 1, binCount + 1));
colEdges = round(linspace(1, size(source, 2) + 1, binCount + 1));
rowEdges(end) = size(source, 1) + 1;
colEdges(end) = size(source, 2) + 1;
rowEdges = unique(rowEdges);
colEdges = unique(colEdges);

sampleU = [];
sampleV = [];
sampleW = [];

for rowIdx = 1:(numel(rowEdges) - 1)
    rows = rowEdges(rowIdx):(rowEdges(rowIdx + 1) - 1);
    if isempty(rows)
        continue;
    end
    for colIdx = 1:(numel(colEdges) - 1)
        cols = colEdges(colIdx):(colEdges(colIdx + 1) - 1);
        if isempty(cols)
            continue;
        end
        cellWeights = source(rows, cols) .* selectionMask(rows, cols);
        totalWeight = sum(cellWeights(:));
        if totalWeight <= 0
            continue;
        end
        cellU = U(rows, cols);
        cellV = V(rows, cols);
        sampleU(end + 1, 1) = sum(cellU(:) .* cellWeights(:)) / totalWeight; %#ok<AGROW>
        sampleV(end + 1, 1) = sum(cellV(:) .* cellWeights(:)) / totalWeight; %#ok<AGROW>
        sampleW(end + 1, 1) = totalWeight; %#ok<AGROW>
    end
end

usedCount = numel(sampleW);
sampleW = sampleW / max(sum(sampleW), eps);
end

function sourceKernel = makeSourceKernelAtPupil(Ufreq, Vfreq, illuminationAngleScale, params)
scale = max(abs(illuminationAngleScale), eps);
sourceU = Ufreq / scale;
sourceV = Vfreq / scale;
source = makeSource(sourceU, sourceV, params);
source = applyCondenserAperture(sourceU, sourceV, source, params);
sourceKernel = source / max(sum(source(:)), eps);
end

function convSame = fftConvolveSame(arrayA, arrayB)
sizeA = size(arrayA);
sizeB = size(arrayB);
sizeConv = sizeA + sizeB - 1;

fftA = fft2(arrayA, sizeConv(1), sizeConv(2));
fftB = fft2(arrayB, sizeConv(1), sizeConv(2));
fullConv = real(ifft2(fftA .* fftB));

startRow = floor(sizeB(1) / 2) + 1;
startCol = floor(sizeB(2) / 2) + 1;
convSame = fullConv(startRow:(startRow + sizeA(1) - 1), startCol:(startCol + sizeA(2) - 1));
end

function projection = buildProjectionRelay(params)
projection = struct();
projection.modelType = 'equivalent-4f-relay';
projection.imageDistanceMm = params.projectionFocalMm / params.reduction;
projection.magnification = -1 / params.reduction;
projection.absMagnification = abs(projection.magnification);
end

function extent = sourceCoordinateExtent(params)
extent = 1.10;
extent = max(extent, 1.08 * params.sourceOuter);
extent = max(extent, 1.08 * params.sourceInner);
extent = max(extent, 0.55 * params.quadSeparation + 1.08 * params.sourceOuter);
extent = max(extent, params.quadSeparation + 0.28);
extent = max(extent, 1.02 * params.condenserAperture);
extent = max(extent, abs(params.pointSourceU) + 0.12);
extent = max(extent, abs(params.pointSourceV) + 0.12);
if strcmp(params.sourceType, 'Freeform')
    extent = max(extent, 1.08 * lithography_custom_source_half(params));
end
end

function extent = pupilCoordinateExtent(params)
extent = 1.10;
extent = max(extent, 1.08 * params.sourceOuter);
extent = max(extent, 1.08 * params.sourceInner);
extent = max(extent, 0.55 * params.quadSeparation + 1.08 * params.sourceOuter);
extent = max(extent, params.quadSeparation + 0.28);
extent = max(extent, abs(params.pointSourceU) + 0.12);
extent = max(extent, abs(params.pointSourceV) + 0.12);
if strcmp(params.sourceType, 'Freeform')
    extent = max(extent, 1.08 * lithography_custom_source_half(params));
end
end

function data = safeNormalize(data)
peak = max(data(:));
if peak > 0
    data = data / peak;
end
end

function diffValue = normalizedDifference(dataA, dataB)
denominator = max(norm(dataA(:)), eps);
diffValue = norm(dataA(:) - dataB(:)) / denominator;
end
