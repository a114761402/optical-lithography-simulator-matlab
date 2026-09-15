function lithography_xy_display_test()
% Reproduce the faint relay slice and verify display-only controls/corners.
p=lithography_reference_params();r=lithography_run_physics(p);
s=lithography_compute_xy_slice(p,r,168.110669);
original=s.rawIntensity;
fprintf('z=%.6f mm: raw peak %.9g, XYZ reference %.9g, ratio %.9g (%.2f dB)\n',...
    s.zMm,max(original(:)),s.xyzReferencePeak,max(original(:))/s.xyzReferencePeak,...
    10*log10(max(original(:))/s.xyzReferencePeak));
assert(max(original(:))>0 && max(original(:))/s.xyzReferencePeak<1e-6);
modes={'Local linear','Local log (dB)','XYZ linear','XYZ log (dB)'};
f=figure('Visible','off','Color','w','Position',[30 30 760 680]);
if isprop(f,'Theme'),f.Theme='light';end
cleanup=onCleanup(@() delete(f));
lithography_render_xy_slice(f,s);
popup=findall(f,'Tag','XYScale');im=findall(f,'Type','image');
for k=1:numel(modes)
    set(popup,'Value',k);cb=get(popup,'Callback');cb(popup,[]);
    v=lithography_xy_display(s,modes{k});
    assert(isequal(get(im,'CData'),v.values));
    saved=getappdata(f,'xySliceData');assert(isequal(saved.rawIntensity,original));
    assert(numel(findall(f,'Type','colorbar'))==1);
    assert(all(isfinite(v.values(:))));
    if k==1
        assert(max(v.values(:))==1 && min(v.values(:))<.1,'Local shape is hidden.');
        exportgraphics(f,fullfile(tempdir,'lithography_xy_local.png'),'Resolution',120);
    elseif k==4
        assert(max(v.values(:))>-90 && max(v.values(:))<-60);
        exportgraphics(f,fullfile(tempdir,'lithography_xy_xyzlog.png'),'Resolution',120);
    end
end
% Exact zero must remain dark; weak/subnormal light must not be called zero.
cases={zeros(4),ones(4)*1e-310,[0 1e-300;1e-310 1e-305],ones(4),[0 20;1 2]};
for n=1:numel(cases)
    t=s;t.rawIntensity=cases{n};t.xyzReferencePeak=1;
    for k=1:numel(modes)
        v=lithography_xy_display(t,modes{k});
        assert(all(isfinite(v.values(:))) && all(isfinite(v.limits)));
        if n==1
            assert(contains(v.note,'DARK'));
            assert(all(v.values(:)==v.limits(1)));
        elseif k==1,assert(max(v.values(:))==1);
        end
        if n==5 && k>=3
            assert(contains(v.note,'saturate'),'Shared-scale saturation was not labelled.');
            assert(max(v.values(:))>v.limits(2),'Stored display values were clipped.');
        end
    end
end
% Other mask shapes/planes use precisely the same data-preserving transform.
q=p;q.sourceType='Point';
for shape={'Circular Aperture','Annular Aperture','Cross','2D Grating'}
    q.maskType=shape{1};rr=lithography_run_physics(q);
    for z=[0 rr.geometry.zField+.001 168.110669 rr.geometry.zImage]
        t=lithography_compute_xy_slice(q,rr,z);before=t.rawIntensity;
        for k=1:numel(modes)
            v=lithography_xy_display(t,modes{k});assert(all(isfinite(v.values(:))));
            assert(isequal(before,t.rawIntensity));
        end
    end
end
fprintf('XY display: reproduced faint slice; 4 controls, 20 numerical corners, 16 mask/plane cases passed. Raw data unchanged.\n');
end
