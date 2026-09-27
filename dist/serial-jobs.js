// One calculation at a time. Replacing a job never lets its late messages win.
export class SerialJobs{
  constructor(onChange=()=>{}){this.waiting=[];this.current=null;this.onChange=onChange;}
  has(key){return this.current?.job.key===key||this.waiting.some(job=>job.key===key);}
  add(job){this.cancel(job.key,false);this.waiting.push(job);this.start();}
  cancel(key=null,start=true){
    const removed=this.waiting.filter(job=>key===null||job.key===key);this.waiting=this.waiting.filter(job=>!removed.includes(job));removed.forEach(job=>job.cancelled?.());
    if(this.current&&(key===null||this.current.job.key===key)){const task=this.current;this.current=null;task.stop?.();task.job.cancelled?.();}
    if(start)this.start();
  }
  start(){
    if(this.current){this.onChange();return;}
    const job=this.waiting.shift();if(!job){this.onChange();return;}
    const task={job,stop:null};this.current=task;this.onChange();
    const done=(error,value)=>{if(this.current!==task)return;this.current=null;task.stop?.();error?job.failed?.(error):job.finished?.(value);this.start();};
    try{task.stop=job.run(done);}catch(error){done(error);}
  }
}
