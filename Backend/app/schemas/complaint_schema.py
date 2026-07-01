# Import BaseModel from Pydantic
# Used to define request and response schemas
from pydantic import BaseModel

# UUID type for complaint and location IDs
from uuid import UUID

# Optional fields and list support
from typing import Optional, List


# ---------------------------------------------------------
# LOCATION INPUT SCHEMA
# ---------------------------------------------------------
# Used when creating a complaint to specify location data
class LocationCreate(BaseModel):

    # Latitude of the complaint location
    latitude: float

    # Longitude of the complaint location
    longitude: float

    # Optional street address
    address: Optional[str] = None

    # Optional city name
    city: Optional[str] = None

    # Optional district name
    district: Optional[str] = None


# ---------------------------------------------------------
# COMPLAINT CREATION SCHEMA
# ---------------------------------------------------------
# Used when a user submits a new complaint
class ComplaintCreate(BaseModel):

    # Type of issue (pothole, garbage, streetlight etc.)
    issue_type: str

    # Title of the complaint
    title: str

    # Detailed description of the problem
    description: str

    # Priority level (default = medium)
    priority: Optional[str] = "medium"

    # Nested location object
    location: LocationCreate

    # Optional list of image URLs
    image_urls: Optional[List[str]] = []


# ---------------------------------------------------------
# COMPLAINT RESPONSE SCHEMA
# ---------------------------------------------------------
# Used when returning complaint data to the client
class ComplaintResponse(BaseModel):

    # Unique complaint ID
    complaint_id: UUID

    # Location ID associated with complaint
    location_id: UUID

    # Issue category
    issue_type: str

    # Complaint title
    title: str

    # Complaint description
    description: str

    # Current status (pending, fixed etc.)
    status: str

    # Priority level
    priority: str

    # Number of users who confirmed the issue is fixed
    verification_count: int

    # Number of users who reported issue still exists
    not_fixed_count: int

    # Allow SQLAlchemy models to convert automatically
    class Config:
        from_attributes = True