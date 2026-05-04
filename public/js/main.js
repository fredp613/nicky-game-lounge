// ═══════════════════════════════════════
//  Nicky's Game Lounge — Main JS
// ═══════════════════════════════════════

document.addEventListener('DOMContentLoaded', () => {
    createParticles();
    initNickyInteraction();
});

// ── Floating pixel particles ──
function createParticles() {
    const container = document.getElementById('particles');
    if (!container) return;

    const colors = ['#e84040', '#42A5F5', '#4CAF50', '#FFB74D', '#AB47BC', '#ffffff'];
    const count = Math.min(25, Math.floor(window.innerWidth / 60));

    for (let i = 0; i < count; i++) {
        const p = document.createElement('div');
        p.className = 'particle';
        p.style.left = Math.random() * 100 + '%';
        p.style.width = (2 + Math.random() * 4) + 'px';
        p.style.height = p.style.width;
        p.style.background = colors[Math.floor(Math.random() * colors.length)];
        p.style.animationDuration = (12 + Math.random() * 20) + 's';
        p.style.animationDelay = (Math.random() * 15) + 's';
        p.style.borderRadius = Math.random() > 0.5 ? '50%' : '2px';
        container.appendChild(p);
    }
}

// ── Nicky interaction — squish on click ──
function initNickyInteraction() {
    const sprite = document.getElementById('nickySprite');
    if (!sprite) return;

    sprite.style.cursor = 'pointer';

    sprite.addEventListener('click', () => {
        sprite.style.animation = 'none';
        sprite.offsetHeight; // reflow
        sprite.style.animation = '';

        sprite.classList.add('squish');
        setTimeout(() => sprite.classList.remove('squish'), 400);
    });

    // Add squish keyframes dynamically
    const style = document.createElement('style');
    style.textContent = `
        .nicky-sprite-wrapper.squish {
            animation: nickySquish 0.4s ease both !important;
        }
        @keyframes nickySquish {
            0% { transform: scale(1, 1); }
            30% { transform: scale(1.15, 0.85); }
            60% { transform: scale(0.92, 1.08); }
            100% { transform: scale(1, 1); }
        }
    `;
    document.head.appendChild(style);
}
