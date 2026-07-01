# Import SQLAlchemy column types
from sqlalchemy import Column, Boolean, ForeignKey, DateTime

# PostgreSQL UUID type
from sqlalchemy.dialects.postgresql import UUID

# SQL functions such as NOW()
from sqlalchemy.sql import func

# Python UUID generator
import uuid

# Base class for SQLAlchemy models
from app.database import Base


# Model representing the complaint_confirmations table
class ComplaintVerification(Base):

    # Name of the table in PostgreSQL
    __tablename__ = "complaint_confirmations"

    # Primary key of the confirmation record
    # Automatically generates a UUID
    confirmation_id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4
    )

    # Reference to the complaint being verified
    # complaint_confirmations.complaint_id → complaints.complaint_id
    complaint_id = Column(
        UUID(as_uuid=True),
        ForeignKey("complaints.complaint_id")
    )

    # Citizen who submitted the verification
    # complaint_confirmations.citizen_id → citizens.user_id
    citizen_id = Column(
        UUID(as_uuid=True),
        ForeignKey("citizens.user_id")
    )

    # Result of verification
    # True = issue is fixed
    # False = issue still exists
    is_fixed = Column(
        Boolean,
        nullable=False
    )

    # Timestamp when the verification was submitted
    confirmed_at = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )