from fastapi import HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import or_

from app.models.user import User
from app.models.citizen import Citizen
from app.schemas.user_schema import UserSignup, UserLogin
from app.utils.password import hash_password, verify_password
from app.utils.jwt_handler import create_access_token


# --------------------------------------------------
# CREATE USER (SIGNUP)
# --------------------------------------------------
def create_user(db: Session, user_data: UserSignup):

    # Check if email or phone already exists
    existing_user = db.query(User).filter(
        or_(
            User.email == user_data.email,
            User.phone_number == user_data.phone_number
        )
    ).first()

    if existing_user:
        raise HTTPException(
            status_code=400,
            detail="Email or phone already registered"
        )

    # Hash password
    hashed_password = hash_password(user_data.password)

    # Create new user
    new_user = User(
        name=user_data.name,
        email=user_data.email,
        phone_number=user_data.phone_number,
        password_hash=hashed_password,
        role=user_data.role
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    # If user role is citizen, create a corresponding citizen record
    if user_data.role == "citizen":
        citizen = Citizen(
            user_id=new_user.user_id
        )
        db.add(citizen)
        db.commit()

    return new_user


# --------------------------------------------------
# AUTHENTICATE USER
# --------------------------------------------------
def authenticate_user(db: Session, login_data: UserLogin):

    # Allow login using email OR phone
    user = db.query(User).filter(
        or_(
            User.email == login_data.email,
            User.phone_number == login_data.email
        )
    ).first()

    if user is None:
        return None

    # Verify password
    if not verify_password(login_data.password, user.password_hash):
        return None

    return user


# --------------------------------------------------
# LOGIN USER
# --------------------------------------------------
def login_user(db: Session, login_data: UserLogin):

    user = authenticate_user(db, login_data)

    if not user:
        return None

    # Create JWT token
    token = create_access_token({
        "user_id": str(user.user_id),
        "role": user.role
    })

    return token