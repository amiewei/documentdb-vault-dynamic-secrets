FROM python:3.11.5-slim-bullseye

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    gpg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Install Vault CLI
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list && \
    apt update && apt install -y vault

# Set a working directory
WORKDIR /app

# Copy your scripts and other necessary files to the container
COPY db-config.py .

# Install Python dependencies
RUN pip install hvac

# Set the entrypoint to run your script
ENTRYPOINT ["python", "/app/db-config.py"]
