from passlib.context import CryptContext

pwd_context = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto"
)

def _bcrypt_safe(password: str) -> str:
   
    return password.encode("utf-8")[:72].decode("utf-8", "ignore")

def hash_password(password: str) -> str:
    password = _bcrypt_safe(password)
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    plain_password = _bcrypt_safe(plain_password)
    return pwd_context.verify(plain_password, hashed_password)