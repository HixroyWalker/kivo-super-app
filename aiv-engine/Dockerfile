# Use Python 3.12
FROM python:3.12-slim

# Install system dependencies for OpenCV and DeepFace
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Pre-download and cache model weights during Docker image build
ENV EASYOCR_DOWNLOAD_PATH=/root/.EasyOCR
RUN python -c "import easyocr; easyocr.Reader(['en'])"
RUN python -c "from deepface import DeepFace; DeepFace.build_model('Facenet512')"

# Copy source code
COPY . .

# Expose port
EXPOSE 8090

# Start the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8090"]
