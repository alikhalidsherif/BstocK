import os
import sys
from sqlalchemy.orm import Session

# Add the project root to the Python path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.database import SessionLocal, engine
from app.models import Base, User, UserRole
from app.auth import get_password_hash

# This ensures tables are created
Base.metadata.create_all(bind=engine)

def seed_admin_user():
    print("--- Seeding Admin User ---")
    
    # Get credentials from environment variables
    admin_username = os.getenv("ADMIN_USERNAME")
    admin_password = os.getenv("ADMIN_PASSWORD")

    # Check if the variables are set
    if not admin_username or not admin_password:
        print("Error: ADMIN_USERNAME and ADMIN_PASSWORD environment variables must be set.")
        return

    db: Session = SessionLocal()
    try:
        # Check if user already exists
        db_user = db.query(User).filter(User.username == admin_username).first()
        if db_user:
            print(f"Admin user '{admin_username}' already exists.")
        else:
            hashed_password = get_password_hash(admin_password)
            new_admin = User(
                username=admin_username, 
                hashed_password=hashed_password,
                role=UserRole.admin,
                is_active=True
            )
            db.add(new_admin)
            db.commit()
            print(f"Admin user '{admin_username}' created successfully!")
    
    finally:
        db.close()

# This allows you to run the file directly
if __name__ == "__main__":
    seed_admin_user() 