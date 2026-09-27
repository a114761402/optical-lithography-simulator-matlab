// Fine uses the same spatial and source sampling in XY, XZ and YZ.
export const QUALITY={preview:{gridSize:128,sourceBins:7},standard:{gridSize:256,sourceBins:13},fine:{gridSize:512,sourceBins:25}};
export const waveQuality=grid=>Object.values(QUALITY).find(q=>q.gridSize===Number(grid))||QUALITY.fine;
// Moving an observation screen is not a change to the optical system.
export const waveParameters=(params,grid)=>({...params,defocusUm:0,...waveQuality(grid)});
