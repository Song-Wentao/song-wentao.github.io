// data/lab.js  — single source of truth for all lab content
// Edit this file to update the entire website.

const LAB = {

  // ── Identity ──────────────────────────────────────────────
  name:       "Shuli Huang",
  fullName:   "Laboratory of Cardiac Physiology",
  dept:       "College of Medicine Molecular Pharmacology & Physiology",
  university: "",
  email:      "",
  phone:      "",
  address:    "",


  // ── About ─────────────────────────────────────────────────
  tagline: "Decoding the language of the beating heart.",
  mission: "I am a cardiovascular physiologist with expertise in neuroendocrinology and immunology. My research uses rodent models to define neuroendocrine mechanisms underlying stress-responsive social behavior, focusing on oxytocinergic and vasopressinergic regulation of aggression and their cardiovascular and neuroendocrine consequences. In parallel, I investigate myocardial infarction–induced ischemic heart failure, examining how innate and adaptive immune cells regulate post-infarction cardiac repair and remodeling, with emphasis on T cell lymphopenia, age-related thymic involution, and innate immune memory.",

  highlights: [
    { icon: "", label: "CV", link: "data/CV_Huang.pdf" },
    { icon: "", label: "Google scholar", link: "https://scholar.google.com/citations?user=8bUj260AAAAJ&hl=en" }
  ],


  // ── News ──────────────────────────────────────────────────
  news: [
    {
      date: "March 2026",
      title: "NIH R01 Renewal Awarded",
      body: "We are thrilled to announce that"
    }
  ],

  // ── People ────────────────────────────────────────────────
  pi: {
    name:   "Dr. Shuli Huang, PhD",
    title:  "Postdoctoral Scholar",
    photo:  "img/HUang.jpg",
    bio:    "I am a cardiovascular physiologist with expertise in neuroendocrinology and immunology. My research uses rodent models to define neuroendocrine mechanisms underlying stress-responsive social behavior, focusing on oxytocinergic and vasopressinergic regulation of aggression and their cardiovascular and neuroendocrine consequences. In parallel, I investigate myocardial infarction–induced ischemic heart failure, examining how innate and adaptive immune cells regulate post-infarction cardiac repair and remodeling, with emphasis on T cell lymphopenia, age-related thymic involution, and innate immune memory.",
    email:  "",
    scholar: "",
    cv:     "#"
  },

  members: [
    { name: "", role: "",   photo: "", research: "To be added", joined: 2025 }
  ],

  alumni: [
    { name: "",     role: "Postdoc", years: "2018–2022", current: "Assistant Professor" },
    { name: "",role: "PhD",     years: "2016–2021", current: "Scientist" },
    { name: "",        role: "Tech",    years: "2019–2021", current: "MD/PhD Student" }
  ],

  // ── Publications ─────────────────────────────────────────
  publications: [
    { year: 2025, 
      authors: "Huang, S., Nunez, J., Toresco, DL., Wen, C., Slotabec, L., Wang, H., Zhang, H., Rouhi, N., Adenawoola, MI., Li, J.",    
      title: "Alterations in the inflammatory homeostasis of aging-related cardiac dysfunction and Alzheimer's diseases.",           
      journal: "FASEB Journal", 
      volume: "39(1): e70303",
      pdf: "#", highlight: true },
    { year: 2025,
      authors: "Li, G., Zhang, M., Huang, S., He, H., Wan, X., Wang, F., & Zhang, Z.",
      title: "Density‐Dependent Difference in Serum Levels of Immunoglobulin G in Brandt's Voles and Its Potential Influencing Factors.",
      journal: "Integrative Zoology",
      volume: "20(5), 963-970.",
      pdf: "#", highlight: false },
    { year: 2023, 
      authors: "Zhang, X., Firman, R. C., Song, M., Li, G., Cheng, C., Liu, J., Huang, S., Batsuren, E., Zhang, Z.",    
      title: "Male and female Brandt’s voles have higher reproductive success when they have more mating partners regardless of population density.",           
      journal: "Behavioral Ecology", 
      volume: "34(4), 662-672",
      pdf: "#", 
      highlight: false },
    { year: 2023, 
      authors: "Lu, W., Huang, S., Liu, J., Batsuren, E., Li, G., Wan, X., Zhao, J., Wang, Z., Han, W., Zhang, Z.",    
      title: "Effects of group size on behavior, reproduction, and mRNA expression in brains of Brandt's Voles.",           
      journal: "Brain Science", 
      volume: "13(2)",
      pdf: "#", 
      highlight: false },
    { year: 2022, 
      authors: "Zhao, J., Lu, W., Huang, S., Le Maho, Y., Habold, C., Zhang, Z.",    
      title: "Impacts of dietary protein and niacin deficiency on reproduction performance, body growth, and gut microbiota of female hamsters (Tscherskia triton) and their offspring.",           
      journal: "Microbiology Spectrum", 
      volume: "10(6), e0015722",
      pdf: "#", 
      highlight: false },
    { year: 2022, 
      authors: "Batsuren, E., Zhang, X., Song, M., Wan, X., Li, G., Liu, J., Huang, S., Zhang, Z.",    
      title: "Density‐dependent changes of mating system and family structure in Brandt's voles (Lasiopodomys brandtii).",           
      journal: "Ecology and Evolution", 
      volume: "12(8), e9199",
      pdf: "#", 
      highlight: false },
    { year: 2021, 
      authors: "Liu, J., Huang, S., Zhang, X., Li, G., Batsuren, E., Lu, W., Xu, X., He, C., Song, Y., Zhang, Z.",    
      title: "Gut microbiota reflect the crowding stress of space shortage, physical and non-physical contact in Brandt's voles (Lasiopodomys brandtii).",           
      journal: "Microbiological Research", 
      volume: "255, 126928",
      pdf: "#", 
      highlight: false },
    { year: 2021, 
      authors: "Huang, S., Li, G., Pan, Y., Liu, J., Zhao, J., Zhang, X., Lu, W., Wan, X., Krebs, C. J., Wang, Z., Han, W., Zhang, Z.",    
      title: "Population variation alters aggression-associated oxytocin and vasopressin expressions in brains of Brandt's voles in field conditions.",           
      journal: "Frontiers in Zoology", 
      volume: "18(1), 56",
      pdf: "#", 
      highlight: false },
    { year: 2021, 
      authors: "Li, G., Wan, X., Yin, B., Wei, W., Hou, X., Zhang, X., Batsuren, E., Zhao, J., Huang, S., Xu, X., Liu, J., Song, Y., Ozgul, A., Dickman, C. R., Wang, G., Krebs, C. J., Zhang, Z.",    
      title: "Timing outweighs magnitude of rainfall in shaping population dynamics of a small mammal species in steppe grassland.",           
      journal: "Proceedings of the National Academy of Sciences of the United States of America", 
      volume: "118(42)",
      pdf: "#", 
      highlight: false },
    { year: 2021, 
      authors: "Huang, S., Li, G., Pan, Y., Song, M., Zhao, J., Wan, X., Krebs, C. J., Wang, Z., Han, W., Zhang, Z.",    
      title: "Density-induced social stress alters oxytocin and vasopressin activities in the brain of a small rodent species.",           
      journal: "Integrative Zoology", 
      volume: "16(2), 149-159",
      pdf: "#", 
      highlight: false },
    { year: 2020, 
      authors: "Liu, J., Huang, S., Li, G., Zhao, J., Lu, W., Zhang, Z.",    
      title: "High housing density increases stress hormone- or disease-associated fecal microbiota in male Brandt's voles (Lasiopodomys brandtii).",           
      journal: "Hormones and Behavior", 
      volume: "126, 104838",
      pdf: "#", 
      highlight: false },
    { year: 2020, 
      authors: "Zhao, J., Li, G., Lu, W., Huang, S., Zhang, Z.",    
      title: "Dominant and subordinate relationship formed by repeated social encounters alters gut microbiota in greater long-tailed hamsters.",           
      journal: "Microbial Ecology", 
      volume: "79(4), 998-1010",
      pdf: "#", 
      highlight: false }
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
