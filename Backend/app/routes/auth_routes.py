from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.database import get_db
from app.models.user import User
from app.schemas.user_schema import UserSignup, UserLogin, UserResponse, UserUpdate
from app.services.auth_service import create_user, login_user
from app.dependencies.auth_dependency import get_current_user
from app.utils.password import hash_password


router = APIRouter(
    prefix="/auth",
    tags=["Authentication"]
)


@router.post("/signup", response_model=UserResponse)
def signup(user_data: UserSignup, db: Session = Depends(get_db)):

    new_user = create_user(db, user_data)

    return new_user


@router.post("/login")
def login(login_data: UserLogin, db: Session = Depends(get_db)):

    token = login_user(db, login_data)

    if not token:
        raise HTTPException(
            status_code=401,
            detail="Invalid email or password"
        )

    return {
        "access_token": token,
        "token_type": "bearer"
    }


@router.get("/me", response_model=UserResponse)
def get_profile(user=Depends(get_current_user), db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.user_id == user["user_id"]).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
    return db_user


@router.put("/me", response_model=UserResponse)
def update_profile(data: UserUpdate, user=Depends(get_current_user), db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.user_id == user["user_id"]).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    if data.name is not None:
        db_user.name = data.name
    if data.email is not None:
        db_user.email = data.email
    if data.phone_number is not None:
        db_user.phone_number = data.phone_number
    if data.password is not None and data.password.strip():
        db_user.password_hash = hash_password(data.password)

    try:
        db.commit()
        db.refresh(db_user)
        return db_user
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=400, detail="Email or phone number already in use")