# BstocK

A stock management application built with Flutter and FastAPI.

## Features

- User authentication with JWT
- Role-based access control (Admin, Supervisor, Clerk)
- Product management (CRUD)
- Inventory change requests (add, sell)
- Request approval system
- Change history and audit trail
- User management

## Setup

### Prerequisites

- Docker
- Docker Compose
- Flutter SDK

### Backend

1.  Navigate to the `backend` directory.
2.  Create a `.env` file and add the following:

    ```
    DATABASE_URL=postgresql://user:password@db/bstock_db
    SECRET_KEY=your_secret_key
    ALGORITHM=HS256
    ACCESS_TOKEN_EXPIRE_MINUTES=30
    ```

3.  Run the following command to start the backend service:

    ```
    docker-compose up --build
    ```

## Database Migrations

If you are updating an existing database, you will need to apply the following migrations:

```sql
ALTER TABLE change_requests ADD COLUMN new_product_name VARCHAR;
ALTER TABLE change_requests ADD COLUMN new_product_barcode VARCHAR;
ALTER TABLE change_requests ADD COLUMN new_product_price FLOAT;
ALTER TABLE change_requests ADD COLUMN new_product_quantity INTEGER;
ALTER TABLE change_requests ADD COLUMN new_product_category VARCHAR;
ALTER TABLE change_requests ALTER COLUMN product_id DROP NOT NULL;

ALTER TABLE change_history ADD COLUMN buyer_name VARCHAR;
ALTER TABLE change_history ADD COLUMN payment_status VARCHAR;
```

### Frontend

1.  Navigate to the `frontend` directory.
2.  Run the following command to start the frontend application:

    ```
    flutter run -d chrome
    ```

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change. 