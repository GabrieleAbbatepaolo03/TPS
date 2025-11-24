from django.utils.translation import gettext_lazy as _


def dashboard_callback(request, context):
    """
    Callback function for Unfold admin dashboard.
    Returns custom dashboard components for the index page.
    """
    context.update({
        "welcome": True,
        "custom_text": f"Welcome, {request.user.first_name or request.user.email}!",
        "kpi": [
            {
                "title": "TPS Management System",
                "metric": "Admin Dashboard",
            },
        ],
    })
    return context
