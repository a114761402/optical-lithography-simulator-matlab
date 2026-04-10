function geom = lithography_projection_geometry(params, projectionRelay)
geom = struct();
geom.projection = projectionRelay;

geom.zSourcePlane = 0;
geom.zCondenser = params.sourceToCondenserMm;
geom.zField = geom.zCondenser + params.condenserFocalMm;
geom.zPupil = geom.zField + params.fieldToPupilMm;
geom.zImage = geom.zPupil + projectionRelay.imageDistanceMm;

geom.zProjection1 = geom.zField + 0.5 * (geom.zPupil - geom.zField);
geom.zProjection2 = geom.zPupil + 0.5 * (geom.zImage - geom.zPupil);
geom.projectionLensSeparation = geom.zProjection2 - geom.zProjection1;

geom.fieldToLens1Mm = geom.zProjection1 - geom.zField;
geom.lens1ToPupilMm = geom.zPupil - geom.zProjection1;
geom.pupilToLens2Mm = geom.zProjection2 - geom.zPupil;
geom.lens2ToImageMm = geom.zImage - geom.zProjection2;
geom.relayFocal1Mm = max(0.5 * (geom.zPupil - geom.zField), eps);
geom.relayFocal2Mm = max(0.5 * (geom.zImage - geom.zPupil), eps);

geom.totalLength = geom.zImage;
postImageMargin = max(24, 0.14 * geom.totalLength);
geom.zAfterImage = geom.zImage + 0.72 * postImageMargin;
geom.zSliceMax = geom.zImage + max(20, 0.30 * projectionRelay.imageDistanceMm);
geom.xMin = min(-18, -0.08 * geom.totalLength);
geom.xMax = geom.zImage + postImageMargin;

geom.maskHalf = clampValue(0.12 + 0.90 * (params.maskSizeUm / params.fieldSizeUm), 0.18, 0.82);
geom.imageHalf = clampValue(geom.maskHalf * geom.projection.absMagnification, 0.08, 0.55);
geom.condenserHalf = 1.00;
geom.projectionHalf = clampValue(max([0.74, geom.maskHalf + 0.08]), 0.74, 1.00);
end

function value = clampValue(value, lowValue, highValue)
value = min(max(value, lowValue), highValue);
end
