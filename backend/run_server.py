import uvicorn

if __name__ == "__main__":
    # Run with host="0.0.0.0" to make the server accessible from other devices
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
    print("Server running at http://0.0.0.0:8000")
