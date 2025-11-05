from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import timedelta

from .. import auth, crud, models, schemas
from ..database import get_db

router = APIRouter(
    prefix="/api/auth",
    tags=["authentication"],
)


@router.post("/onboarding", response_model=schemas.OnboardingResponse, status_code=201)
def onboard_new_organization(
    onboarding: schemas.OnboardingRequest,
    db: Session = Depends(get_db)
):
    """
    Create a new organization with an owner user.
    This is the first step for new businesses.
    """
    existing_user = crud.get_user_by_username(db, username=onboarding.username)
    if existing_user:
        raise HTTPException(
            status_code=400,
            detail="Username already registered"
        )
    
    hashed_password = auth.get_password_hash(onboarding.password)
    org_create = schemas.OrganizationCreate(name=onboarding.organization_name)
    db_org = crud.create_organization(db, org=org_create, owner_id=None)
    
    owner_user = crud.create_user(
        db=db,
        user=schemas.UserCreate(
            username=onboarding.username,
            password=onboarding.password,
            role=models.UserRole.owner,
            organization_id=db_org.id
        ),
        hashed_password=hashed_password
    )
    
    db_org.owner_id = owner_user.id
    db.add(db_org)
    db.commit()
    db.refresh(db_org)
    db.refresh(owner_user)
    
    access_token_expires = timedelta(minutes=auth.settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        data={
            "sub": owner_user.username,
            "organization_id": db_org.id,
            "role": owner_user.role.value
        },
        expires_delta=access_token_expires
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "organization": db_org,
        "user": owner_user
    }


@router.post("/token", response_model=schemas.Token)
def login_for_access_token(
    db: Session = Depends(get_db),
    form_data: OAuth2PasswordRequestForm = Depends()
):
    """
    OAuth2 compatible token login endpoint.
    Returns JWT token with organization_id embedded.
    """
    user = crud.get_user_by_username(db, username=form_data.username)
    if not user or not auth.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user"
        )
    
    if not user.organization_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User not associated with any organization"
        )
    
    access_token_expires = timedelta(minutes=auth.settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        data={
            "sub": user.username,
            "organization_id": user.organization_id,
            "role": user.role.value
        },
        expires_delta=access_token_expires
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "organization_id": user.organization_id,
        "role": user.role.value
    }


@router.get("/me", response_model=schemas.User)
def read_current_user(
    current_user: models.User = Depends(auth.get_current_active_user)
):
    """Get current authenticated user"""
    return current_user
