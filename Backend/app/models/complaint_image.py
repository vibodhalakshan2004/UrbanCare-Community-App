# Import SQLAlchemy column tools
from sqlalchemy import Column, String, ForeignKey

# PostgreSQL UUID type
from sqlalchemy.dialects.postgresql import UUID

# Python UUID generator
import uuid

# Base model class for SQLAlchemy
from app.database import Base


# ComplaintImage model represents the "complaint_images" table
class ComplaintImage(Base):

    # Table name in the database
    __tablename__ = "complaint_images"

    # Primary key of the table
    # Each image gets a unique UUID automatically
    image_id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4
    )

    # Foreign key linking this image to a complaint
    # complaint_images.complaint_id → complaints.complaint_id
    complaint_id = Column(
        UUID(as_uuid=True),
        ForeignKey("complaints.complaint_id"),
        nullable=False
    )

    # Type of image stored
    # Examples:
    # complaint = original complaint photo
    # verification = citizen verification photo
    # repair = authority repair proof
    image_type = Column(
        String(20),
        nullable=False,
        default="complaint"
    )

    # URL of the image stored in Firebase or another cloud storage
    image_url = Column(
        String(500),
        nullable=False
    )