# Import BaseModel from Pydantic
# Used to define request and response schemas
from pydantic import BaseModel, field_serializer

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
# LOCATION RESPONSE SCHEMA
# ---------------------------------------------------------
# Used when returning location data with complaint details
class LocationResponse(BaseModel):

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

    class Config:
        from_attributes = True


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

    # Location data (latitude, longitude, address)
    location: Optional[LocationResponse] = None

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

    # Optional first image URL for convenient display in clients
    primary_image_url: Optional[str] = None

    # All image URLs linked to the complaint
    image_urls: List[str] = []

    # Current authenticated user's latest verification vote for this complaint.
    my_verification: Optional[bool] = None
    my_feedback_type: Optional[str] = None

    # Allow SQLAlchemy models to convert automatically
    class Config:
        from_attributes = True
    
    @field_serializer('location', when_used='json')
    def serialize_location(self, value):
        """Explicitly serialize location field"""
        if value is None:
            return None
        # If it's already a dict or LocationResponse, return as-is
        if isinstance(value, dict):
            return value
        # If it's a SQLAlchemy model, convert to dict
        if hasattr(value, '__dict__'):
            return {
                'latitude': getattr(value, 'latitude', None),
                'longitude': getattr(value, 'longitude', None),
                'address': getattr(value, 'address', None),
                'city': getattr(value, 'city', None),
                'district': getattr(value, 'district', None),
            }
        return value


class ComplaintImageUploadResponse(BaseModel):
    image_url: str
    object_path: str