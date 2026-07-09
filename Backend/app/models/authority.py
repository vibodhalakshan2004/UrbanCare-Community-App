from sqlalchemy import Column, String, Integer, Float, ForeignKey
from sqlalchemy.dialects.postgresql import UUID

from app.database import Base


class Authority(Base):
    __tablename__ = "authorities"

    authority_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.user_id"),
        primary_key=True
    )

    department_id = Column(
        UUID(as_uuid=True),
        ForeignKey("departments.department_id"),
        nullable=True
    )

    badge_number = Column(String(50), unique=True, nullable=False)

    total_points = Column(Integer, default=0)

    resolved_count = Column(Integer, default=0)

    avg_resolution_hours = Column(Float)

    fcm_token = Column(String)