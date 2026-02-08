// 禁用侧边栏分组标题的点击
document.addEventListener('DOMContentLoaded', function() {
    // 找到所有分组标题并禁用点击
    const groupTitles = document.querySelectorAll('aside nav > div > button, aside nav > div > a');
    groupTitles.forEach(title => {
        // 检查是否是分组标题（没有子元素的）
        const parent = title.closest('div');
        if (parent && parent.querySelector('div > a, div > button')) {
            title.style.cursor = 'default';
            title.style.pointerEvents = 'none';
        }
    });
});

