# SubdomainSweep

A fast and concurrent Bash tool to discover and validate subdomains via crt.sh with HTTP/HTTPS checks.
A Bash script to fetch all subdomains of a given domain from [crt.sh](https://crt.sh), deduplicate them, and check their HTTP(S) availability using concurrent `curl` requests.


## 📦 Features

- Fetch subdomains from `https://crt.sh`
- Deduplicate all results
- Test both `https://` and `http://` for status code `200`
- Concurrent processing with configurable parallelism
- Shows progress like `[progress: 3/50]`
- Outputs results to:
  - `https_200.txt` — valid domains
  - `https_failed.txt` — failed domains and status codes


## 🛠 Requirements

- `bash`
- `curl`
- `jq`

You can install dependencies on Debian/Ubuntu via:

```bash
sudo apt update && sudo apt install curl jq -y
```


## 🚀 Usage

### Basic Usage

```bash
./check_domains.sh example.com
```

### With Custom Parameters

You can configure concurrency, delay, and timeout via environment variables:

```bash
MAX_CONCURRENT=10 SLEEP_INTERVAL=1 CONNECT_TIMEOUT=5 ./check_domains.sh example.com
```


## ⚙️ Configuration Options

| Variable         | Description                                  | Default |
|------------------|----------------------------------------------|---------|
| `MAX_CONCURRENT` | Max number of concurrent checks              | `5`     |
| `SLEEP_INTERVAL` | Sleep between launching concurrent batches   | `2`     |
| `CONNECT_TIMEOUT`| Max seconds to wait for each curl connection | `3`     |


## 📂 Output Files

- `https_200.txt` — domains where HTTP or HTTPS returned `200 OK`
- `https_failed.txt` — domains with non-200 status and the codes

## 📌 Example Output

```
[progress: 1/20] www.example.com ✅ (https:200 / http:000)
[progress: 2/20] mail.example.com ❌ (https:000 / http:404)
```


## 🧹 Temporary Files

The script creates temporary files to store raw and deduplicated domain lists. These are automatically cleaned up after execution.


## 🔒 Disclaimer

This script is intended for **legitimate testing** only. Please ensure you have permission to scan the domains you test.


## 📝 License

GPL-3.0 
