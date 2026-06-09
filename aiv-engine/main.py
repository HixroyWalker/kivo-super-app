from fastapi import FastAPI, UploadFile, File, Header, HTTPException
from pydantic import BaseModel
import easyocr
import cv2
import numpy as np
import base64
from deepface import DeepFace
import os

app = FastAPI()
reader = easyocr.Reader(['en'])

class KYCVerifyRequest(BaseModel):
    selfie_b64: str
    id_b64: str
    expected_name: str

@app.post("/verify")
async def verify_kyc(req: KYCVerifyRequest, x_aiv_secret: str = Header(None)):
    if x_aiv_secret != os.getenv("AIV_SHARED_SECRET"):
        raise HTTPException(status_code=403, detail="Invalid secret")

    # Decode images
    selfie_bytes = base64.b64decode(req.selfie_b64)
    id_bytes = base64.b64decode(req.id_b64)

    nparr_selfie = np.frombuffer(selfie_bytes, np.uint8)
    nparr_id = np.frombuffer(id_bytes, np.uint8)

    img_selfie = cv2.imdecode(nparr_selfie, cv2.IMREAD_COLOR)
    img_id = cv2.imdecode(nparr_id, cv2.IMREAD_COLOR)

    # 1. OCR Name Extraction
    ocr_results = reader.readtext(img_id)
    extracted_text = " ".join([res[1] for res in ocr_results])
    
    # Simple name matching logic (Levenshtein would be better)
    name_match = req.expected_name.lower() in extracted_text.lower()

    # 2. Face Matching
    try:
        result = DeepFace.verify(img_selfie, img_id, model_name="Facenet512", detector_backend="opencv")
        face_match = result["verified"]
        confidence = result["distance"]
    except Exception as e:
        face_match = False
        confidence = 1.0

    return {
        "face_match": face_match,
        "face_distance": confidence,
        "name_match": name_match,
        "extracted_text": extracted_text,
        "verdict": "APPROVED" if face_match and name_match else "MANUAL_REVIEW"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
