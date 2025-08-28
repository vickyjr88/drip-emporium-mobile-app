# Drip Emporium Mobile App - Order Management Feature Plan

This plan outlines the enhancements and new feature implementations for the Drip Emporium Mobile App to manage orders for physical stores.

## Phase 1: Core Data Models & Backend Integration

*   **Define Data Models:**
    *   Create new Dart classes for `Store` (id, name, address, etc.).
    *   Create new Dart classes for `Attender` (id, name, email, storeId, role, etc.).
    *   Enhance existing `Customer` model (or create if not explicit) to include types like 'Shop', 'Reseller', 'Client'.
    *   Enhance existing `Order` model (or create if not explicit) to include status (e.g., `Pending`, `Completed`, `Returned`), customer type at order, discount applied, bargain price, and final price.
*   **Firebase Security Rules:**
    *   Update Firebase Firestore security rules to accommodate the new `stores` and `attenders` collections.
    *   Modify rules for `customers` and `orders` collections to reflect new fields and access patterns, ensuring proper data access and security.
*   **Data Repository (`lib/services/data_repository.dart`):**
    *   Implement CRUD (Create, Read, Update, Delete) operations for `Stores` and `Attenders`.
    *   Enhance existing methods for `Customers` and `Orders` to support new fields and functionalities (e.g., updating order status, fetching orders by store/date).

## Phase 2: Business Logic & State Management

*   **Providers (`lib/providers/`):**
    *   Create new providers (e.g., `StoreProvider`, `AttenderProvider`) to manage the state and data flow for stores and attenders.
    *   Enhance existing providers (e.g., `CartProvider`, `ProductsProvider`, `OrdersProvider`) to incorporate the new pricing logic (based on customer type, discounts, bargains) and order status management.
    *   Implement logic for calculating daily/weekly sales statistics within an appropriate provider or service, aggregating data from orders.

## Phase 3: User Interface Development

*   **New Screens (`lib/screens/`):**
    *   Develop dedicated screens for `Store Management` (allowing users to add, view, edit, and delete stores).
    *   Develop `Attender Management` screens (for adding, viewing, editing, and deleting attenders).
    *   Create a `Sales Statistics` screen to display daily and weekly sales data, potentially with charts or summary tables.
*   **Enhance Existing Screens:**
    *   Modify the `Order Creation` flow (likely within `ProductDetailsScreen` or `CartScreen`) to allow selection of customer type, input for discounts/bargains, and dynamic display of computed final prices.
    *   Update `Order Details` screens to enable changing order status, including specific functionality for marking items as returned.
*   **Navigation:**
    *   Integrate the new screens into the app's navigation structure, potentially by adding new tabs to `bottom_nav_bar_screen.dart` or creating a dedicated admin/management section.

## Phase 4: Testing & Refinement

*   **Unit & Widget Tests:**
    *   Write comprehensive unit tests for all new data models, service methods, and provider logic to ensure correctness and reliability.
    *   Develop widget tests for new UI components and enhanced existing ones to verify proper rendering and interaction.
*   **Code Quality:**
    *   Regularly run `flutter analyze` to identify and fix potential issues, and `flutter format` to maintain consistent code style.
*   **Build Verification:**
    *   Ensure the application builds successfully for all target platforms (Android, iOS, Web, etc.) after each major change, catching compilation errors early.
