#!/bin/bash

# Script to run Django API server accessible from real iOS device
echo "🚀 Starting Django API server for real device testing..."
echo "📱 Your Mac IP: 172.20.10.13"
echo "🔗 API will be accessible at: http://172.20.10.13:8000"
echo ""

# Navigate to your Django project directory (adjust this path if needed)
# Replace this with your actual Django project path
DJANGO_PROJECT_PATH="../your-django-project"

if [ ! -d "$DJANGO_PROJECT_PATH" ]; then
    echo "❌ Django project not found at: $DJANGO_PROJECT_PATH"
    echo "📝 Please update DJANGO_PROJECT_PATH in this script to point to your Django project"
    echo ""
    echo "Manual command to run in your Django project directory:"
    echo "python manage.py runserver 0.0.0.0:8000"
    echo ""
    echo "⚠️  Important: Add '172.20.10.13' to ALLOWED_HOSTS in your Django settings.py:"
    echo "ALLOWED_HOSTS = ['localhost', '127.0.0.1', '172.20.10.13']"
    exit 1
fi

cd "$DJANGO_PROJECT_PATH"

echo "📂 Starting server from: $(pwd)"
echo ""
echo "⚠️  Make sure your Django settings.py includes:"
echo "ALLOWED_HOSTS = ['localhost', '127.0.0.1', '172.20.10.13']"
echo ""

# Run Django server on all interfaces
python manage.py runserver 0.0.0.0:8000
