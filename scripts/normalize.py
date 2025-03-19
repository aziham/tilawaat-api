import sys
import json

def normalize_peaks(filename):
    with open(filename, "r") as f:
        data = json.load(f)

    max_val = max(data["data"])
    data["data"] = [round(x / max_val, 2) for x in data["data"]]

    with open(filename, "w") as f:
        json.dump(data, f, separators=(",", ":"))

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python normalize_peaks.py file.json")
        exit()
    normalize_peaks(sys.argv[1])
