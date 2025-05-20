#!/bin/bash

# Update system and install NGINX
apt-get update -y
apt-get install -y nginx

# Install Node.js (optional)
curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
apt-get install -y nodejs

# Create frontend directory and index.html
mkdir -p /var/www/html
cat > /var/www/html/index.html <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Simple 3-Tier App</title>
  <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap" rel="stylesheet">
  <style>
    body {
      font-family: 'Poppins', sans-serif;
      background: linear-gradient(to right, #4facfe, #00f2fe);
      margin: 0;
      padding: 0;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      color: #fff;
    }
    .container {
      text-align: center;
      background: rgba(0, 0, 0, 0.3);
      padding: 40px;
      border-radius: 15px;
      box-shadow: 0 8px 16px rgba(0,0,0,0.3);
    }
    h1 {
      font-size: 2.5rem;
      margin-bottom: 10px;
    }
    p {
      font-size: 1.2rem;
    }
    #counter {
      font-size: 1.8rem;
      margin: 20px 0;
      font-weight: 600;
    }
    button {
      background-color: #fff;
      color: #4facfe;
      font-size: 1.1rem;
      padding: 12px 25px;
      border: none;
      border-radius: 8px;
      cursor: pointer;
      transition: background-color 0.3s ease;
    }
    button:hover {
      background-color: #f0f0f0;
    }
  </style>
  <script>
    const backendUrl = "/api/increment/";
    async function updateCounter() {
      try {
        const response = await fetch(backendUrl);
        const data = await response.json();
        document.getElementById("counter").innerText = "Counter: " + data.counter;
      } catch (error) {
        console.error("Error fetching counter:", error);
        document.getElementById("counter").innerText = "Error fetching counter";
      }
    }
    window.onload = updateCounter;
  </script>
</head>
<body>
  <div class="container">
    <h1>Welcome to the Simple 3-Tier App</h1>
    <p><strong>By Mahmoud Sharara 💥🔥</strong></p>
    <p id="counter">Counter: 0</p>
    <button onclick="updateCounter()">Increment</button>
  </div>
</body>
</html>
EOF

# Configure NGINX reverse proxy
cat > /etc/nginx/sites-available/reverse-proxy.conf <<EOF
server {
    listen 80;
    server_name _;

    location / {
        root /var/www/html;
        index index.html;
    }

    location /api/ {
        proxy_pass http://${backend_alb_dns}:3000/api/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

ln -sf /etc/nginx/sites-available/reverse-proxy.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Restart NGINX
systemctl restart nginx
