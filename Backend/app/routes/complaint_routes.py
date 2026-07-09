# Import FastAPI utilities
# APIRouter groups related endpoints
# Depends injects dependencies like database or authentication
# HTTPException is used for API error responses
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File

# SQLAlchemy database session
from sqlalchemy.orm import Session

# Used to return lists of objects
from typing import List

# UUID type for complaint IDs
from uuid import UUID


# Import database session dependency
from app.database import get_db

# Import schemas for request and response validation
from app.schemas.complaint_schema import ComplaintCreate, ComplaintResponse, ComplaintImageUploadResponse

# Import service classes that contain business logic
from app.services.complaint_service import ComplaintService
from app.services.complaint_verification_service import ComplaintVerificationService
from app.services.storage_service import StorageService

# Import authentication dependency
# This extracts the logged-in user from the JWT token
from app.dependencies.auth_dependency import get_current_user


# Create router object
# prefix="/complaints" means all endpoints start with /complaints
# tags=["Complaints"] groups them in Swagger docs
router = APIRouter(
    prefix="/complaints",
    tags=["Complaints"]
)


@router.post("/upload-image", response_model=ComplaintImageUploadResponse)
async def upload_complaint_image(
    image: UploadFile = File(...),
    user=Depends(get_current_user),
):
    file_bytes = await image.read()
    if not file_bytes:
        raise HTTPException(status_code=400, detail="Uploaded file is empty")

    service = StorageService()
    return service.upload_complaint_image(
        user_id=user["user_id"],
        filename=image.filename or "image.jpg",
        content_type=image.content_type or "application/octet-stream",
        file_bytes=file_bytes,
    )


# ------------------------------------------------------
# CREATE COMPLAINT
# ------------------------------------------------------
# Endpoint: POST /complaints
# Creates a new complaint
@router.post("/", response_model=ComplaintResponse)
def create_complaint(

    # Complaint data from request body
    data: ComplaintCreate,

    # Extract authenticated user from JWT
    user = Depends(get_current_user),

    # Inject database session
    db: Session = Depends(get_db)
):

    # Create complaint service object
    service = ComplaintService(db)

    # Call service to create complaint
    # user["user_id"] comes from decoded JWT
    return service.create_complaint(data, user["user_id"])


# ------------------------------------------------------
# GET ALL COMPLAINTS
# ------------------------------------------------------
# Endpoint: GET /complaints
# Returns all visible complaints
@router.get("/", response_model=List[ComplaintResponse])
def get_all_complaints(
    user = Depends(get_current_user),
    db: Session = Depends(get_db)
):

    # Create complaint service
    service = ComplaintService(db)

    # Get complaints
    complaints = service.get_all_complaints(citizen_id=user["user_id"])
    
    # Convert to response models with explicit location serialization
    responses = []
    for complaint in complaints:
        response = ComplaintResponse.model_validate(complaint)
        responses.append(response)
    
    return responses


# ------------------------------------------------------
# GET MY COMPLAINTS
# ------------------------------------------------------
# Endpoint: GET /complaints/my
# Returns only the logged-in citizen's own complaints
@router.get("/my", response_model=List[ComplaintResponse])
def get_my_complaints(
    user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    service = ComplaintService(db)
    return service.get_my_complaints(citizen_id=user["user_id"])


# ------------------------------------------------------
# GET SINGLE COMPLAINT
# ------------------------------------------------------
# Endpoint: GET /complaints/{complaint_id}
# Returns one complaint
@router.get("/{complaint_id}", response_model=ComplaintResponse)
def get_complaint(

    # Complaint ID from URL path
    complaint_id: UUID,

    user = Depends(get_current_user),

    # Database session
    db: Session = Depends(get_db)
):

    service = ComplaintService(db)

    # Fetch complaint
    complaint = service.get_complaint_by_id(complaint_id, citizen_id=user["user_id"])

    # If complaint does not exist
    if not complaint:
        raise HTTPException(
            status_code=404,
            detail="Complaint not found"
        )

    # Convert to response model with explicit location serialization
    return ComplaintResponse.model_validate(complaint)


# ------------------------------------------------------
# VERIFY COMPLAINT
# ------------------------------------------------------
# Endpoint: POST /complaints/{complaint_id}/verify
# Citizens confirm whether issue is fixed
@router.post("/{complaint_id}/verify")
def verify_complaint(

    # Complaint ID from URL
    complaint_id: UUID,

    # Whether the issue is fixed
    is_fixed: bool,

    # Optional detailed selection on client
    feedback_type: str | None = None,

    # Authenticated user from JWT
    user = Depends(get_current_user),

    # Database session
    db: Session = Depends(get_db)
):

    # Create verification service
    service = ComplaintVerificationService(db)

    # Perform verification logic
    return service.verify_complaint(
        complaint_id,
        user["user_id"],  # extracted from JWT
        is_fixed,
        feedback_type,
    )