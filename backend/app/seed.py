import getpass
import sys
import os
from sqlalchemy.orm import Session

# Add the project root to the Python path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.database import SessionLocal, engine
from app.models import Base, User, UserRole
from app.auth import get_password_hash

# This ensures tables are created
Base.metadata.create_all(bind=engine)

def seed_admin_user():
    db: Session = SessionLocal()
    try:
        print("--- Seeding Admin User ---")

        # Check if an admin user already exists
        admin_exists = db.query(User).filter(User.role == UserRole.admin).first()
        if admin_exists:
            print("Admin user already exists. Skipping.")
            return

        print("Creating a new admin user.")
        username = input("Enter admin username: ")
        password = getpass.getpass("Enter admin password: ")
        
        hashed_password = get_password_hash(password)
        
        admin_user = User(
            username=username,
            hashed_password=hashed_password,
            role=UserRole.admin,
            is_active=True
        )
        
        db.add(admin_user)
        db.commit()
        
        print(f"Admin user '{username}' created successfully!")

    finally:
        db.close()

if __name__ == "__main__":
    seed_admin_user() 