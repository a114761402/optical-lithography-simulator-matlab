function lithography_preview_mesh_test()
% Physical-coordinate preview and observation-plane invariance, not UI cosmetics.
p=lithography_default_params();p.sourceType='Point';p.pointSourceV=.6;
p=lithography_check_settings(p);r=lithography_run_physics(p);
yz=lithography_wave_yz_preview(p,r);g=r.geometry;
assert(all(diff(yz.zMm)>0));
assert(max(diff(yz.zMm))<=g.zSliceMax/120*(1+1e-10));
for plane=[g.zCondenser g.zField g.zPupil g.zImage]
    [distance,j]=min(abs(yz.zMm-plane));assert(distance<1e-10);
    assert(yz.zMm(j)-yz.zMm(j-1)<1.01e-7 && yz.zMm(j+1)-yz.zMm(j)<1.01e-7,...
        'Missing one-sided samples at a thin element or focus.');
end
assert(isequal(size(yz.yPhysicalMm),size(yz.rawIntensity)));
assert(all(diff(yz.yPhysicalMm,1,1)>0,'all'));
[~,iy]=max(yz.rawIntensity(:,1));
expected=p.pointSourceV*p.condenserFocalMm*p.projNA/p.reduction;
assert(abs(yz.yPhysicalMm(iy,1)-expected)<1e-6,'Off-axis source moved to normalized y.');
fig=figure('Visible','off');cleanup=onCleanup(@()delete(fig));ax=axes(fig);
lithography_render_yz_panel(ax,yz);
s=findobj(ax,'Tag','WavePreview');
assert(isequal(get(s,'YData'),yz.yPhysicalMm),'Preview reverted to per-column normalized coordinates.');
assert(strcmp(get(s,'FaceColor'),'interp'),'A slice is extruded over a finite z interval.');
assert(strcmp(get(get(ax,'YLabel'),'String'),'y (mm)'));
% Changing only the chosen image/observation plane cannot alter the field at z.
z=g.zImageNominal+.01;
a=lithography_compute_xy_slice(p,r,z);
% Script-only probe beyond the GUI image-ROI guard; the queried z is already
% supported by the full-path slice evaluator in both configurations.
shifted=p;shifted.defocusUm=10;shifted.enforceLimits=false;
rr=lithography_run_physics(shifted);b=lithography_compute_xy_slice(shifted,rr,z);
assert(isequal(a.axisM,b.axisM) && isequal(a.rawIntensity,b.rawIntensity),...
    'The image-plane marker changes the propagated field or grid.');
centre=lithography_compute_xy_slice(p,r,g.zImageNominal);
for delta=[-1e-6 1e-6]
    near=lithography_compute_xy_slice(p,r,g.zImageNominal+delta);
    assert(isequal(near.axisM,centre.axisM));
    err=norm(near.rawIntensity(:)-centre.rawIntensity(:))/max(norm(centre.rawIntensity(:)),realmin);
    assert(err<.001,'Large image-plane discontinuity: %.4g',err);
end
% Corner geometries remain bounded and refine the actual and nominal image planes.
for reduction=[1 4 20]
    for defocus=[-10 0 10]
        t=p;t.reduction=reduction;t.defocusUm=defocus;
        gg=lithography_projection_geometry(t,struct('imageDistanceMm',t.projectionFocalMm/reduction,'absMagnification',1/reduction));
        zz=lithography_preview_z_grid(t,gg);
        assert(numel(zz)<350 && all(isfinite(zz)) && zz(1)==0 && zz(end)==gg.zSliceMax);
        assert(any(abs(zz-gg.zImageNominal)<1e-10) && any(abs(zz-gg.zImage)<1e-10));
    end
end
dark=yz;dark.rawIntensity(:)=0;
d=lithography_preview_display(dark,'Local / z');assert(all(d.values(:)==0));
fprintf('Physical preview: %d planes, mm coordinates, off-axis source, one-sided elements, image-plane invariance/continuity, 9 geometry corners and dark input passed.\n',numel(yz.zMm));
end
