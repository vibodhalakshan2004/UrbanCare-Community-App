# Import SQLAlchemy database session type
from sqlalchemy.orm import Session

# Import text() to run raw SQL queries
from sqlalchemy import text

# Import database models
from app.models.location import Location
from app.models.complaint import Complaint
from app.models.complaint_image import ComplaintImage


# Service class that contains complaint-related business logic
class ComplaintService:

    # Constructor receives database session
    def __init__(self, db: Session):
        self.db = db

    # ---------------------------------------------------------
    # CREATE A NEW COMPLAINT
    # ---------------------------------------------------------
    def create_complaint(self, data, citizen_id):

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
        return complaint


    # ---------------------------------------------------------
    # GET ALL VISIBLE COMPLAINTS
    # ---------------------------------------------------------
    def get_all_complaints(self):

        # Query complaints that are not hidden
        return (
            self.db.query(Complaint)
            .filter(Complaint.is_hidden == False)
            .all()
        )


    # ---------------------------------------------------------
    # GET COMPLAINT BY ID
    # ---------------------------------------------------------
    def get_complaint_by_id(self, complaint_id):

        # Query complaint by ID but exclude hidden complaints
        return (
            self.db.query(Complaint)
            .filter(
                Complaint.complaint_id == complaint_id,
                Complaint.is_hidden == False
            )
            .first()
        )