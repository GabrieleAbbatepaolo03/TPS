document.addEventListener('DOMContentLoaded', function() {
    // Add home icon to topbar
    addHomeIcon();
    
    // Remove all back buttons and settings
    removeBackButtons();
    removeSettingsFromSidebar();
});

function addHomeIcon() {
    const header = document.querySelector('.unfold-header');
    if (!header || document.querySelector('.home-icon')) return;
    
    const homeBtn = document.createElement('a');
    homeBtn.href = '/admin/';
    homeBtn.className = 'home-icon';
    homeBtn.title = 'Dashboard';
    homeBtn.innerHTML = `
        <svg width="20" height="20" fill="currentColor" viewBox="0 0 24 24">
            <path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/>
        </svg>
    `;
    
    // Insert before theme/profile icons (usually on the right side)
    const actions = header.querySelector('.unfold-header-actions, [class*="actions"]');
    if (actions) {
        actions.insertBefore(homeBtn, actions.firstChild);
    }
}

function removeBackButtons() {
    // Remove breadcrumbs
    const breadcrumbs = document.querySelectorAll('.unfold-breadcrumb, .breadcrumbs, [class*="breadcrumb"]');
    breadcrumbs.forEach(el => el.remove());
    
    // Remove back links
    const backLinks = document.querySelectorAll('a[href*=".."], .back-link, [class*="back"]');
    backLinks.forEach(el => {
        if (el.textContent.toLowerCase().includes('back')) {
            el.remove();
        }
    });
}

function removeSettingsFromSidebar() {
    // Remove settings icon and title from sidebar
    const settingsElements = document.querySelectorAll(
        '.unfold-sidebar .unfold-settings, ' +
        '.unfold-sidebar .settings-icon, ' +
        '.unfold-sidebar-header, ' +
        '.unfold-sidebar-brand, ' +
        '.unfold-sidebar h1, ' +
        '.unfold-sidebar .logo'
    );
    settingsElements.forEach(el => el.remove());
}
