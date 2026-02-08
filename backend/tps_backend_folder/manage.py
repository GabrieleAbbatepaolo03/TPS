#!/usr/bin/env python
"""Django's command-line utility for administrative tasks."""
import os
import sys
import webbrowser
import threading


def open_browser():
    """自动打开浏览器到 admin 页面"""
    import time
    time.sleep(2)  # 等待服务器启动
    webbrowser.open('http://127.0.0.1:8000/admin/')


def main():
    """Run administrative tasks."""
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'tps_backend.settings')
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Couldn't import Django. Are you sure it's installed and "
            "available on your PYTHONPATH environment variable? Did you "
            "forget to activate a virtual environment?"
        ) from exc

    # 如果是 runserver 命令，自动打开浏览器
    # 只在 reloader 子进程中打开，避免打开两次
    if len(sys.argv) >= 2 and sys.argv[1] == 'runserver':
        if os.environ.get('RUN_MAIN') == 'true':
            threading.Thread(target=open_browser, daemon=True).start()

    execute_from_command_line(sys.argv)


if __name__ == '__main__':
    main()
