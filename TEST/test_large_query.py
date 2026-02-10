import requests
import time
import statistics

# --- CONFIG ---
#BASE_URL = "https://tps-production-c025.up.railway.app"
BASE_URL = "http://localhost:8000"
LOGIN_ENDPOINT = "/api/users/token/user/"
BENCH_ENDPOINT = "/api/parkings/"
USERNAME = "admin@admin.com"
PASSWORD = "admin"
LIMITS = [5, 10, 20, 50, 100, 200, 500, 1000]  
ITERATIONS = 1                      

# --- FUNCTION TO GET JWT ---
def get_jwt(username, password):
    data = {"email": username, "password": password}
    r = requests.post(BASE_URL + LOGIN_ENDPOINT, json=data)
    if r.status_code == 200:
        token = r.json().get("access")
        return token
    else:
        raise Exception(f"Login failed: {r.status_code} {r.text}")

# --- FUNCTION TO MEASURE LATENCY ---
def measure(limit, token):
    headers = {"Authorization": f"Bearer {token}"}
    times = []
    for _ in range(ITERATIONS):
        start = time.time()
        r = requests.get(f"{BASE_URL}{BENCH_ENDPOINT}search_map/?city=0_TEST_CITY", headers=headers) 
        elapsed = time.time() - start
        times.append(elapsed)
        if r.status_code != 200:
            print(f"Error {r.status_code} for limit={limit}")
    return {
        "limit": limit,
        "avg": statistics.mean(times),
        "p95": statistics.quantiles(times, n=20)[18],
        "max": max(times)
    }

# --- MAIN SCRIPT ---
def main():
    print("Logging in...")
    token = get_jwt(USERNAME, PASSWORD)
    print("Login successful. JWT acquired.\n")
    
    results = []
    for limit in LIMITS:
        res = measure(limit, token)
        results.append(res)
        print(f'\nResult for limit={limit}: {res}')

if __name__ == "__main__":
    main()
