
#!/bin/bash
set -e

# Session 10 - Exercise 4
# Custom Bridge Network & Named Volume

# 1. Create custom bridge network
echo "Creating Docker Network..."
if ! docker network inspect app-net >/dev/null 2>&1; then
    docker network create --driver bridge app-net
fi

# 2. Create named volume
echo "Creating Docker Volume..."
if ! docker volume inspect db-data >/dev/null 2>&1; then
    docker volume create db-data
fi

# 3. Start PostgreSQL container
echo "Starting PostgreSQL..."

if ! docker container inspect db-server >/dev/null 2>&1; then
    docker run -d \
        --name db-server \
        --network app-net \
        -e POSTGRES_USER=postgres \
        -e POSTGRES_PASSWORD=postgres123 \
        -e POSTGRES_DB=appdb \
        -v db-data:/var/lib/postgresql/data \
        postgres:15-alpine
fi

# 4. Start Backend container
echo "Starting Backend..."

if ! docker container inspect app-container >/dev/null 2>&1; then
    docker run -d \
        --name app-container \
        --network app-net \
        -e DB_HOST=db-server \
        -e DB_PORT=5432 \
        -e DB_USER=postgres \
        -e DB_PASSWORD=postgres123 \
        -e DB_NAME=appdb \
        -p 8081:3000 \
        hw-backend:v1
fi

# 5. Check Docker resources
echo "Checking Docker Network..."
docker network ls
docker network inspect app-net

echo "Checking Docker Volume..."
docker volume ls
docker volume inspect db-data

# 6. Check containers
echo "Checking Containers..."
docker ps

# 7. Test DNS resolution using Node.js
echo "Testing DNS resolution..."
docker exec app-container node -e \
"require('dns').lookup('db-server', (err, address) => {
  if (err) {
    console.error(err);
    process.exit(1);
  }
  console.log('db-server resolved to:', address);
});"

# 8. Test ping
echo "Testing Network Connection..."
docker exec app-container ping -c 2 db-server

echo "Docker setup completed successfully!"
