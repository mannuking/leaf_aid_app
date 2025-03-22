from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import google.generativeai as genai
from typing import Optional

app = FastAPI()

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with your Flutter app's domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configure Gemini API
GEMINI_API_KEY = "AIzaSyD1UC4JIFoYyMrsmevjLGq_c4DTW1-CrgM"
genai.configure(api_key=GEMINI_API_KEY)
model = genai.GenerativeModel('gemini-pro')

class ChatRequest(BaseModel):
    message: str

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Plant Care Assistant API is running"}

@app.post("/chat")
async def chat(request: ChatRequest):
    try:
        # Add plant care context to the prompt
        prompt = f"""You are a helpful plant care assistant. You help users with:
1. Plant disease identification and treatment
2. Plant care tips and advice
3. Gardening best practices
4. Plant selection recommendations

User query: {request.message}"""

        # Generate response
        response = model.generate_content(prompt)
        
        return {
            "status": "success",
            "message": response.text
        }
    except Exception as e:
        print(f"Error in chat endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/test")
async def test_connection():
    try:
        response = model.generate_content("test connection")
        return {"status": "success", "message": "Connection successful"}
    except Exception as e:
        print(f"Error in test endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e)) 
