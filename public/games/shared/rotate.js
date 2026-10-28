// "Turn your phone sideways" card for the 3D games: phones in portrait only, hidden once the phone
// is turned or the player taps OK (then it stays away for this visit).
(function(){
  if(!matchMedia("(pointer:coarse)").matches)return;
  const TXT={ti:["ንዝበለጸ ተሞክሮ ስልክኻ ብጎኑ ግበሮ","ሕራይ"],am:["ለተሻለ ተሞክሮ ስልክዎን በጎን ያዙሩት","እሺ"],
    en:["Turn your phone sideways for the best experience","OK"],no:["Snu telefonen på siden for best opplevelse","OK"]};
  const css=`#rotHint{position:fixed;inset:0;z-index:99;display:grid;place-items:center;background:rgba(5,9,14,.72);padding:24px}
#rotHint div{background:#111a25;border:2px solid #f7c948;border-radius:20px;padding:22px 20px;max-width:320px;text-align:center;color:#f3f6fa;font:700 1.05rem "Noto Sans Ethiopic",system-ui,sans-serif}
#rotHint i{display:block;font-style:normal;font-size:3.4rem;animation:rotP 1.8s ease-in-out infinite}
#rotHint button{margin-top:14px;font:800 1rem system-ui,sans-serif;background:#f7c948;color:#2a1d00;border:0;border-radius:12px;padding:10px 26px}
@keyframes rotP{0%,20%{transform:rotate(0)}50%,80%{transform:rotate(-90deg)}100%{transform:rotate(0)}}`;
  const st=document.createElement("style");st.textContent=css;document.head.appendChild(st);
  const el=document.createElement("div");el.id="rotHint";el.hidden=true;document.body.appendChild(el);
  const portrait=matchMedia("(orientation:portrait)");let off=false;
  function lang(){const q=new URLSearchParams(location.search).get("lang");const l=(document.documentElement.lang||q||"en").slice(0,2);return TXT[l]?l:"en"}
  function update(){if(off||!portrait.matches){el.hidden=true;return}
    const t=TXT[lang()];el.innerHTML=`<div><i>📱</i>${t[0]}<br><button type="button">${t[1]}</button></div>`;
    el.querySelector("button").onclick=()=>{off=true;el.hidden=true};el.hidden=false}
  portrait.addEventListener?portrait.addEventListener("change",update):portrait.addListener(update);
  setTimeout(update,400);
})();
