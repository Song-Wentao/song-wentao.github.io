// Donation amount selection
document.addEventListener('DOMContentLoaded', function() {
    const donationBtns = document.querySelectorAll('.donation-btn');
    donationBtns.forEach(btn => {
        btn.addEventListener('click', function() {
            donationBtns.forEach(b => b.classList.remove('active'));
            this.classList.add('active');
        });
    });

    const frequencyBtns = document.querySelectorAll('.frequency-btn');
    frequencyBtns.forEach(btn => {
        btn.addEventListener('click', function() {
            frequencyBtns.forEach(b => b.classList.remove('active'));
            this.classList.add('active');
        });
    });
});