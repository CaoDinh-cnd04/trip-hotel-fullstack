#!/bin/bash

# Script để push lên GitHub
# Thay đổi URL dưới đây với GitHub repository URL của bạn

echo "🚀 Đang push Trip Hotel Mobile App lên GitHub..."
echo ""

# Add remote origin (thay đổi URL này)
echo "📡 Adding remote origin..."
git remote add origin https://github.com/YOUR_USERNAME/trip-hotel-mobile.git

# Push to GitHub
echo "⬆️ Pushing to GitHub..."
git branch -M main
git push -u origin main

echo ""
echo "✅ Hoàn thành! Dự án đã được đẩy lên GitHub"
echo "🔗 Repository URL: https://github.com/YOUR_USERNAME/trip-hotel-mobile"
echo ""
echo "📋 Các bước tiếp theo:"
echo "1. Cập nhật file README.md với thông tin chính xác"
echo "2. Tạo release đầu tiên"
echo "3. Setup CI/CD nếu cần"
echo "4. Invite collaborators"