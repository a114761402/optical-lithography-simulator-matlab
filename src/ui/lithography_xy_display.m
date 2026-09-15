function view=lithography_xy_display(slice,mode)
% Pure display transform: the stored field/intensity is never modified.
raw=slice.rawIntensity;
if isempty(raw) || any(~isfinite(raw(:))) || any(raw(:)<0)
    error('Lithography:XYData','XY intensity must be finite, nonnegative and nonempty.');
end
peak=max(raw(:));
shared=[];
if isfield(slice,'xyzReferencePeak'),shared=slice.xyzReferencePeak;
elseif strcmp(slice.normalizationMode,'XYZ'),shared=slice.normalizationPeak;end
validShared=isscalar(shared) && isfinite(shared) && shared>0;
local=startsWith(mode,'Local');
if local
    reference=peak;
    note='Shape only: this plane is rescaled; colours do not compare brightness across z.';
elseif validShared
    reference=shared;
    note='Shared reference: colours compare intensity across z.';
else
    error('Lithography:XYReference','A positive shared intensity reference is required.');
end
if ~ismember(mode,{'Local linear','Local log (dB)','XYZ linear','XYZ log (dB)'})
    error('Lithography:XYScale','Unknown XY display scale.');
end
isLog=contains(mode,'log');
if peak==0
    values=zeros(size(raw));
    if isLog,values(:)=-120;end
    note='DARK: calculated intensity is zero everywhere in this window.';
elseif isLog
    % Subtract logarithms to preserve ratios even for subnormal intensities.
    values=max(-120,10*(log10(raw)-log10(reference)));
else
    values=raw/reference;
end
if isLog
    limits=[-120 0];ticks=[-120 -60 0];
    label=[mode ' | floor -120 dB'];
else
    limits=[0 1];ticks=[0 .5 1];
    label=mode;
    if ~local && peak>0 && max(values(:))<.01
        note='Nonzero but faint on this scale: choose Local linear or XYZ log (dB).';
    end
end
if ~local && peak>reference
    note='Above XYZ reference: colours saturate; choose Local to inspect shape. Raw values are unchanged.';
end
relativeDb=NaN;
if validShared,relativeDb=10*(log10(peak)-log10(shared));end
view=struct('values',values,'limits',limits,'ticks',ticks,'label',label,...
    'note',note,'reference',reference,'peak',peak,'relativeDb',relativeDb);
end
