# Import SQLAlchemy session
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError

# Import HTTPException to return API-safe errors
from fastapi import HTTPException

# Import Complaint model
from app.models.complaint import Complaint


# Function to get the status of a complaint
def get_status(db: Session, complaint_id):

    try:
        # Query the complaints table to find the complaint with the given ID
        complaint = db.query(Complaint).filter(
            Complaint.complaint_id == complaint_id
        ).first()
    except SQLAlchemyError as exc:
        # Roll back in case the session is in a failed transaction state
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="Unable to fetch complaint status right now"
        ) from exc

    # If no complaint is found, return None
    if not complaint:
        return None

    # Return only the complaint status
    return complaint.status