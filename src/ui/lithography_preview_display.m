function view=lithography_preview_display(yz,scaleMode)
% Display transform only. Never alter the stored, physical wave intensity.
raw=yz.rawIntensity;
switch scaleMode
    case 'Local / z'
        peaks=max(raw,[],1);
        values=raw./max(peaks,realmin);
        label='Local / z';limits=[0 1];ticks=[0 .5 1];
        note='Each z rescaled: shape only, not brightness';
    case 'XYZ linear'
        reference=sharedReference(yz);
        values=raw/reference;label='XYZ linear';limits=[0 1];ticks=[0 .5 1];
        note='Shared linear scale: weak light can appear black';
    case 'XYZ log (dB)'
        reference=sharedReference(yz);
        values=10*log10(max(raw/reference,1e-12));
        label='XYZ (dB)';limits=[-120 0];ticks=[-120 -60 0];
        note='Shared logarithmic scale; floor -120 dB';
    otherwise
        error('Lithography:PreviewScale','Unknown preview scale.');
end
view=struct('values',values,'limits',limits,'ticks',ticks,'label',label,'note',note);
end

function reference=sharedReference(yz)
if isfield(yz,'xyzReferencePeak')
    reference=yz.xyzReferencePeak;
elseif strcmp(yz.normalizationMode,'XYZ')
    reference=yz.normalizationPeak;
else
    error('Lithography:PreviewScale','A shared XYZ reference is required.');
end
reference=max(reference,realmin);
end
