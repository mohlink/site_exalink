/* Motion is optional; the page stays usable without JavaScript. */
(()=>{"use strict";
  const reduce=window.matchMedia&&window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  if(reduce||!("IntersectionObserver" in window))return;
  const elements=[...document.querySelectorAll(".reveal")];
  const observer=new IntersectionObserver(entries=>{
    entries.forEach(entry=>{
      if(entry.isIntersecting){entry.target.classList.add("visible");observer.unobserve(entry.target)}
    });
  },{rootMargin:"0px 0px -25px 0px",threshold:.1});
  elements.forEach(el=>observer.observe(el));
  document.documentElement.classList.add("motion-ready");
})();