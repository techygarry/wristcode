// ==========================================
// BrightSmile Dental - Interactive Scripts
// ==========================================

document.addEventListener('DOMContentLoaded', () => {

  // --- Navbar scroll effect ---
  const navbar = document.getElementById('navbar');
  const handleScroll = () => {
    navbar.classList.toggle('scrolled', window.scrollY > 20);
  };
  window.addEventListener('scroll', handleScroll, { passive: true });
  handleScroll();

  // --- Mobile nav toggle ---
  const navToggle = document.getElementById('navToggle');
  const navLinks = document.getElementById('navLinks');

  navToggle.addEventListener('click', () => {
    navToggle.classList.toggle('active');
    navLinks.classList.toggle('open');
  });

  // Close mobile nav on link click
  navLinks.querySelectorAll('a').forEach(link => {
    link.addEventListener('click', () => {
      navToggle.classList.remove('active');
      navLinks.classList.remove('open');
    });
  });

  // --- Active nav link on scroll ---
  const sections = document.querySelectorAll('section[id]');
  const navItems = document.querySelectorAll('.nav-links li a:not(.btn)');

  const updateActiveNav = () => {
    const scrollPos = window.scrollY + 100;
    sections.forEach(section => {
      const top = section.offsetTop;
      const height = section.offsetHeight;
      const id = section.getAttribute('id');
      if (scrollPos >= top && scrollPos < top + height) {
        navItems.forEach(item => {
          item.classList.remove('active');
          if (item.getAttribute('href') === `#${id}`) {
            item.classList.add('active');
          }
        });
      }
    });
  };
  window.addEventListener('scroll', updateActiveNav, { passive: true });

  // --- Scroll-reveal animations ---
  const animateElements = document.querySelectorAll(
    '.service-card, .team-card, .testimonial-card, .about-feature, .detail-item'
  );

  animateElements.forEach(el => el.classList.add('animate-in'));

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('visible');
          observer.unobserve(entry.target);
        }
      });
    },
    { threshold: 0.15, rootMargin: '0px 0px -40px 0px' }
  );

  animateElements.forEach(el => observer.observe(el));

  // --- Set minimum date to today for appointment form ---
  const dateInput = document.getElementById('date');
  if (dateInput) {
    const today = new Date().toISOString().split('T')[0];
    dateInput.setAttribute('min', today);
  }

  // --- Appointment form handling ---
  const form = document.getElementById('appointmentForm');
  if (form) {
    form.addEventListener('submit', (e) => {
      e.preventDefault();

      const formData = new FormData(form);
      const data = Object.fromEntries(formData.entries());

      // Simple validation
      if (!data.firstName || !data.lastName || !data.email || !data.phone || !data.service || !data.date) {
        return;
      }

      // Sanitize name for display
      const safeName = document.createElement('span');
      safeName.textContent = data.firstName;

      // Show success state
      const wrapper = form.closest('.appointment-form-wrapper');
      wrapper.innerHTML = '';

      const successDiv = document.createElement('div');
      successDiv.className = 'form-success';

      const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
      svg.setAttribute('viewBox', '0 0 64 64');
      svg.setAttribute('fill', 'none');
      svg.innerHTML = '<circle cx="32" cy="32" r="30" fill="#D1FAE5"/><path d="M20 32L28 40L44 24" stroke="#10B981" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>';

      const h3 = document.createElement('h3');
      h3.textContent = 'Appointment Requested!';

      const p = document.createElement('p');
      p.textContent = `Thank you, ${data.firstName}! We'll contact you within 24 hours to confirm your appointment.`;

      successDiv.appendChild(svg);
      successDiv.appendChild(h3);
      successDiv.appendChild(p);
      wrapper.appendChild(successDiv);

      // Scroll to success message
      wrapper.scrollIntoView({ behavior: 'smooth', block: 'center' });
    });
  }

  // --- Smooth scroll for CTA buttons ---
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', (e) => {
      const target = document.querySelector(anchor.getAttribute('href'));
      if (target) {
        e.preventDefault();
        target.scrollIntoView({ behavior: 'smooth' });
      }
    });
  });

  // --- Phone number formatting ---
  const phoneInput = document.getElementById('phone');
  if (phoneInput) {
    phoneInput.addEventListener('input', (e) => {
      let value = e.target.value.replace(/\D/g, '');
      if (value.length > 10) value = value.slice(0, 10);
      if (value.length >= 6) {
        value = `(${value.slice(0, 3)}) ${value.slice(3, 6)}-${value.slice(6)}`;
      } else if (value.length >= 3) {
        value = `(${value.slice(0, 3)}) ${value.slice(3)}`;
      }
      e.target.value = value;
    });
  }

});
