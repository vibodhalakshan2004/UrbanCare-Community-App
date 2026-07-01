# Import SQLAlchemy column types
from sqlalchemy import Column, String, Text, ForeignKey, DateTime, Integer, Boolean

# PostgreSQL UUID type
from sqlalchemy.dialects.postgresql import UUID

# SQL functions (used for timestamps)
from sqlalchemy.sql import func

# Python library for generating UUIDs
import uuid

# Base class for all SQLAlchemy models
from app.database import Base


# Complaint model represents the "complaints" table in PostgreSQL
class Complaint(Base):

    # Name of the table
    __tablename__ = "complaints"

    # Primary key of the complaint
    # UUID is automatically generated when a new complaint is created
    complaint_id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4
    )

    # User who reported the complaint
    # This connects to users.user_id
    citizen_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.user_id"),
        nullable=False
    )

    # Location where the problem occurred
    # Connects to locations.location_id
    location_id = Column(
        UUID(as_uuid=True),
        ForeignKey("locations.location_id"),
        nullable=False
    )

    # Type of issue
    # Example: road_damage, garbage, streetlight
    issue_type = Column(String(50), nullable=False)

    # Short title of the complaint
    title = Column(String(150), nullable=False)

    # Detailed description of the issue
    description = Column(Text, nullable=False)

    # Current complaint status
    # Default when created is "pending"
    status = Column(String(30), default="pending")

    # Priority level of the issue
    # low / medium / high
    priority = Column(String(20), default="medium")

    # Number of users who confirmed the issue is fixed
    verification_count = Column(Integer, default=0)

    # Number of users who said the issue is still not fixed
    not_fixed_count = Column(Integer, default=0)

    # Whether the complaint is hidden from public view
    # Admins may hide spam complaints
    is_hidden = Column(Boolean, default=False)

    # Time when the complaint was created
    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )

    # Time when the complaint was last updated
    # Automatically updates whenever the row is modified
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )