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

  const events = [...document.querySelectorAll('.timeline-item')];
  const replayButton = document.querySelector('#replay-button');
  const pauseButton = document.querySelector('#pause-button');
  const resetButton = document.querySelector('#reset-button');
  const speedSelect = document.querySelector('#playback-speed');
  const progress = document.querySelector('#replay-progress');
  const progressBar = document.querySelector('.replay-progress');
  const replayState = document.querySelector('#replay-state');
  const duration = Math.max(...events.map(event => Number(event.dataset.offset)));
  let elapsed = 0;
  let timer = null;
  let isPaused = false;

  const paintReplay = () => {
    events.forEach(event => {
      const completed = Number(event.dataset.offset) <= elapsed;
      event.classList.toggle('event-complete', completed);
      event.classList.toggle('event-current', completed && Number(event.dataset.offset) === elapsed);
    });
    const percentage = duration ? (elapsed / duration) * 100 : 0;
    progress.style.width = `${percentage}%`;
    progressBar.setAttribute('aria-valuenow', String(elapsed));
    replayState.textContent = elapsed >= duration ? 'COMPLETE · 135s' : `T + ${elapsed}s · RECORDED RUN`;
  };

  const stopTimer = () => {
    if (timer) window.clearInterval(timer);
    timer = null;
  };

  const finishReplay = () => {
    stopTimer();
    isPaused = false;
    pauseButton.disabled = true;
    pauseButton.textContent = 'Ⅱ Pause';
    replayButton.disabled = false;
    replayButton.innerHTML = '✓ <span>Replay again</span>';
    paintReplay();
  };

  const startReplay = () => {
    if (elapsed >= duration) elapsed = 0;
    isPaused = false;
    replayButton.disabled = true;
    pauseButton.disabled = false;
    pauseButton.textContent = 'Ⅱ Pause';
    replayState.textContent = 'PLAYING · RECORDED RUN';
    paintReplay();
    stopTimer();
    timer = window.setInterval(() => {
      elapsed = Math.min(duration, elapsed + 1);
      paintReplay();
      if (elapsed >= duration) finishReplay();
    }, 1000 / Number(speedSelect.value));
  };

  replayButton.addEventListener('click', startReplay);
  pauseButton.addEventListener('click', () => {
    if (isPaused) {
      startReplay();
      return;
    }
    isPaused = true;
    stopTimer();
    pauseButton.textContent = '▶ Resume';
    replayButton.disabled = false;
    replayButton.innerHTML = '▶ <span>Continue run</span>';
    replayState.textContent = `PAUSED · T + ${elapsed}s`;
  });
  resetButton.addEventListener('click', () => {
    stopTimer();
    elapsed = 0;
    isPaused = false;
    replayButton.disabled = false;
    replayButton.innerHTML = '▶ <span>Replay run</span>';
    pauseButton.disabled = true;
    pauseButton.textContent = 'Ⅱ Pause';
    paintReplay();
  });
  speedSelect.addEventListener('change', () => {
    if (!timer) return;
    stopTimer();
    timer = window.setInterval(() => {
      elapsed = Math.min(duration, elapsed + 1);
      paintReplay();
      if (elapsed >= duration) finishReplay();
    }, 1000 / Number(speedSelect.value));
  });
  paintReplay();

  const filterButtons = [...document.querySelectorAll('.filter-chip')];
  filterButtons.forEach(button => button.addEventListener('click', () => {
    filterButtons.forEach(item => item.classList.toggle('active', item === button));
    const filter = button.dataset.filter;
    events.forEach(event => {
      event.hidden = filter !== 'all' && event.dataset.kind !== filter;
    });
  }));

  document.querySelector('#export-events').addEventListener('click', () => {
    const rows = [['offset_seconds', 'event', 'category', 'recorded_time'], ...events.map(event => [
      event.dataset.offset,
      event.querySelector('b').textContent,
      event.dataset.kind,
      event.querySelector('time').textContent,
    ])];
    const csv = rows.map(row => row.map(value => `"${String(value).replaceAll('"', '""')}"`).join(',')).join('\r\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'disaster-recovery-events.csv';
    link.click();
    URL.revokeObjectURL(url);
  });
})();
