# Import SQLAlchemy database session type
from sqlalchemy.orm import Session, joinedload

# Import text() to run raw SQL queries
from sqlalchemy import text

# Import UUID for type conversion
from uuid import UUID

# Import database models
from app.models.location import Location
from app.models.complaint import Complaint
from app.models.complaint_image import ComplaintImage
from app.models.complaint_verification import ComplaintVerification
from app.services.storage_service import StorageService


# Service class that contains complaint-related business logic
class ComplaintService:

    # Constructor receives database session
    def __init__(self, db: Session):
        self.db = db
        self.storage = StorageService()

    def _attach_image_payload(self, complaint, citizen_id=None):
        if complaint is None:
            return None

        images = (
            self.db.query(ComplaintImage)
            .filter(ComplaintImage.complaint_id == complaint.complaint_id)
            .all()
        )
        image_urls = []
        for img in images:
            if not img.image_url:
                continue

            resolved = self.storage.resolve_display_url(img.image_url)
            if resolved:
                image_urls.append(resolved)

        # Dynamic attributes are consumed by Pydantic response model (from_attributes).
        complaint.image_urls = image_urls
        complaint.primary_image_url = image_urls[0] if image_urls else None

        # Ensure location is loaded for Pydantic serialization
        if complaint.location_id:
            location = (
                self.db.query(Location)
                .filter(Location.location_id == complaint.location_id)
                .first()
            )
            if location:
                complaint.location = location

        complaint.my_verification = None
        complaint.my_feedback_type = None
        if citizen_id:
            verification = (
                self.db.query(ComplaintVerification)
                .filter(
                    ComplaintVerification.complaint_id == complaint.complaint_id,
                    ComplaintVerification.citizen_id == citizen_id,
                )
                .first()
            )
            if verification:
                complaint.my_verification = bool(verification.is_fixed)
                if verification.feedback_type:
                    complaint.my_feedback_type = verification.feedback_type
                else:
                    complaint.my_feedback_type = "fixed" if verification.is_fixed else "still_there"

        return complaint

    # ---------------------------------------------------------
    # CREATE A NEW COMPLAINT
    # ---------------------------------------------------------
    def create_complaint(self, data, citizen_id):
        
        # Convert citizen_id string to UUID (comes from JWT token as string)
        if isinstance(citizen_id, str):
            citizen_id = UUID(citizen_id)

        # Step 1: Create a location object
        location = Location(
            latitude=data.location.latitude,
            longitude=data.location.longitude,
            address=data.location.address,
            city=data.location.city,
            district=data.location.district
        )

        # Save location to database
        self.db.add(location)

        # Flush sends the insert to DB but does not commit yet
        # This allows us to get location_id immediately
        self.db.flush()

        # -----------------------------------------------------
        # Step 2: Update the PostGIS spatial column (geog)
        # -----------------------------------------------------
        self.db.execute(
            text("""
                UPDATE locations
                SET geog = ST_SetSRID(
                    ST_MakePoint(:lng, :lat), 4326
                )::geography
                WHERE location_id = :location_id
            """),
            {
                "lng": data.location.longitude,
                "lat": data.location.latitude,
                "location_id": location.location_id
            }
        )

        # -----------------------------------------------------
        # Step 3: Create complaint record
        # -----------------------------------------------------
        complaint = Complaint(
            citizen_id=citizen_id,
            location_id=location.location_id,
            issue_type=data.issue_type,
            title=data.title,
            description=data.description,
            status="created",
            priority=data.priority
        )

        # Add complaint to session
        self.db.add(complaint)

        # Flush again to obtain complaint_id
        self.db.flush()

        # -----------------------------------------------------
        # Step 4: Save complaint images
        # -----------------------------------------------------
        if data.image_urls:
            for url in data.image_urls:

                # Create image record
                image = ComplaintImage(
                    complaint_id=complaint.complaint_id,
                    image_url=url
                )

                # Add image to database
                self.db.add(image)

        # -----------------------------------------------------
        # Step 5: Commit transaction
        # -----------------------------------------------------
        self.db.commit()

        # Refresh complaint object with latest DB data
        self.db.refresh(complaint)

        # Return created complaint
        return self._attach_image_payload(complaint)


    # ---------------------------------------------------------
    # GET ALL VISIBLE COMPLAINTS
    # ---------------------------------------------------------
    def get_all_complaints(self, citizen_id=None):

        # Query complaints that are not hidden, with eager loading of location
        complaints = (
            self.db.query(Complaint)
            .options(joinedload(Complaint.location))
            .filter(Complaint.is_hidden == False)
            .all()
        )

        return [self._attach_image_payload(complaint, citizen_id=citizen_id) for complaint in complaints]


    # ---------------------------------------------------------
    # GET COMPLAINT BY ID
    # ---------------------------------------------------------
    def get_complaint_by_id(self, complaint_id, citizen_id=None):

        # Query complaint by ID but exclude hidden complaints, with eager loading of location
        complaint = (
            self.db.query(Complaint)
            .options(joinedload(Complaint.location))
            .filter(
                Complaint.complaint_id == complaint_id,
                Complaint.is_hidden == False
            )
            .first()
        )

        return self._attach_image_payload(complaint, citizen_id=citizen_id)


    # ---------------------------------------------------------
    # GET COMPLAINTS BY LOGGED-IN CITIZEN
    # ---------------------------------------------------------
    def get_my_complaints(self, citizen_id):
        if isinstance(citizen_id, str):
            citizen_id = UUID(citizen_id)

        complaints = (
            self.db.query(Complaint)
            .options(joinedload(Complaint.location))
            .filter(Complaint.citizen_id == citizen_id)
            .order_by(Complaint.created_at.desc())
            .all()
        )

        return [self._attach_image_payload(c, citizen_id=citizen_id) for c in complaints]