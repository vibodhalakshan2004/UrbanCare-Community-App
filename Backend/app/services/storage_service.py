import json
import os
import urllib.error
import urllib.parse
import urllib.request
from uuid import uuid4

from fastapi import HTTPException


class StorageService:
    def __init__(self):
        self.supabase_url = os.getenv("SUPABASE_URL", "").rstrip("/")
        self.supabase_service_role_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
        self.bucket = os.getenv("SUPABASE_STORAGE_BUCKET", "complaints")
        self.base_folder = os.getenv("SUPABASE_COMPLAINT_FOLDER", "complaints").strip("/")

    def _validate_config(self):
        if not self.supabase_url or not self.supabase_service_role_key:
            raise HTTPException(
                status_code=500,
                detail="Supabase storage is not configured on backend"
            )

    def _parse_storage_locator(self, image_url: str):
        if not image_url or not image_url.startswith("supabase://"):
            return None

        locator = image_url[len("supabase://"):]
        if "/" not in locator:
            return None

        bucket, object_path = locator.split("/", 1)
        if not bucket or not object_path:
            return None

        return bucket, object_path

    def resolve_display_url(self, image_url: str, expires_in: int = 3600) -> str | None:
        if not image_url:
            return None

        if image_url.startswith("http://") or image_url.startswith("https://"):
            return image_url

        locator = self._parse_storage_locator(image_url)
        if not locator:
            return None

        if not self.supabase_url or not self.supabase_service_role_key:
            return None

        bucket, object_path = locator
        encoded_path = urllib.parse.quote(object_path, safe="/")
        sign_url = f"{self.supabase_url}/storage/v1/object/sign/{bucket}/{encoded_path}"

        body = json.dumps({"expiresIn": expires_in}).encode("utf-8")
        req = urllib.request.Request(
            sign_url,
            data=body,
            method="POST",
            headers={
                "Authorization": f"Bearer {self.supabase_service_role_key}",
                "apikey": self.supabase_service_role_key,
                "Content-Type": "application/json",
            },
        )

        try:
            with urllib.request.urlopen(req, timeout=30) as response:
                payload = json.loads(response.read().decode("utf-8"))

            signed = (
                payload.get("signedURL")
                or payload.get("signedUrl")
                or payload.get("url")
            )
            if not signed:
                return None

            if signed.startswith("http://") or signed.startswith("https://"):
                return signed

            normalized_path = signed.lstrip("/")
            # Supabase may return paths like /object/sign/... that still need /storage/v1 prefix.
            if not normalized_path.startswith("storage/v1/"):
                normalized_path = f"storage/v1/{normalized_path}"

            return f"{self.supabase_url}/{normalized_path}"
        except Exception:
            return None

    def _infer_image_content_type(self, filename: str, content_type: str, file_bytes: bytes) -> str | None:
        normalized = (content_type or "").strip().lower()
        if normalized.startswith("image/"):
            return normalized

        ext = ""
        if "." in (filename or ""):
            ext = filename.rsplit(".", 1)[-1].lower()

        ext_map = {
            "jpg": "image/jpeg",
            "jpeg": "image/jpeg",
            "png": "image/png",
            "gif": "image/gif",
            "webp": "image/webp",
            "bmp": "image/bmp",
            "heic": "image/heic",
            "heif": "image/heif",
        }
        if ext in ext_map:
            return ext_map[ext]

        # Last-resort signature checks for common image formats.
        if file_bytes.startswith(b"\xff\xd8\xff"):
            return "image/jpeg"
        if file_bytes.startswith(b"\x89PNG\r\n\x1a\n"):
            return "image/png"
        if file_bytes.startswith((b"GIF87a", b"GIF89a")):
            return "image/gif"
        if len(file_bytes) >= 12 and file_bytes[:4] == b"RIFF" and file_bytes[8:12] == b"WEBP":
            return "image/webp"

        return None

    def upload_complaint_image(self, user_id: str, filename: str, content_type: str, file_bytes: bytes):
        self._validate_config()

        resolved_content_type = self._infer_image_content_type(filename, content_type, file_bytes)
        if not resolved_content_type:
            raise HTTPException(status_code=400, detail="Only image files are allowed")

        ext = "jpg"
        if "." in filename:
            ext = filename.rsplit(".", 1)[-1].lower()

        object_name = f"{uuid4()}.{ext}"
        object_path = f"{self.base_folder}/{user_id}/{object_name}"

        encoded_path = urllib.parse.quote(object_path, safe="/")
        upload_url = f"{self.supabase_url}/storage/v1/object/{self.bucket}/{encoded_path}"

        req = urllib.request.Request(
            upload_url,
            data=file_bytes,
            method="POST",
            headers={
                "Authorization": f"Bearer {self.supabase_service_role_key}",
                "apikey": self.supabase_service_role_key,
                "Content-Type": resolved_content_type,
                "x-upsert": "false",
            },
        )

        try:
            with urllib.request.urlopen(req, timeout=30) as response:
                _ = response.read()
        except urllib.error.HTTPError as e:
            body = e.read().decode("utf-8", errors="ignore") if e.fp else ""
            detail = "Failed to upload image to storage"
            if body:
                try:
                    payload = json.loads(body)
                    detail = payload.get("message") or payload.get("error") or detail
                except Exception:
                    detail = body
            raise HTTPException(status_code=502, detail=detail)
        except Exception:
            raise HTTPException(status_code=502, detail="Failed to upload image to storage")

        # Keep storage private: store a stable storage locator in DB.
        image_url = f"supabase://{self.bucket}/{object_path}"
        return {
            "image_url": image_url,
            "object_path": object_path,
        }
