// Keep only position edits in this history. Calculation results are shared,
// immutable references; restoring a position gets a fresh calculation identity.
export const positionSnapshot=(planes,activeId,lastPosition)=>({
  planes:planes.map(panel=>({...panel})),activeId,lastPosition
});

const samePositions=(a,b)=>a.planes.length===b.planes.length&&a.planes.every((panel,i)=>{
  const other=b.planes[i];
  return panel.id===other.id&&panel.plane===other.plane&&panel.base===other.base&&panel.offset===other.offset;
});

export class PositionHistory{
  constructor(initial,limit=40){this.states=[initial];this.index=0;this.limit=limit;}
  get canUndo(){return this.index>0;}
  get canRedo(){return this.index<this.states.length-1;}
  clear(state){this.states=[state];this.index=0;}
  record(before,after){
    if(samePositions(before,after))return false;
    this.states[this.index]=before;
    this.states.length=this.index+1;
    this.states.push(after);
    if(this.states.length>this.limit+1)this.states.shift();
    this.index=this.states.length-1;
    return true;
  }
  undo(){return this.canUndo?this.states[--this.index]:null;}
  redo(){return this.canRedo?this.states[++this.index]:null;}
}
