import subprocess

# Define target and ports
target = "scanme.nmap.org"
ports = "22,80,443"

# Run Nmap with common flags:
# -Pn: skip ping discovery
# -sS: TCP SYN scan (stealth)
# -p: specify ports
command = ["nmap", "-Pn", "-sS", "-p", ports, target]

# Run and capture the output
result = subprocess.run(command, capture_output=True, text=True)

# Print the raw Nmap output
print(result.stdout)
