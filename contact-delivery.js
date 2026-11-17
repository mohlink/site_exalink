/* EXALINK Funio contact delivery adapter
 * IMPORTANT: Explicit opt-in only: <body data-contact-mode="smtp">.
 * GitHub Pages and all preview builds remain draft-only.
 * Relies on local same-origin PHP endpoints. No SMTP credentials in browser.
 */
(()=>{"use strict";
  const form=document.getElementById("contact-form");
  if(!form)return;
  const live=document.body.dataset.contactMode==="smtp" &&
    location.protocol==="https:" && !/(^|\.)github\.io$/i.test(location.hostname);
  if(!live)return;

  const submitButton=form.querySelector('button[type="submit"]');
  const result=document.getElementById("draft-result");
  const delivery=document.getElementById("delivery-status");
  const texts={
    en:{
      title:"Send your inquiry to EXALINK",
      intro:"Submit your project details securely to info@exalink.ca.",
      note:"We use the details you provide to reply to your business inquiry. Please do not include passwords or other confidential credentials.",
      send:"Send message securely",sending:"Sending…",
      sent:"Your inquiry has been submitted successfully. Thank you for contacting EXALINK.",
      failed:"We could not confirm delivery. Please contact info@exalink.ca directly. If you already submitted, check before sending again to avoid duplicates.",
      unavailable:"Online sending is not available yet. You can email info@exalink.ca directly.",
    },
    fr:{
      title:"Envoyer votre demande à EXALINK",
      intro:"Transmettez les détails de votre projet de façon sécurisée à info@exalink.ca.",
      note:"Nous utilisons les renseignements fournis pour répondre à votre demande. Évitez d'inclure des mots de passe ou d'autres données d'accès confidentielles.",
      send:"Envoyer le message",sending:"Envoi en cours…",
      sent:"Votre demande a été transmise avec succès. Merci d'avoir contacté EXALINK.",
      failed:"Nous n'avons pas pu confirmer la réception. Vous pouvez écrire à info@exalink.ca. Si vous venez de soumettre une demande, vérifiez avant de réessayer pour éviter un doublon.",
      unavailable:"L'envoi en ligne n'est pas encore disponible. Vous pouvez écrire directement à info@exalink.ca.",
    }
  };
  const lang=()=>document.documentElement.lang==="fr"?"fr":"en";
  const t=()=>texts[lang()];
  let readyToken=null, tokenAt=0, busy=false;
  const showStatus=(message,kind)=>{
    delivery.textContent=message;
    delivery.hidden=false;
    delivery.dataset.kind=kind;
    delivery.setAttribute("role",kind==="error"?"alert":"status");
  };
  const hideStatus=()=>{
    delivery.hidden=true;
    delivery.textContent="";
    delivery.removeAttribute("data-kind");
  };
  function updateCopy(){
    const dict=t();
    form.querySelector('[data-i18n="contactFormTitle"]').textContent=dict.title;
    form.querySelector('[data-i18n="contactFormIntro"]').textContent=dict.intro;
    form.querySelector('[data-i18n="formNote"]').textContent=dict.note;
    submitButton.textContent=busy?dict.sending:dict.send;
    if(!busy)submitButton.disabled=false;
  }
  async function getToken(){
    const now=Date.now();
    if(readyToken && now-tokenAt<60*60*1000)return readyToken;
    const response=await fetch("api/csrf.php",{
      method:"GET",credentials:"same-origin",cache:"no-store",
      headers:{"Accept":"application/json"}
    });
    if(!response.ok)throw Error("Token unavailable");
    const payload=await response.json();
    if(!payload || payload.ok!==true || typeof payload.token!=="string" || payload.token.length<40){
      throw Error("Invalid token");
    }
    readyToken=payload.token;tokenAt=now;
    return readyToken;
  }
  updateCopy();
  getToken().catch(()=>{ /* No user input is transmitted during readiness check. */ });
  document.getElementById("lang-en").addEventListener("click",updateCopy);
  document.getElementById("lang-fr").addEventListener("click",updateCopy);
  form.addEventListener("input",()=>{if(delivery.dataset.kind==="error")hideStatus()});
  form.addEventListener("submit",async(event)=>{
    // This capture listener overrides the preview-only form submission handler.
    event.preventDefault();
    event.stopImmediatePropagation();
    if(busy || !form.reportValidity())return;
    hideStatus();
    result.hidden=true;
    busy=true;
    submitButton.disabled=true;
    updateCopy();
    const field=id=>document.getElementById(id).value.trim();
    try{
      const token=await getToken();
      const payload={
        token,
        name:field("field-name"),
        company:field("field-company"),
        email:field("field-email"),
        phone:field("field-phone"),
        subject:field("field-subject"),
        message:field("field-message"),
        website:""
      };
      const response=await fetch("api/contact.php",{
        method:"POST",credentials:"same-origin",
        headers:{"Content-Type":"application/json","Accept":"application/json"},
        body:JSON.stringify(payload)
      });
      const reply=await response.json().catch(()=>null);
      if(!response.ok || !reply || reply.ok!==true || reply.message!=="sent"){
        throw Error(reply&&reply.error?reply.error:"Delivery not confirmed");
      }
      readyToken=null;tokenAt=0;
      form.reset();
      showStatus(t().sent,"success");
    }catch(err){
      const offline=err&&(/Token unavailable|Invalid token/.test(err.message));
      showStatus(offline?t().unavailable:t().failed,"error");
    }finally{
      busy=false;
      submitButton.disabled=false;
      updateCopy();
    }
  },true);
})();
