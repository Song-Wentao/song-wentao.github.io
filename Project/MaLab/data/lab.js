// data/lab.js  — single source of truth for all lab content
// Edit this file to update the entire website.

const LAB = {

  // ── Identity ──────────────────────────────────────────────
  name:       "Ma Lab",
  fullName:   "Laboratory of Cardiac Physiology",
  dept:       "College of Medicine Molecular Pharmacology & Physiology",
  university: "University of South Florida",
  email:      "yma4@usf.edu",
  phone:      "+1 (813) 974-1516",
  address:    "12901 Bruce B. Downs Blvd., MDC 2529, Tampa FL 33612 ",


  // ── About ─────────────────────────────────────────────────
  tagline: "Decoding the language of the beating heart.",
  mission: "Myocardial infarction (MI)-induced ischemic heart failure is the leading cause of morbidity and mortality in the United States. Our research goals are to reveal the cellular and molecular mechanisms whereby innate and adaptive immunity regulate cardiac repair post-myocardial infarction and to accelerate the development of immunomodulatory agents for the treatment of patients with ischemic heart failure. We use mouse myocardial infarction model to investigate how distinct innate (e.g. neutrophils, macrophages, and eosinophils) and adaptive (T and B lymphocytes) immune cells regulate cardiac wound healing response. Current projects include: 1) T lymphopenia in ischemic heart failure; 2) detrimental role of age-associated thymic involution in cardiac remodeling post-MI; and 3) innate immune memory and cardiac repair.",

  highlights: [
    { icon: "", label: "Allergy, Immunology & Infectious Disease" },
    { icon: "", label: "Cardiovascular Sciences" },
    { icon: "", label: "Cellular and Molecular Biology" }
  ],


  // ── News ──────────────────────────────────────────────────
  news: [
    {
      date: "March 2026",
      title: "NIH R01 Renewal Awarded",
      body: "We are thrilled to announce that our NIH R01 grant on ryanodine receptor regulation has been renewed for another 5 years. This funding will support our continued work on calcium spark dynamics in failing cardiomyocytes."
    },
    {
      date: "January 2026",
      title: "New Paper in Nature Cardiovascular Research",
      body: "Our work on phase-separated RyR2 clusters in arrhythmia is now published. Congratulations to Dr. Maya Patel and the whole team on this outstanding contribution."
    },
    {
      date: "November 2025",
      title: "Dr. Chen Named AHA Fellow",
      body: "We are proud to share that Dr. Wei Chen has been elected as a Fellow of the American Heart Association (FAHA) in recognition of his contributions to cardiac research."
    }
  ],

  // ── People ────────────────────────────────────────────────
  pi: {
    name:   "Dr. Yonggang Ma, PhD",
    title:  "Assistant Professor",
    photo:  "img/Ma.jpg",
    bio:    "Dr. Ma received his PhD from Peking Union Medical College and completed postdoctoral training at UT Health SA and UMMC. He joined USF in 2018 and established this lab in 2022. His current work focuses on the regulation of both innate and adaptive immune responses in ischemic heart failure.",
    email:  "yma4@usf.edu",
    scholar: "https://www.researchgate.net/profile/Yonggang-Ma-4",
    cv:     "#"
  },

  members: [
    { name: "Madison D. Cooper", role: "Predoctoral Student",   photo: "", research: "To be added", joined: 2025 },
    { name: "Daria M. Konovalova", role: "Research volunteer",   photo: "", research: "To be added", joined: 2025 },
    { name: "Dr. Shuli Huang",   role: "Postdoc", photo: "", research: "To be added", joined: 2025 }
  ],

  alumni: [
    { name: "Dr. Joe Doe",     role: "Postdoc", years: "2018–2022", current: "Assistant Professor, Duke University" },
    { name: "Dr. Joe Doe",role: "PhD",     years: "2016–2021", current: "Scientist, Genentech" },
    { name: "Joe Doe",        role: "Tech",    years: "2019–2021", current: "MD/PhD Student, Yale" }
  ],

  // ── Publications ─────────────────────────────────────────
  publications: [
    { year: 2025, 
      authors: "Madison D. Cooper and Yonggang Ma",    
      title: "Inherited burdens: the cardiac cost of parental obesity in offspring following myocardial infarction",           
      journal: "American Journal of Physiology - Heart and Circulatory Physiology ", 
      volume: "329:1, H91-93",           
      pdf: "data/publications/2025.pdf", highlight: true },
    { year: 2025, 
      authors: "Rebecca Patrick, Briana D. Pando, Clement Yang, Alexandra Aponte, Fang Wang, Tom Ewing, Yonggang Ma, Sarah Y. Yuan, Mack H. Wu",    
      title: "Focal adhesion kinase mediates microvascular leakage and endothelial barrier dysfunction in ischemia-reperfusion injury",           
      journal: "Microvascular Research", 
      volume: "159: 104791",           
      pdf: "", highlight: false  },      
    { year: 2025, 
      authors: "Madison D. Cooper and Yonggang Ma",    
      title: "Inherited burdens: the cardiac cost of parental obesity in offspring following myocardial infarction",           
      journal: "American Journal of Physiology - Heart and Circulatory Physiology ", 
      volume: "329:1, H91-J93",           
      pdf: "", highlight: false },
    { year: 2025, 
      authors: "Gabriel Araujo Grilo, Jeremias Munoz Jr., Dae Hyun Lee, Shahriare Hossain, Yonggang Ma, Vasundhara Kain, Merry L. Lindsey, and Ganesh V. Halade",    
      title: "Macro- and microinjury define the heart failure progression after permanent coronary ligation or ischemia-reperfusion in young healthy mice",           
      journal: "American Journal of Physiology - Heart and Circulatory Physiology ", 
      volume: "329:2, H521-H533",           
      pdf: "", highlight: false  },
    { year: 2024, 
      authors: "Shane DX, Konovalova DM, Rajendran H, Yuan SY, Ma Y",    
      title: "Glucocorticoids impair T lymphopoiesis after myocardial infarction",           
      journal: "American Journal of Physiology - Heart and Circulatory Physiology ", 
      volume: "H533-H544",           
      pdf: "data/publications/2024.pdf", highlight: false  },      
    { year: 2024, 
      authors: "Shane DX, Konovalova DM, Rajendran H, Yuan SY, Ma Y",    
      title: "Microbiome-Immune Interplay in Aging Brains: A Pilot Investigation from the MiaGB Cohort",           
      journal: "Alzheimer's Dement", 
      volume: "20: e090734",           
      pdf: "", highlight: false  },

    { year: 2023, 
      authors: "Ma Y, Kemp SS, Yang X, Wu MH, Yuan SY",      
      title: "Cellular mechanisms underlying the impairment of macrophage efferocytosis", 
      journal: "Immunology Letters",          
      volume: "254: 41-53",     
      pdf: "#", highlight: false },
    { year: 2022,
       authors: "Ma Y, Yang X, Villalba N, Chatterjee V, Reynolds A, Spence S, Wu MH, Yuan SY",
       title: "Circulating lymphocyte trafficking to the bone marrow contributes to lymphopenia in myocardial infarction",
       journal: "BAmerican journal of physiology. Heart and circulatory physiology.",
       volume: "H622-H635", 
       pdf: "#", highlight: false },
    { year: 2021, authors: "Ma Y, Yang X, Chatterjee V, Wu MH, Yuan SY",
      title: "The gut-lung axis in systemic inflammation: role of mesenteric lymph as conduit",
      journal: "American journal of respiratory cell and molecular biology",
      volume: "64(1) : 19-28",
      pdf: "#", highlight: false  },
    { year: 2021,
      authors: "Ma Y",
      title: "Role of neutrophils in cardiac injury and repair following myocardial infarction",
      journal: "Cells",
      volume: "10(7) : 1676",
      pdf: "#", highlight: false },
    { year: 2020, 
      authors: "Ma Y, Zabell T, Creasy A, Yang X, Chatterjee V, Villalba N, Kistler EB, Wu MH, Yuan SY",
      title: "Gut ischemia reperfusion injury induces lung inflammation via mesenteric lymph-mediated neutrophil activation",
      journal: "Frontiers in immunology.",
      volume: "11: 586685",
      pdf: "#", highlight: false },
    { year: 2019,
      authors: "Ma Y, Yang X, Chatterjee V, Meegan JE, Beard RS, Yuan SY",
      title: "SRole of neutrophil extracellular traps and vesicles in regulating vascular endothelial permeability",
      journal: "Frontiers in Immunology",
      volume: "10: 1037",
      pdf: "#", highlight: false },
    { year: 2021,
      authors: "Ma Y, Mouton AJ, Lindsey ML",
      title: "Cardiac macrophage biology in the steady-state heart, the aging heart, and following myocardial infarction",
      journal: "Translational Research",
      volume: "191: 15-28",
      pdf: "#", highlight: false }
  ],

  // ── Projects ─────────────────────────────────────────────
  projects: [
    {
      status: "Active", funding: "National Institutes of Health",
      title: "T Lymphopenia in Ischemic Heart Failure",
      summary: "The ryanodine receptor (RyR2) is the primary calcium release channel of the sarcoplasmic reticulum. Aberrant RyR2 activity underlies multiple forms of inherited and acquired arrhythmia, including CPVT and atrial fibrillation. We investigate how post-translational modifications, accessory proteins, and local lipid environments modulate RyR2 gating.",
      approaches: ["Planar lipid bilayer electrophysiology", "Single-molecule FRET imaging", "CRISPR-Cas9 knock-in mouse models", "Cryo-EM structural analysis (collaboration)"]
    },
    {
      status: "Active", funding: "AHA Scientist Development Grant",
      title: "SERCA2a & Calcium Reuptake",
      summary: "Impaired calcium reuptake by SERCA2a is a hallmark of heart failure. We study the regulatory axis of phospholamban, sarcolipin, and DWORF to understand how these micropeptides compete for SERCA2a binding and control pump activity. Our goal is to identify strategies for re-activating SERCA2a in the failing heart.",
      approaches: ["Fluorescence lifetime imaging (FLIM)", "Bioluminescence resonance energy transfer (BRET)", "Adeno-associated viral gene delivery", "Förster theory modeling"]
    },
    {
      status: "Finished", funding: "Pilot Grant, UMS Cardiovascular Center",
      title: "Cardiac Optogenetics",
      summary: "We are developing optogenetic tools to achieve millisecond-precision optical control of cardiac pacemaking and conduction. Using channelrhodopsin variants expressed in specific conduction system cell types, we aim to create all-optical platforms for studying and correcting rhythm disorders without pharmacological side effects.",
      approaches: ["Adeno-associated virus serotype 9 delivery", "Whole-heart optical mapping", "Langendorff perfusion", "Custom LED illumination hardware"]
    }
  ],

  // ── Opportunities ────────────────────────────────────────
  oppIntro: "We are always looking for talented and motivated individuals to join our team. We are committed to fostering a diverse, equitable, and inclusive scientific environment. Researchers from all backgrounds are encouraged to apply.",

  positions: [
    {
      type: "Postdoctoral Fellows", icon: "🎓", open: false,
      description: "We are actively recruiting postdoctoral scientists with expertise in electrophysiology, cell biology, structural biology, or computational biophysics. Candidates should have (or be completing) a PhD in a relevant field. Strong publication record and independent thinking are valued.",
      how: "Send a CV, brief research statement (1–2 pages), and contact information for three references to yma4@usf.edu with the subject line: 'Postdoc Application – [Your Name]'."
    },
    {
      type: "PhD Students", icon: "🧪", open: false,
      description: "Prospective PhD students should apply through the USF PhD Programs. Rotation students are welcome year-round. We look for intellectual curiosity, resilience, and a passion for cardiac biology.",
      how: "Apply to the UMS graduate programs and indicate interest in the Ma Lab during your application. Rotation requests can be sent directly to Dr. Ma."
    },
    {
      type: "Undergraduate Researchers", icon: "🔭", open: false,
      description: "We accept motivated undergraduates for part-time research during the academic year and full-time summer positions. Prior wet lab experience is helpful but not required. Commitment of at least one academic year is preferred.",
      how: "Email Dr. Ma with a brief introduction, your CV/resume, and your availability. Subject: 'Undergraduate Research Inquiry'."
    },
    {
      type: "Research Technician", icon: "🛠️", open: false,
      description: "No technician positions are currently open. Check back or send an inquiry to be kept on file for future openings.",
      how: ""
    }
  ],

};
