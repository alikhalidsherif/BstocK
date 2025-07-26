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

### Frontend

1.  Navigate to the `frontend` directory.
2.  Download the Roboto font from [here](https://www.fontsquirrel.com/fonts/roboto).
3.  Unzip the downloaded file and copy all of the `.ttf` files to the `frontend/fonts` directory.
4.  Run the following command to start the frontend application:

    ```
    flutter run -d chrome
    ```

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change. 