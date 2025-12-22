# Firestore Security Rules Configuration

## Vấn đề
Web app đang gặp lỗi "Missing or insufficient permissions" khi truy cập Firestore.

## Giải pháp

### Cách 1: Cấu hình Firestore Rules (Khuyến nghị)

Vào Firebase Console → Firestore Database → Rules và cập nhật rules như sau:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if user is participant in conversation
    function isParticipant(conversationId) {
      return isAuthenticated() && 
             request.auth.uid in resource.data.participants;
    }
    
    // Conversations collection
    match /conversations/{conversationId} {
      // Allow read if user is a participant
      allow read: if isAuthenticated() && 
                     request.auth.uid in resource.data.participants;
      
      // Allow write if user is a participant
      allow write: if isAuthenticated() && 
                      request.auth.uid in resource.data.participants;
      
      // Allow create if user is in participants array
      allow create: if isAuthenticated() && 
                        request.auth.uid in request.resource.data.participants;
      
      // Messages subcollection
      match /messages/{messageId} {
        // Allow read if user is participant in parent conversation
        allow read: if isAuthenticated() && 
                       request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participants;
        
        // Allow create if user is sender or receiver
        allow create: if isAuthenticated() && 
                         (request.resource.data.senderId == request.auth.uid ||
                          request.resource.data.receiverId == request.auth.uid);
        
        // Allow update if user is sender
        allow update: if isAuthenticated() && 
                         resource.data.senderId == request.auth.uid;
        
        // Allow delete if user is sender
        allow delete: if isAuthenticated() && 
                         resource.data.senderId == request.auth.uid;
      }
    }
    
    // Users collection
    match /users/{userId} {
      // Allow read if user is reading their own data or is authenticated
      allow read: if isAuthenticated() && 
                     (request.auth.uid == userId || 
                      resource.data.backend_user_id != null);
      
      // Allow write if user is writing their own data
      allow write: if isAuthenticated() && 
                      request.auth.uid == userId;
    }
    
    // User mapping collection
    match /user_mapping/{backendUserId} {
      // Allow read if authenticated
      allow read: if isAuthenticated();
      
      // Allow write if authenticated (for creating mappings)
      allow write: if isAuthenticated();
    }
  }
}
```

### Cách 2: Tạm thời cho phép đọc (Chỉ dùng cho Development)

⚠️ **CẢNH BÁO**: Chỉ dùng cho development, KHÔNG dùng cho production!

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true; // ⚠️ Cho phép tất cả - CHỈ DÙNG CHO DEV
    }
  }
}
```

### Cách 3: Authenticate với Firebase Auth

Nếu bạn muốn authenticate user với Firebase sau khi đăng nhập backend, bạn cần:

1. Backend tạo custom token cho Firebase
2. Frontend sign in với custom token đó

Xem file `hotel_web/src/utils/firebaseAuth.js` để biết cách sử dụng.

## Lưu ý

1. **Firestore Rules** là cách bảo mật tốt nhất
2. Nếu user chưa có Firebase account, có thể dùng offline placeholder UID: `offline_{backendUserId}`
3. Đảm bảo user được authenticate với Firebase Auth trước khi truy cập Firestore

## Kiểm tra

Sau khi cấu hình rules, kiểm tra bằng cách:
1. Vào Firebase Console → Firestore Database → Rules
2. Click "Publish" để áp dụng rules
3. Refresh web app và kiểm tra console

