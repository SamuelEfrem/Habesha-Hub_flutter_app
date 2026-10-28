// Stops game music and sounds when the game is left: tracks every AudioContext and <audio> the page makes,
// pauses them when the page is hidden or closed, and gives the app window.habeshaPause() to call on exit.
// Load it before the game's own scripts.
(function(){
  const ctxs=[],Orig=window.AudioContext||window.webkitAudioContext;
  if(Orig){const Track=function(...a){const c=new Orig(...a);ctxs.push(c);return c};Track.prototype=Orig.prototype;
    window.AudioContext=Track;if(window.webkitAudioContext)window.webkitAudioContext=Track}
  const OrigAudio=window.Audio,media=new Set();
  if(OrigAudio){const A=function(src){const a=new OrigAudio(src);media.add(a);return a};A.prototype=OrigAudio.prototype;window.Audio=A}
  function pauseAll(){ctxs.forEach(c=>{try{if(c.state==="running")c.suspend()}catch(e){}});
    media.forEach(a=>{try{a.pause()}catch(e){}});document.querySelectorAll("audio,video").forEach(m=>{try{m.pause()}catch(e){}});
    try{speechSynthesis.cancel()}catch(e){}}
  function resumeAll(){ctxs.forEach(c=>{try{if(c.state==="suspended")c.resume()}catch(e){}})}
  window.habeshaPause=pauseAll;window.habeshaResume=resumeAll;
  document.addEventListener("visibilitychange",()=>{document.hidden?pauseAll():resumeAll()});
  addEventListener("pagehide",pauseAll);
})();
