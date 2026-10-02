import test from 'node:test';
import assert from 'node:assert/strict';
import {PositionHistory,positionSnapshot} from '../dist/position-history.js';
import {createPlanes,appendPositionGroup,setObservation} from '../dist/observation-state.js';
import {restorePositions} from '../dist/reference-positions.js';
import {defaults,geometry} from '../dist/optics.js';

test('Undo and redo follow a position move, add, and reset without reusing old identities',()=>{
  let planes=createPlanes(),activeId='D',lastPosition=450;
  const history=new PositionHistory(positionSnapshot(planes,activeId,lastPosition));
  const record=change=>{
    const before=positionSnapshot(planes,activeId,lastPosition);
    change();
    history.record(before,positionSnapshot(planes,activeId,lastPosition));
  };
  record(()=>setObservation(planes[3],geometry(defaults),449.123));
  record(()=>{appendPositionGroup(planes,2);activeId='E';});
  record(()=>{planes=restorePositions();activeId=null;});
  assert.equal(history.canUndo,true);
  let state=history.undo();assert.deepEqual(state.planes.map(p=>p.id),['A','B','C','D','E','F']);
  assert.equal(state.planes[3].base,449.123);
  planes=restorePositions(state.planes);
  assert.notEqual(planes[3].instance,state.planes[3].instance);
  state=history.undo();assert.deepEqual(state.planes.map(p=>p.id),['A','B','C','D']);
  assert.equal(state.planes[3].base,449.123);
  state=history.undo();assert.equal(state.planes[3].plane,'image');
  assert.equal(history.canUndo,false);
  assert.equal(history.redo().planes[3].base,449.123);
  assert.equal(history.redo().planes.length,6);
  assert.equal(history.redo().planes.length,4);
  assert.equal(history.canRedo,false);
});

test('New position edits clear redo; selection alone does not make a step',()=>{
  const panels=createPlanes(),initial=positionSnapshot(panels,'D',450),history=new PositionHistory(initial);
  assert.equal(history.record(initial,positionSnapshot(panels,'A',450)),false);
  const before=positionSnapshot(panels,'D',450);
  panels[3].base=449;panels[3].plane='custom';
  history.record(before,positionSnapshot(panels,'D',450));
  history.undo();assert.equal(history.canRedo,true);
  panels[3].base=448;
  history.record(before,positionSnapshot(panels,'D',450));
  assert.equal(history.canRedo,false);
  assert.equal(history.undo().planes[3].base,0);
});
