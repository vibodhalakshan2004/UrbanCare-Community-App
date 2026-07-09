from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from app.utils.jwt_handler import verify_token

security = HTTPBearer()


class CurrentUser:
    def __init__(self, payload: dict):
        self.user_id = payload["user_id"]
        self.role = payload["role"]

    def to_dict(self):
        return {
            "user_id": self.user_id,
            "role": self.role
        }


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
):
    token = credentials.credentials
    payload = verify_token(token)

    if payload is None:
        raise HTTPException(
            status_code=401,
            detail="Invalid or expired token"
        )

    return CurrentUser(payload).to_dict()


def require_role(required_role: str):
    def role_checker(user=Depends(get_current_user)):
        if user["role"] != required_role:
            raise HTTPException(status_code=403, detail="Access denied")
        return user

    return role_checker