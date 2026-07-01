# Import FastAPI tools
# APIRouter -> used to group related endpoints
# Depends -> used for dependency injection (like database connection)
from fastapi import APIRouter, Depends

# SQLAlchemy session for database operations
from sqlalchemy.orm import Session

# Used to specify response type as a list
from typing import List

# Import the function that gives a database session
from app.database import get_db

# Import the service that contains geofence logic
from app.services.geofence_service import GeofenceService

# Import the response schema
from app.schemas.geofence_schema import NearbyComplaint


# Create a router object
# prefix="/geofence" means all routes start with /geofence
# tags=["Geofence"] groups this endpoint in Swagger docs
router = APIRouter(
    prefix="/geofence",
    tags=["Geofence"]
)


# Endpoint to get nearby complaints
# Example URL:
# /geofence/nearby?lat=6.9271&lng=79.8612
@router.get(
    "/nearby",
    response_model=List[NearbyComplaint]  # response must match this schema
)
def nearby_damage(

    # Latitude of user location
    lat: float,

    # Longitude of user location
    lng: float,

    # Search radius in meters (default = 5000m)
    radius_m: int = 5000,

    # Maximum number of complaints returned
    limit: int = 50,

    # Database session injected automatically
    db: Session = Depends(get_db)
):

    # Create the geofence service object
    service = GeofenceService(db)

    # Call the service method to get nearby complaints
    complaints = service.get_nearby_complaints(
        lat,
        lng,
        radius_m,
        limit
    )

    # Return the result to the client
    return complaints