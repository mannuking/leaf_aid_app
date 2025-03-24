from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import google.generativeai as genai
from typing import Optional
import logging
import sys
import os
import json

# Set up more detailed logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

app = FastAPI()

# Enable CORS with more options
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

# Configure Gemini API
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "AIzaSyD1UC4JIFoYyMrsmevjLGq_c4DTW1-CrgM")
if not GEMINI_API_KEY:
    logger.error("GEMINI_API_KEY not set in environment variables")
    sys.exit(1)

genai.configure(api_key=GEMINI_API_KEY)
model = genai.GenerativeModel('gemini-pro')

class ChatRequest(BaseModel):
    message: str

@app.get("/")
def read_root():
    logger.info("Root endpoint called")
    return {"status": "ok", "message": "Plant Care Assistant API is running"}

@app.middleware("http")
async def log_requests(request: Request, call_next):
    logger.info(f"Incoming request: {request.method} {request.url}")
    try:
        if request.method == "POST":
            body = await request.body()
            if body:
                try:
                    logger.info(f"Request body: {body.decode()}")
                except:
                    logger.info(f"Binary request body, size: {len(body)} bytes")
        response = await call_next(request)
        logger.info(f"Response status code: {response.status_code}")
        return response
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return JSONResponse(
            status_code=500,
            content={"detail": str(e)},
        )

@app.post("/chat")
async def chat(request: ChatRequest):
    try:
        logger.info(f"Received message: {request.message}")
        
        # Add plant care context to the prompt
        prompt = f"""You are a helpful plant care assistant. You help users with:
1. Plant disease identification and treatment
2. Plant care tips and advice
3. Gardening best practices
4. Plant selection recommendations

User query: {request.message}"""

        # Generate response with safety settings
        generation_config = {
            "temperature": 0.7,
            "top_p": 0.95,
            "top_k": 40,
            "max_output_tokens": 1024,
        }
        
        logger.info("Sending request to Gemini API")
        try:
            response = model.generate_content(
                prompt,
                generation_config=generation_config
            )
            logger.info("Successfully received response from Gemini API")
        except Exception as e:
            logger.error(f"Error from Gemini API: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Gemini API error: {str(e)}")
        
        result = {
            "status": "success",
            "message": response.text
        }
        logger.info(f"Returning response with length: {len(response.text)}")
        return result
    except Exception as e:
        logger.error(f"Error in chat endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/test")
async def test_connection():
    try:
        logger.info("Test endpoint called")
        return {"status": "success", "message": "Connection successful"}
    except Exception as e:
        logger.error(f"Error in test endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

# Add debug info endpoint
@app.get("/debug")
async def debug_info(request: Request):
    """Return debug information to help diagnose connection issues"""
    client_host = request.client.host if request.client else "unknown"
    headers = dict(request.headers)
    
    info = {
        "client_ip": client_host,
        "request_headers": headers,
        "server_info": {
            "gemini_api_key_set": bool(GEMINI_API_KEY),
            "python_version": sys.version,
        }
    }
    logger.info(f"Debug info requested by {client_host}")
    return info

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
