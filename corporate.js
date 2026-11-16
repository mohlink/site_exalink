/* EXALINK corporate bilingual pages: English default, French available. */
(()=>{"use strict";
const page=document.body.dataset.page;
const en={
home:"Home",services:"Services",about:"About Us",contact:"Contact",navApproach:"Our approach",menuContact:"Contact",cta:"Discuss your project ↗",
footer:"© 2026 EXALINK · Website preview · Technology solutions for business",
aboutKicker:"ABOUT EXALINK",aboutTitle:"Technology, integration and practical expertise.",aboutLead:"EXALINK supports businesses and organizations with connected technologies: IT infrastructure, professional communications, industrial networks and smart systems integration.",aboutPhoto:"CONNECTED BUSINESS TECHNOLOGY",
aboutEyebrow:"WHO WE ARE",aboutSubTitle:"Technology built around real operational needs",aboutParagraph1:"EXALINK is a Québec-based technology services company working across IT, networking, telecommunications and connected systems. We focus on understanding business requirements before proposing technical solutions.",
aboutParagraph2:"Our interests also extend to engineering-oriented topics such as industrial connectivity, mobile robotics, autonomous navigation and mapping. These areas inform our approach to innovation without replacing our core business services.",
aboutValue1Title:"Practical solutions",aboutValue1Body:"Solutions that fit existing environments, operational needs and budgets.",
aboutValue2Title:"Connected expertise",aboutValue2Body:"A cross-disciplinary view of networks, communications and systems integration.",
aboutValue3Title:"Technical collaboration",aboutValue3Body:"Clear technical discussion and a project-by-project approach.",
areasKicker:"OUR AREAS OF ACTIVITY",areasTitle:"Connecting the technologies behind your operations",areasLead:"Explore our main fields of service and technical expertise.",
area1:"IT & Networking",area1Text:"Business networks, infrastructure and technical support.",
area2:"Telecommunications",area2Text:"VoIP, wired and wireless, LTE/5G, industrial Wi-Fi and mining communications.",
area3:"Smart Systems & Integration",area3Text:"Connected devices, monitoring, IoT and automation.",
aboutActionTitle:"Let's discuss your technology challenges.",aboutActionBody:"Tell us about your project and the environment in which it needs to work.",aboutActionButton:"Contact EXALINK ↗",
contactKicker:"CONTACT EXALINK",contactTitle:"Let's discuss your next project.",contactLead:"Tell us about your needs in IT, telecommunications, industrial connectivity or systems integration. We'll help clarify the next steps.",
contactVisual:"A CONNECTED APPROACH",
contactAsideKicker:"LET'S CONNECT",contactAsideTitle:"Start with your business needs",contactAsideBody:"A few details about your organization and project are enough to start a meaningful technical discussion.",
contactPoint1:"Business & industrial projects",contactPoint1Text:"Solutions tailored to professional environments.",
contactPoint2:"IT, telecom & integration",contactPoint2Text:"From wired and wireless networks to connected systems.",
contactPoint3:"Contact information",contactPoint3Text:"The official email and phone number will be confirmed before launch.",
contactFormTitle:"Tell us about your project",contactFormIntro:"Complete the form to prepare a message you can copy into your email application.",
fieldName:"Your name *",fieldCompany:"Company / organization",fieldEmail:"Email address *",fieldPhone:"Phone (optional)",fieldSubject:"Project area *",fieldMessage:"How can we help? *",subjectPlaceholder:"Choose a service",subjectIt:"IT & Networking",subjectTele:"Telecommunications / LTE / 5G / Wi-Fi",subjectSystems:"Smart Systems / IoT / Automation",subjectOther:"Other business technology project",namePlaceholder:"Full name",companyPlaceholder:"Company name",emailPlaceholder:"you@company.com",phonePlaceholder:"Phone number",messagePlaceholder:"Briefly describe your needs, location, current environment and objectives.",
formSubmit:"Prepare message",formNote:"Preview mode: this form does not send or store your message. It generates text that you can copy. An actual contact form will be configured once the receiving address and hosting are confirmed.",
formResultTitle:"Your message is ready",formResultIntro:"Nothing has been sent. Copy this draft and paste it into your email application.",
formCopy:"Copy message",copyDone:"Text copied. No message has been sent.",copyFail:"Select and copy the message manually. No message has been sent.",
draftSubject:"EXALINK – Business technology inquiry",draftName:"Name",draftCompany:"Company",draftEmail:"Email",draftPhone:"Phone",draftArea:"Project area",draftMessage:"Project details",formError:"Please complete the required fields correctly.",noJs:"JavaScript is required for this draft form. No data is sent from this page."
};
const fr={
home:"Accueil",services:"Services",about:"À propos",contact:"Contact",navApproach:"Notre approche",menuContact:"Contact",cta:"Parlons de votre projet ↗",
footer:"© 2026 EXALINK · Site de démonstration · Solutions technologiques pour entreprises",
aboutKicker:"À PROPOS D’EXALINK",aboutTitle:"Technologies, intégration et expertise technique.",aboutLead:"EXALINK accompagne les entreprises et les organisations dans leurs projets technologiques : infrastructures TI, communications professionnelles, réseaux industriels et intégration de systèmes intelligents.",aboutPhoto:"TECHNOLOGIES CONNECTÉES POUR ENTREPRISES",
aboutEyebrow:"QUI NOUS SOMMES",aboutSubTitle:"Des technologies adaptées aux besoins opérationnels réels",aboutParagraph1:"EXALINK est une entreprise québécoise de services technologiques active en informatique, réseaux, télécommunications et systèmes connectés. Nous privilégions la compréhension des besoins d’affaires avant de proposer une solution technique.",
aboutParagraph2:"Nos champs d’intérêt s’étendent également à l’ingénierie, à la connectivité industrielle, à la robotique mobile, à la navigation autonome et à la cartographie. Ces domaines nourrissent notre démarche d’innovation, sans remplacer nos principaux services.",
aboutValue1Title:"Des solutions concrètes",aboutValue1Body:"Des technologies adaptées aux installations existantes, aux besoins et aux budgets.",
aboutValue2Title:"Des expertises connectées",aboutValue2Body:"Une approche transversale des réseaux, des communications et de l’intégration.",
aboutValue3Title:"Une collaboration technique",aboutValue3Body:"Des échanges clairs et une démarche adaptée à chaque projet.",
areasKicker:"NOS DOMAINES D’ACTIVITÉ",areasTitle:"Connecter les technologies qui soutiennent vos opérations",areasLead:"Découvrez nos principaux services et domaines d’expertise.",
area1:"Informatique et réseaux",area1Text:"Réseaux d’entreprise, infrastructures et soutien technique.",
area2:"Télécommunications",area2Text:"VoIP, réseaux filaires et sans fil, LTE/5G, Wi-Fi industriel et communications minières.",
area3:"Systèmes intelligents et intégration",area3Text:"Objets connectés, supervision, IoT et automatisation.",
aboutActionTitle:"Parlons de vos défis technologiques.",aboutActionBody:"Présentez-nous votre projet et l’environnement dans lequel la solution doit fonctionner.",aboutActionButton:"Contacter EXALINK ↗",
contactKicker:"CONTACTER EXALINK",contactTitle:"Parlons de votre prochain projet.",contactLead:"Décrivez vos besoins en informatique, télécommunications, connectivité industrielle ou intégration de systèmes. Nous pourrons explorer les prochaines étapes.",
contactVisual:"UNE APPROCHE CONNECTÉE",
contactAsideKicker:"ENTRONS EN CONTACT",contactAsideTitle:"Commençons par vos besoins",contactAsideBody:"Quelques informations sur votre organisation et votre projet suffisent pour entamer un échange technique.",
contactPoint1:"Projets professionnels et industriels",contactPoint1Text:"Des solutions adaptées aux environnements d’entreprise.",
contactPoint2:"TI, télécommunications et intégration",contactPoint2Text:"Des réseaux filaires et sans fil aux systèmes connectés.",
contactPoint3:"Coordonnées",contactPoint3Text:"L’adresse courriel officielle et le téléphone seront confirmés avant le lancement.",
contactFormTitle:"Décrivez votre projet",contactFormIntro:"Remplissez le formulaire pour préparer un message à copier dans votre application courriel.",
fieldName:"Votre nom *",fieldCompany:"Entreprise / organisation",fieldEmail:"Adresse courriel *",fieldPhone:"Téléphone (facultatif)",fieldSubject:"Domaine du projet *",fieldMessage:"Comment pouvons-nous vous aider ? *",subjectPlaceholder:"Choisir un service",subjectIt:"Informatique et réseaux",subjectTele:"Télécommunications / LTE / 5G / Wi-Fi",subjectSystems:"Systèmes intelligents / IoT / automatisation",subjectOther:"Autre projet technologique",namePlaceholder:"Nom complet",companyPlaceholder:"Nom de l’entreprise",emailPlaceholder:"vous@entreprise.com",phonePlaceholder:"Numéro de téléphone",messagePlaceholder:"Décrivez brièvement vos besoins, votre localisation, l’environnement actuel et vos objectifs.",
formSubmit:"Préparer le message",formNote:"Mode démonstration : ce formulaire n’envoie ni n’enregistre votre message. Il prépare un texte que vous pourrez copier. Un formulaire d’envoi sera configuré après validation de l’adresse de réception et de l’hébergement.",
formResultTitle:"Votre message est prêt",formResultIntro:"Aucun message n’a été envoyé. Copiez ce brouillon dans votre application courriel.",
formCopy:"Copier le message",copyDone:"Texte copié. Aucun message n’a été envoyé.",copyFail:"Sélectionnez et copiez le texte manuellement. Aucun message n’a été envoyé.",
draftSubject:"EXALINK – Demande de renseignements professionnels",draftName:"Nom",draftCompany:"Entreprise",draftEmail:"Courriel",draftPhone:"Téléphone",draftArea:"Domaine du projet",draftMessage:"Description du projet",formError:"Veuillez remplir correctement les champs obligatoires.",noJs:"JavaScript est nécessaire pour préparer le message. Aucune donnée n’est envoyée depuis cette page."
};
function langPref(){try{return localStorage.getItem("exalink-language")==="fr"?"fr":"en"}catch(e){return "en"}}
let active="en";
const copy=()=>active==="fr"?fr:en;
function display(lang){
 active=lang==="fr"?"fr":"en";const dict=copy();document.documentElement.lang=active;
 document.querySelectorAll("[data-i18n]").forEach(el=>{const key=el.dataset.i18n;if(typeof dict[key]==="string")el.textContent=dict[key]});
 document.querySelectorAll("[data-placeholder]").forEach(el=>{const key=el.dataset.placeholder;if(typeof dict[key]==="string")el.setAttribute("placeholder",dict[key])});
 document.getElementById("lang-en").setAttribute("aria-pressed",String(active==="en"));
 document.getElementById("lang-fr").setAttribute("aria-pressed",String(active==="fr"));
 document.getElementById("corporate-nav").setAttribute("aria-label",active==="fr"?"Navigation principale":"Primary navigation");
 document.title="EXALINK | "+dict[page==="about"?"about":"contact"];
 document.querySelector('meta[name="description"]').setAttribute("content",dict[page==="about"?"aboutLead":"contactLead"]);
 if(page==="contact"){
   document.getElementById("draft-result").hidden=true;
   document.getElementById("copy-status").textContent="";
 }
 try{localStorage.setItem("exalink-language",active)}catch(e){}
}
document.getElementById("lang-en").addEventListener("click",()=>display("en"));
document.getElementById("lang-fr").addEventListener("click",()=>display("fr"));
if(page==="contact"){
 const form=document.getElementById("contact-form");
 const result=document.getElementById("draft-result");
 const output=document.getElementById("draft-text");
 form.addEventListener("submit",event=>{
   event.preventDefault();
   if(!form.reportValidity())return;
   const t=copy(),val=id=>document.getElementById(id).value.trim();
   const subject=form.querySelector("#field-subject").selectedOptions[0].textContent;
   const text=[t.draftSubject,"",t.draftName+": "+val("field-name"),t.draftCompany+": "+val("field-company"),t.draftEmail+": "+val("field-email"),t.draftPhone+": "+val("field-phone"),t.draftArea+": "+subject,"",t.draftMessage+":","",val("field-message")].join("\n");
   output.textContent=text;result.hidden=false;
   result.scrollIntoView({behavior:window.matchMedia("(prefers-reduced-motion: reduce)").matches?"auto":"smooth",block:"nearest"});
 });
 document.getElementById("copy-draft").addEventListener("click",async()=>{
   const text=output.textContent;const status=document.getElementById("copy-status");
   try{
     if(navigator.clipboard&&window.isSecureContext)await navigator.clipboard.writeText(text);
     else throw Error("Clipboard API unavailable");
     status.textContent=copy().copyDone;
   }catch(e){status.textContent=copy().copyFail}
 });
}
display(langPref());
})();