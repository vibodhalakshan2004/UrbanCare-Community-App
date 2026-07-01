# Import SQLAlchemy database session
from sqlalchemy.orm import Session

# Import HTTPException to return API errors
from fastapi import HTTPException

# Import database models
from app.models.complaint import Complaint
from app.models.complaint_verification import ComplaintVerification


# Service class responsible for complaint verification logic
class ComplaintVerificationService:

    # Number of confirmations needed to mark complaint as fixed
    FIX_THRESHOLD = 5

    # Number of "not fixed" votes needed to reopen complaint
    REOPEN_THRESHOLD = 5

    # Constructor receives database session
    def __init__(self, db: Session):
        self.db = db


    # --------------------------------------------------------
    # VERIFY COMPLAINT
    # --------------------------------------------------------
    def verify_complaint(self, complaint_id, citizen_id, is_fixed):

        # Step 1: Find complaint in database
        complaint = (
            self.db.query(Complaint)
            .filter(Complaint.complaint_id == complaint_id)
            .first()
        )

        # If complaint does not exist
        if not complaint:
            raise HTTPException(
                status_code=404,
                detail="Complaint not found"
            )

        # Step 2: If complaint already hidden (already fixed)
        if complaint.is_hidden:
            raise HTTPException(
                status_code=400,
                detail="Complaint already closed"
            )

        # ----------------------------------------------------
        # Step 3: Check if this user already verified
        # ----------------------------------------------------
        existing_verification = (
            self.db.query(ComplaintVerification)
            .filter(
                ComplaintVerification.complaint_id == complaint_id,
                ComplaintVerification.citizen_id == citizen_id
            )
            .first()
        )

        # If user already voted
        if existing_verification:
            raise HTTPException(
                status_code=400,
                detail="User already verified this complaint"
            )

        # ----------------------------------------------------
        # Step 4: Create verification record
        # ----------------------------------------------------
        verification = ComplaintVerification(
            complaint_id=complaint_id,
            citizen_id=citizen_id,
            is_fixed=is_fixed
        )

        # Add verification to database
        self.db.add(verification)

        # ----------------------------------------------------
        # Step 5: Update verification counters
        # ----------------------------------------------------
        if is_fixed:

            # Increase fixed confirmation count
            complaint.verification_count += 1

        else:

            # Increase not-fixed counter
            complaint.not_fixed_count += 1


        # ----------------------------------------------------
        # Step 6: Check if complaint should be closed
        # ----------------------------------------------------
        if complaint.verification_count >= self.FIX_THRESHOLD:

            # Mark complaint as fixed
            complaint.status = "fixed"

            # Hide complaint from geofence search
            complaint.is_hidden = True


        # ----------------------------------------------------
        # Step 7: Check if complaint should reopen
        # ----------------------------------------------------
        elif complaint.not_fixed_count >= self.REOPEN_THRESHOLD:

            # Change status back to pending
            complaint.status = "pending"

            # Reset counters
            complaint.verification_count = 0
            complaint.not_fixed_count = 0


        # ----------------------------------------------------
        # Step 8: Save changes
        # ----------------------------------------------------
        self.db.commit()

        # Refresh complaint object from database
        self.db.refresh(complaint)

        # Return updated complaint
        return complaint