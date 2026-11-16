/* EXALINK hero carousel — progressive enhancement, bilingual and keyboard accessible */
(()=>{"use strict";
  const root=document.querySelector(".hero-media.slider");
  if(!root)return;
  const slides=[...root.querySelectorAll(".hero-slide")];
  const dots=[...root.querySelectorAll(".slider-dot")];
  const prev=root.querySelector(".slider-prev"),next=root.querySelector(".slider-next");
  const pause=root.querySelector(".slider-pause"),count=root.querySelector(".slider-count");
  const captionSmall=root.querySelector("[data-slider-eyebrow]");
  const captionTitle=root.querySelector("[data-slider-title]");
  const langControl=document.querySelectorAll(".lang button");
  const reduced=window.matchMedia&&window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const copy={
    en:{
      region:"Featured images of EXALINK activities",controls:"Slideshow controls",previous:"Previous image",next:"Next image",pause:"Pause automatic slideshow",play:"Resume automatic slideshow",view:"View image",of:"of",
      slides:[
        {eyebrow:"IT & NETWORKING",title:"Infrastructure that keeps you connected.",alt:"Professional server racks with connected network equipment"},
        {eyebrow:"TELECOMMUNICATIONS",title:"VoIP, LTE/5G and Wi-Fi for business and industry.",alt:"Professional telecommunications and wireless connectivity"},
        {eyebrow:"SMART SYSTEMS & INTEGRATION",title:"Automation made to fit your operations.",alt:"Industrial control panel with electronic modules and wiring"},
        {eyebrow:"ENGINEERING & INNOVATION",title:"Exploring tomorrow’s connected systems.",alt:"Mobile robot equipped with sensors in a laboratory"}
      ]
    },
    fr:{
      region:"Photos illustrant les activités d’EXALINK",controls:"Commandes du diaporama",previous:"Image précédente",next:"Image suivante",pause:"Suspendre le défilement automatique",play:"Reprendre le défilement automatique",view:"Afficher l’image",of:"sur",
      slides:[
        {eyebrow:"INFORMATIQUE ET RÉSEAUX",title:"Des infrastructures qui vous connectent.",alt:"Baies de serveurs et équipements réseau interconnectés"},
        {eyebrow:"TÉLÉCOMMUNICATIONS",title:"VoIP, LTE/5G et Wi-Fi pour les entreprises et les mines.",alt:"Équipements de télécommunications et de connectivité sans fil"},
        {eyebrow:"SYSTÈMES INTELLIGENTS ET INTÉGRATION",title:"Une automatisation adaptée à vos opérations.",alt:"Armoire de commande industrielle avec modules électroniques et câblage"},
        {eyebrow:"INGÉNIERIE ET INNOVATION",title:"Explorer les systèmes connectés de demain.",alt:"Robot mobile équipé de capteurs dans un laboratoire"}
      ]
    }
  };
  let position=0,timer=null,userPaused=false,isHovering=false,focusWithin=false,visible=true;
  const currentLanguage=()=>document.documentElement.lang==="fr"?"fr":"en";
  function updateCopy(){
    const t=copy[currentLanguage()];
    root.setAttribute("aria-label",t.region);
    root.querySelector(".slider-controls").setAttribute("aria-label",t.controls);
    prev.setAttribute("aria-label",t.previous);
    next.setAttribute("aria-label",t.next);
    slides.forEach((slide,i)=>{
      slide.querySelector("img").alt=t.slides[i].alt;
      dots[i].setAttribute("aria-label",t.view+" "+(i+1)+" "+t.of+" "+slides.length);
    });
    captionSmall.textContent=t.slides[position].eyebrow;
    captionTitle.textContent=t.slides[position].title;
    count.textContent=String(position+1).padStart(2,"0")+" / "+String(slides.length).padStart(2,"0");
    pause.setAttribute("aria-label",userPaused?t.play:t.pause);
    pause.setAttribute("title",userPaused?t.play:t.pause);
    pause.setAttribute("aria-pressed",String(userPaused));
    pause.querySelector(".pause-icon").hidden=userPaused;
    pause.querySelector(".play-icon").hidden=!userPaused;
  }
  function show(index){
    position=(index+slides.length)%slides.length;
    slides.forEach((slide,i)=>{
      const active=i===position;
      slide.classList.toggle("is-active",active);
      slide.setAttribute("aria-hidden",String(!active));
      dots[i].setAttribute("aria-current",String(active));
    });
    updateCopy();
  }
  function stop(){if(timer){clearInterval(timer);timer=null}}
  function canPlay(){return !reduced&&!userPaused&&!isHovering&&!focusWithin&&!document.hidden&&visible}
  function syncTimer(){stop();if(canPlay())timer=setInterval(()=>show(position+1),5500)}
  function manualStep(index){show(index);syncTimer()}
  prev.addEventListener("click",()=>manualStep(position-1));
  next.addEventListener("click",()=>manualStep(position+1));
  dots.forEach((dot,i)=>dot.addEventListener("click",()=>manualStep(i)));
  pause.addEventListener("click",()=>{userPaused=!userPaused;updateCopy();syncTimer()});
  root.addEventListener("mouseenter",()=>{isHovering=true;syncTimer()});
  root.addEventListener("mouseleave",()=>{isHovering=false;syncTimer()});
  root.addEventListener("focusin",()=>{focusWithin=true;syncTimer()});
  root.addEventListener("focusout",event=>{if(!root.contains(event.relatedTarget)){focusWithin=false;syncTimer()}});
  root.addEventListener("keydown",event=>{
    if(event.target.matches("button")&&event.key==="ArrowRight"){event.preventDefault();manualStep(position+1)}
    if(event.target.matches("button")&&event.key==="ArrowLeft"){event.preventDefault();manualStep(position-1)}
  });
  let touchX=null;
  root.addEventListener("touchstart",e=>{if(e.touches.length===1)touchX=e.touches[0].clientX},{passive:true});
  root.addEventListener("touchend",e=>{
    if(touchX===null)return;
    const delta=e.changedTouches[0].clientX-touchX;touchX=null;
    if(Math.abs(delta)>55)manualStep(position+(delta<0?1:-1));
  },{passive:true});
  document.addEventListener("visibilitychange",syncTimer);
  if("IntersectionObserver" in window){
    const obs=new IntersectionObserver(entries=>{visible=entries[0].isIntersecting;syncTimer()},{threshold:.12});
    obs.observe(root);
  }
  langControl.forEach(btn=>btn.addEventListener("click",updateCopy));
  show(0);syncTimer();
})();
