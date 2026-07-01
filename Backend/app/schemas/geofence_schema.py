# Import BaseModel from Pydantic
# BaseModel is used to define data schemas for FastAPI
from pydantic import BaseModel

# Import UUID type because complaint IDs are UUIDs
from uuid import UUID

# Optional allows fields to be None (not required)
from typing import Optional


# Schema for a nearby complaint returned by the API
class NearbyComplaint(BaseModel):

    # Unique identifier for the complaint
    complaint_id: UUID

    # Type of issue (garbage, pothole, streetlight, etc.)
    issue_type: str

    # Title of the complaint
    title: str

    # Description of the problem
    description: str

    # Current status of complaint
    # Example: pending, in_progress, fixed
    status: str

    # Priority level
    # Example: low, medium, high
    priority: str

    # Latitude of complaint location
    latitude: float

    # Longitude of complaint location
    longitude: float

    # Street address (optional)
    address: Optional[str] = None

    # City name (optional)
    city: Optional[str] = None

    # District name (optional)
    district: Optional[str] = None

    # Distance from user location in meters
    # Calculated using PostGIS ST_Distance
    distance_m: float