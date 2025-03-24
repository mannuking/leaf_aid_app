"""
Health checker utility for the FastAPI backend
Run this script to verify the server is operating correctly
"""
import requests
import socket
import json
import sys
import time

def get_local_ip():
    """Get the local IP address of the machine"""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # Doesn't need to be reachable
        s.connect(('10.255.255.255', 1))
        IP = s.getsockname()[0]
    except Exception:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP

def check_server(host, port=8000):
    """Check if the server is accessible"""
    urls = [
        f"http://{host}:{port}/",
        f"http://{host}:{port}/test",
    ]
    
    results = {}
    
    for url in urls:
        try:
            print(f"\nTesting URL: {url}")
            response = requests.get(url, timeout=5)
            results[url] = {
                "status": response.status_code,
                "response": response.json() if response.status_code == 200 else None,
                "success": response.status_code == 200
            }
            print(f"  Status: {response.status_code}")
            if response.status_code == 200:
                print(f"  Response: {response.json()}")
            else:
                print(f"  Error: Non-200 response code")
        except requests.exceptions.Timeout:
            print(f"  Error: Timeout connecting to {url}")
            results[url] = {"status": "timeout", "success": False}
        except requests.exceptions.ConnectionError:
            print(f"  Error: Could not connect to {url}")
            results[url] = {"status": "connection_error", "success": False}
        except Exception as e:
            print(f"  Error: {str(e)}")
            results[url] = {"status": "error", "message": str(e), "success": False}
    
    return results

def test_chat_endpoint(host, port=8000):
    """Test the chat endpoint with a simple message"""
    url = f"http://{host}:{port}/chat"
    data = {"message": "Hello, can you help me with tomato plant care?"}
    
    try:
        print(f"\nTesting chat endpoint: {url}")
        print(f"  Request payload: {data}")
        
        start_time = time.time()
        response = requests.post(url, json=data, timeout=30)
        elapsed_time = time.time() - start_time
        
        print(f"  Response time: {elapsed_time:.2f} seconds")
        print(f"  Status code: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            # Truncate the message if it's too long for display
            if len(result.get("message", "")) > 100:
                result["message"] = result["message"][:100] + "..."
            print(f"  Response: {json.dumps(result, indent=2)}")
            return {"success": True, "response": result}
        else:
            print(f"  Error response: {response.text}")
            return {"success": False, "status_code": response.status_code, "response": response.text}
    except Exception as e:
        print(f"  Error: {str(e)}")
        return {"success": False, "error": str(e)}

if __name__ == "__main__":
    local_ip = get_local_ip()
    
    print("\n=== FastAPI Backend Health Check ===")
    print(f"Your local IP address is: {local_ip}")
    print("Testing server on different addresses...")
    
    # Test localhost variants
    hosts = ["localhost", "127.0.0.1", local_ip, "0.0.0.0"]
    
    all_success = False
    
    for host in hosts:
        print(f"\n--- Testing host: {host} ---")
        results = check_server(host)
        
        # If any connection was successful, try the chat endpoint
        if any(result.get("success", False) for result in results.values()):
            chat_result = test_chat_endpoint(host)
            all_success = chat_result.get("success", False)
            if all_success:
                print(f"\n✅ Server is working correctly on {host}!")
                print(f"Use this URL in your Flutter app: http://{host}:8000")
                break
    
    if not all_success:
        print("\n❌ Could not find a working server configuration")
        print("Please check that your FastAPI server is running correctly")
        sys.exit(1)
    
    print("\n=== Recommendations for Flutter App ===")
    print(f"1. For Android Emulator: Use baseUrl = 'http://10.0.2.2:8000'")
    print(f"2. For iOS Simulator: Use baseUrl = 'http://localhost:8000'")
    print(f"3. For Physical Devices: Use baseUrl = 'http://{local_ip}:8000'")
