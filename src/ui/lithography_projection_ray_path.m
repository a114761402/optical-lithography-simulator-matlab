function path = lithography_projection_ray_path(params, geom, yField, yPupil)
% Build a step-by-step projection-ray sketch:
% field plane -> lens 1 -> pupil plane -> lens 2 -> image plane -> post-image.

path = struct();
path.zNodes = [geom.zField geom.zProjection1 geom.zPupil geom.zProjection2 geom.zImage geom.zAfterImage];
path.yField = yField;
path.yPupil = yPupil;
path.yImage = geom.projection.magnification * yField;

sFieldToLens1 = max(geom.zProjection1 - geom.zField, eps);
sLens1ToPupil = max(geom.zPupil - geom.zProjection1, eps);
sPupilToLens2 = max(geom.zProjection2 - geom.zPupil, eps);
sLens2ToImage = max(geom.zImage - geom.zProjection2, eps);
postImageDistance = max(geom.zAfterImage - geom.zImage, eps);

lensHalf = 0.94 * geom.projectionHalf;

path.yLens1 = lensNodeHeight(yField, yPupil, sFieldToLens1, sLens1ToPupil, max(geom.relayFocal1Mm, eps), lensHalf);
path.yLens2 = lensNodeHeight(path.yPupil, path.yImage, sPupilToLens2, sLens2ToImage, max(geom.relayFocal2Mm, eps), lensHalf);
postImageSlope = (path.yImage - path.yLens2) / sLens2ToImage;
path.yAfterImage = path.yImage + postImageSlope * postImageDistance;
path.yNodes = [path.yField path.yLens1 path.yPupil path.yLens2 path.yImage path.yAfterImage];
path.preZ = path.zNodes(1:3);
path.preY = path.yNodes(1:3);
path.postZ = path.zNodes(3:end);
path.postY = path.yNodes(3:end);
end

function yLens = lensNodeHeight(yIn, yOut, distanceIn, distanceOut, focalLengthMm, lensHalf)
denominator = (1 / distanceOut) + (1 / distanceIn) - (1 / focalLengthMm);

if abs(denominator) < 1e-9
    yLens = straightLineHeight(yIn, yOut, distanceIn, distanceOut);
else
    yLens = (yOut / distanceOut + yIn / distanceIn) / denominator;
end

if ~isfinite(yLens)
    yLens = straightLineHeight(yIn, yOut, distanceIn, distanceOut);
end

yLens = min(max(yLens, -lensHalf), lensHalf);
end

function yValue = straightLineHeight(yLeft, yRight, distanceLeft, distanceRight)
alpha = distanceLeft / max(distanceLeft + distanceRight, eps);
yValue = yLeft + alpha * (yRight - yLeft);
end
