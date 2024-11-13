# CommerceCore Product Management Service v1

This **Product Management Service** is part of a microservices-based e-commerce
platform, handling the management of products, categories, carts, and orders. It
provides APIs for developers to manage their e-commerce products, orders, and
checkout processes. The service also integrates with other microservices for
user authentication and payment processing.

The service is built using **Ruby on Rails**, with **Sidekiq** for background
job processing and **Redis** for caching and Pub/Sub messaging.

---

## **Features**

- **Product Management**: Create, update, delete, and manage products, including
  product images.
- **Category Management**: Manage categories to organize products.
- **Cart Management**: Handle user carts, adding/removing items, and tracking
  items for checkout.
- **Order Management**: Create orders from carts, manage order statuses, and
  allow users to view their order history.
- **Checkout Process**: Move items from the cart to an order, trigger the
  payment process, and update order statuses accordingly.
- **Real-time Order Status**: Track and update the status of orders in real-time
  via WebSocket (ActionCable).
- **Order Cancellation**: Allow users to cancel orders when they are in
  `pending` or `processing` status.

---

## **Table of Contents**

- [Features](#features)
- [Installation](#installation)
- [Configuration](#configuration)
- [API Endpoints](#api-endpoints)
- [Real-time Order Status](#real-time-order-status)
- [Background Jobs](#background-jobs)
- [Testing](#testing)
- [Postman Documentation](#postman-documentation)
- [Contributing](#contributing)
- [License](#license)

---

## **Installation**

### **Requirements**

- **Ruby**: 3.0 or higher
- **Rails**: 7.2.1 or higher
- **Redis**: For caching and Pub/Sub
- **Sidekiq**: For background job processing
- **PostgreSQL**: Database for storing product, order, and cart data

### **Setup Instructions**

1. Clone the repository:
   ```bash
   git clone https://github.com/Backendly/commercecore-product-management-service
   cd commercecore-product-management-service
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Set up the database:
   ```bash
   rails db:create
   rails db:migrate
   ```

4. Start the application:
   ```bash
   rails server
   ```

5. Start Sidekiq for background job processing:
   ```bash
   bundle exec sidekiq
   ```

6. Ensure Redis is running for Pub/Sub and caching:
   ```bash
   redis-server
   ```

---

## **Configuration**

### **Environment Variables**

The following environment variables need to be configured:

- `REDIS_URL`: The URL for your Redis server.
- `MESSAGE_BROKER_URL`: The URL for your Redis server (for Pub/Sub messaging).
- `REDIS_PROVIDER`: Set to `MESSAGE_BROKER_URL` or `REDIS_URL`  for Sidekiq configuration.
- `DATABASE_URL`: The URL for your PostgreSQL database.
- `RAILS_ENV`: Set to `development`, `test`, or `production` as needed.

### **Queue Adapter**

The application uses **Sidekiq** for background job processing. Ensure that *
*ActiveJob** is set to use `Sidekiq` as the queue adapter.

In `config/application.rb`:

```ruby
config.active_job.queue_adapter = :sidekiq
```

---

## **API Endpoints**

Below is a summary of the major API endpoints provided by this service. For a
full list, refer to the **Postman Documentation**.

---

### **API Root Endpoint**

- **GET /api/v1**
  This endpoint serves as the root for the **Product Management Service** API.
  It provides a basic response indicating that the service is running and
  available, giving developers a way to verify that the API is live.

---

### **Health Status Endpoint**

- **GET /api/v1/status**
  This endpoint checks the health of the **Product Management Service**. It
  returns the status of the service, verifying that it is up and running. This
  can be used for monitoring purposes to ensure the service is operating as
  expected.

  This is useful for health checks in production environments, ensuring the
  service and its dependencies (like the database and Redis) are properly
  functioning.

---

### **Categories**

- **GET /api/v1/categories**: List all categories.
- **POST /api/v1/categories**: Create a new category.
- **GET /api/v1/categories/:id**: Retrieve details of a specific category.
- **PUT /api/v1/categories/:id**: Update a category.
- **DELETE /api/v1/categories/:id**: Delete a category.

### **Products**

- **GET /api/v1/products**: List all products, with optional filters (e.g., by
  price, name, category).
- **POST /api/v1/products**: Create a new product (without images).
- **GET /api/v1/products/:id**: Retrieve details of a specific product.
- **PUT /api/v1/products/:id**: Update a product.
- **DELETE /api/v1/products/:id**: Delete a product.
- **POST /api/v1/products/:id/images**: Add images to a product.
- **DELETE /api/v1/products/:id/images/:image_id**: Remove an image from a
  product.

### **Carts**

- **GET /api/v1/cart**: Retrieve the user's current cart (created automatically
  on first request).
- **POST /api/v1/cart/items**: Add an item to the cart.
- **DELETE /api/v1/cart/items/:id**: Remove an item from the cart.

### **Checkout**

- **POST /api/v1/cart/checkout**: Initiate the checkout process and create an
  order from the cart. The order status is updated in real-time via WebSocket.

### **Orders**

- **GET /api/v1/orders**: List all orders for the current authenticated user (
  latest first).
- **GET /api/v1/orders/:id**: Retrieve details of a specific order.
- **GET /api/v1/orders/:id/items**: Retrieve all items for a specific order.
- **GET /api/v1/orders/:id/items/:item_id**: Retrieve a specific item from an
  order.
- **POST /api/v1/orders/:id/cancel**: Cancel an order if it is in the `pending`
  or `processing` state.

---

## **Real-time Order Status**

- **WebSocket Channel**: `OrderStatusChannel`
    - After initiating a checkout, the frontend can subscribe to real-time
      updates for the order via WebSocket.
    - The order status (`pending`, `successful`, `failed`) is broadcasted as the
      payment is processed.
    - Subscription URL:
      `wss://commerce-core-product-mgmt-api-b42744f7b4b9.herokuapp.com/cable`

---

## **Background Jobs**

The service uses **Sidekiq** for background processing. Below are the key
background jobs:

- **PaymentServiceNotifierJob**: Notifies the payment service to process the
  payment after checkout.
- **PaymentStatusListenerJob**: Listens for updates from the payment service via
  Redis Pub/Sub.
- **PaymentStatusJob**: Updates the order status based on the payment result (
  successful/failed).
- **CartCleanupJob**: Clears the user's cart upon successful checkout and
  updates the stock quantity for each product.

---

## **Testing**

The service includes comprehensive unit and integration tests for all major
functionalities, including:

- Product and category management.
- Cart and order creation.
- Checkout process and real-time order status updates.

To run the test suite:

```bash
bundle exec rspec
```

---

## **Postman Documentation**

Detailed API documentation for all available endpoints can be found on
**Postman**:

[**Postman API Documentation**](https://documenter.getpostman.com/view/14404907/2sAXjRWpnZ)

---

## **Contributing**

We welcome contributions from the community! If you'd like to contribute:

1. Fork the repository.
2. Create a new feature branch: `git checkout -b feature/my-feature`.
3. Commit your changes: `git commit -m 'Add new feature'`.
4. Push to the branch: `git push origin feature/my-feature`.
5. Open a pull request.

Please ensure all tests pass before submitting your PR.
