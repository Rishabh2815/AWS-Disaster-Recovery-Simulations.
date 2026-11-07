(() => {
  const links = [...document.querySelectorAll('.nav-item')];
  const sections = links.map(link => document.querySelector(link.getAttribute('href'))).filter(Boolean);

  const setActive = () => {
    const marker = window.scrollY + 130;
    let active = sections[0];
    for (const section of sections) {
      if (section.offsetTop <= marker) active = section;
    }
    links.forEach(link => link.classList.toggle('active', link.getAttribute('href') === `#${active.id}`));
  };

  window.addEventListener('scroll', setActive, { passive: true });
  window.addEventListener('hashchange', setActive);
  setActive();
})();
