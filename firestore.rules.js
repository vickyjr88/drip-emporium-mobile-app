rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Rules for the 'users' collection:
    // - Users can read their own profile.
    // - Only authenticated admins can create, update, or delete any user document
    //   (e.g., to set roles like 'isAdmin').
    match /users/{userId} {
      allow read: if request.auth.uid == userId;
      allow create, update, delete: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }

    // Rules for the 'stores' collection:
    // - Only authenticated admins can create, read, update, or delete store documents.
    match /stores/{storeId} {
      allow read, create, update, delete: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }

    // Rules for the 'attenders' collection:
    // - Only authenticated admins can create, read, update, or delete attender documents.
    match /attenders/{attenderId} {
      allow read, create, update, delete: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }

    // Example rules for other collections (adjust as per your application's needs):

    // Rules for the 'orders' collection:
    // - Authenticated users can create orders.
    // - Users can read their own orders.
    // - Only authenticated admins can read all orders and update order status.
    match /orders/{orderId} {
      allow create: if request.auth != null;
      allow read: if request.auth.uid == resource.data.userId || (request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true);
      allow update: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
      allow delete: if false; // Orders are typically not deleted by users or admins directly
    }

    // Rules for the 'products' collection:
    // - Everyone can read product information.
    // - Only authenticated admins can create, update, or delete product documents.
    match /products/{productId} {
      allow read: true;
      allow create, update, delete: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
  }
}
