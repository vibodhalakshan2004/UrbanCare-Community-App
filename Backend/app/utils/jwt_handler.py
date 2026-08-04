from jose import jwt, JWTError
from datetime import datetime, timedelta
from dotenv import load_dotenv
import os

load_dotenv()

SECRET_KEY = os.getenv("JWT_SECRET")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_HOURS = 24


class JwtHandler:
    @staticmethod
    def create_access_token(data: dict):
        payload = data.copy()
        payload["exp"] = datetime.utcnow() + timedelta(hours=ACCESS_TOKEN_EXPIRE_HOURS)

        return jwt.encode(
            payload,
            SECRET_KEY,
            algorithm=ALGORITHM
        )

    @staticmethod
    def verify_token(token: str):
        try:
            return jwt.decode(
                token,
                SECRET_KEY,
                algorithms=[ALGORITHM]
            )
        except JWTError:
            return None


def create_access_token(data: dict):
    return JwtHandler.create_access_token(data)


def verify_token(token: str):
    return JwtHandler.verify_token(token)