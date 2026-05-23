/* ==============================================
   MEOWTUAL LOVE — contact.js
   ============================================== */

function selectAmt(btn) {
  document.querySelectorAll('.donation-btn').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  document.getElementById('customAmt').value = '';
}

function selectFreq(btn) {
  document.querySelectorAll('.freq-btn').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
}

document.addEventListener('DOMContentLoaded', () => {

  /* Contact form */
  document.getElementById('contactSubmit')?.addEventListener('click', () => {
    const success = document.getElementById('formSuccess');
    success.classList.add('visible');
    setTimeout(() => success.classList.remove('visible'), 5000);
  });

  /* Donate */
  document.getElementById('donateBtn')?.addEventListener('click', () => {
    const active = document.querySelector('.donation-btn.active');
    const custom = document.getElementById('customAmt')?.value;
    const freq   = document.querySelector('.freq-btn.active')?.textContent.trim();
    const amt    = custom ? '$' + custom : (active?.textContent || '$50');
    alert(`Thank you for your generous ${amt} donation (${freq})! 🐾❤️\n\nEvery dollar helps us save more cats.`);
  });

  /* Volunteer CTA */
  document.getElementById('volunteerBtn')?.addEventListener('click', () => {
    const subjectInput = document.querySelector('.form-input[placeholder="How can we help?"]');
    if (subjectInput) subjectInput.value = 'Volunteer Inquiry';
    document.querySelector('.contact-form-wrap')?.scrollIntoView({ behavior: 'smooth' });
  });

});
