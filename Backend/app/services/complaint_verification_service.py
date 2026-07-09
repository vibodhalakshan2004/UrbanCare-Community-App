# Import SQLAlchemy database session
from sqlalchemy.orm import Session
from sqlalchemy import text

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
    VALID_FEEDBACK_TYPES = {"fixed", "still_there", "got_worse"}

    # Constructor receives database session
    def __init__(self, db: Session):
        self.db = db

    def _ensure_feedback_type_column(self):
        self.db.execute(
            text(
                """
                ALTER TABLE complaint_confirmations
                ADD COLUMN IF NOT EXISTS feedback_type VARCHAR(20)
                """
            )
        )

    def _normalize_feedback_type(self, is_fixed: bool, feedback_type: str | None) -> str:
        if is_fixed:
            return "fixed"

        normalized = (feedback_type or "still_there").strip().lower()
        if normalized not in self.VALID_FEEDBACK_TYPES:
            raise HTTPException(status_code=400, detail="Invalid feedback_type")
        if normalized == "fixed":
            raise HTTPException(status_code=400, detail="feedback_type=fixed requires is_fixed=true")
        return normalized


    # --------------------------------------------------------
    # VERIFY COMPLAINT
    # --------------------------------------------------------
    def verify_complaint(self, complaint_id, citizen_id, is_fixed, feedback_type=None):
        self._ensure_feedback_type_column()
        feedback_type = self._normalize_feedback_type(is_fixed, feedback_type)

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

        # If user already voted, allow updates instead of rejecting.
        if existing_verification:
            previous_is_fixed = bool(existing_verification.is_fixed)
            previous_feedback_type = (
                (existing_verification.feedback_type or "").strip().lower()
                if existing_verification.feedback_type
                else ("fixed" if previous_is_fixed else "still_there")
            )

            # Adjust counters only when moving between fixed and not-fixed.
            if previous_is_fixed != is_fixed:
                if previous_is_fixed:
                    complaint.verification_count = max(0, complaint.verification_count - 1)
                    complaint.not_fixed_count += 1
                else:
                    complaint.not_fixed_count = max(0, complaint.not_fixed_count - 1)
                    complaint.verification_count += 1

            existing_verification.is_fixed = is_fixed
            existing_verification.feedback_type = feedback_type

            # Nothing changed for counters/status when only non-fixed subtype changed.
            if previous_is_fixed == is_fixed and previous_feedback_type == feedback_type:
                self.db.refresh(complaint)
                complaint.my_verification = existing_verification.is_fixed
                complaint.my_feedback_type = existing_verification.feedback_type
                return complaint

        else:
            # ----------------------------------------------------
            # Step 4: Create verification record
            # ----------------------------------------------------
            verification = ComplaintVerification(
                complaint_id=complaint_id,
                citizen_id=citizen_id,
                is_fixed=is_fixed,
                feedback_type=feedback_type,
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
        complaint.my_verification = is_fixed
        complaint.my_feedback_type = feedback_type

        # Return updated complaint
        return complaint