# EXERCISE 4
## Custom Network & Named Volume Using Docker CLI

### 1. Mục tiêu

Thiết lập Custom Bridge Network để các Docker Container giao tiếp với nhau thông qua hostname nội bộ.

Sử dụng Named Volume để lưu trữ dữ liệu PostgreSQL và kiểm tra khả năng Data Persistence khi xóa và tái tạo Database Container.

### 2. Công nghệ sử dụng

- Docker Desktop
- Docker CLI
- Node.js / Express
- PostgreSQL 15 Alpine
- Docker Bridge Network
- Docker Named Volume
- Windows CMD

### 3. Cấu hình hệ thống

| Thành phần | Giá trị |
|---|---|
| Custom Network | app-net |
| Named Volume | db-data |
| Backend Image | hw-backend:v1 |
| Backend Container | app-container |
| Database Image | postgres:15-alpine |
| Database Container | db-server |
| Database Name | appdb |
| Backend Port | 8081:3000 |
| PostgreSQL Port | 5432 |
| Database Hostname | db-server |

### 4. Tạo Custom Bridge Network

Sử dụng lệnh:

```bash
docker network create --driver bridge app-net
```

Kiểm tra:

```bash
docker network ls
docker network inspect app-net
```

Custom Bridge Network cho phép các Container trong cùng mạng giao tiếp thông qua Docker DNS mà không cần sử dụng địa chỉ IP cố định.

### 5. Tạo Named Volume

```bash
docker volume create db-data
```

Kiểm tra:

```bash
docker volume ls
docker volume inspect db-data
```

Named Volume giúp lưu trữ dữ liệu độc lập với vòng đời của Container.

### 6. Khởi chạy PostgreSQL Container

```bash
docker run -d \
  --name db-server \
  --network app-net \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres123 \
  -e POSTGRES_DB=appdb \
  -v db-data:/var/lib/postgresql/data \
  postgres:15-alpine
```

PostgreSQL sử dụng Named Volume `db-data` để lưu trữ dữ liệu tại `/var/lib/postgresql/data`.

### 7. Khởi chạy Backend Container

```bash
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
```

Backend và PostgreSQL cùng tham gia mạng `app-net`.

Hostname Database được cấu hình là `db-server`. Ứng dụng mẫu từ Bài 2 chưa triển khai logic truy vấn PostgreSQL; phần thực hành này kiểm tra kết nối mạng và dữ liệu bằng Docker CLI và psql.

### 8. Kiểm tra kết nối DNS

Thực hiện:

```bash
docker exec -it app-container ping -c 2 db-server
```

Kết quả thực tế:

```text
PING db-server (172.23.0.2): 56 data bytes
64 bytes from 172.23.0.2: seq=0 ttl=64 time=0.094 ms
64 bytes from 172.23.0.2: seq=1 ttl=64 time=0.122 ms

2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 0.094/0.108/0.122 ms
```

**Nhận xét:** Backend Container phân giải thành công hostname `db-server` thành địa chỉ IP nội bộ `172.23.0.2`.

Kết quả 0% packet loss chứng minh hai Container giao tiếp được qua Custom Bridge Network.

### 9. Kiểm tra Data Persistence

**Bước 1: Truy cập PostgreSQL**

```bash
docker exec -it db-server psql -U postgres -d appdb
```

**Bước 2: Tạo bảng students**

```sql
CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100)
);
```

**Bước 3: Thêm dữ liệu**

```sql
INSERT INTO students (name)
VALUES ('Nguyen Van A');
```

**Bước 4: Kiểm tra dữ liệu**

```sql
SELECT * FROM students;
```

Kết quả:

```text
 id |     name
----+--------------
  1 | Nguyen Van A
(1 row)
```

**Bước 5: Xóa Database Container**

```bash
docker rm -f db-server
```

Lệnh này xóa Container nhưng không xóa Named Volume.

**Bước 6: Tạo lại Database Container**

```bash
docker run -d \
  --name db-server \
  --network app-net \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres123 \
  -e POSTGRES_DB=appdb \
  -v db-data:/var/lib/postgresql/data \
  postgres:15-alpine
```

**Bước 7: Kiểm tra Database sau khi tái tạo**

```bash
docker exec db-server pg_isready -U postgres -d appdb
```

Kết quả:

```text
/var/run/postgresql:5432 - accepting connections
```

Tiếp tục truy vấn:

```bash
docker exec -it db-server psql -U postgres -d appdb
```

```sql
SELECT * FROM students;
```

Kết quả thực tế:

```text
 id |     name
----+--------------
  1 | Nguyen Van A
(1 row)
```

**Kết luận:** Dữ liệu PostgreSQL vẫn tồn tại sau khi xóa và tạo lại Database Container nhờ sử dụng cùng Named Volume `db-data`.

### 10. Tổng kết kết quả

| Yêu cầu | Kết quả |
|---|---|
| Tạo Custom Bridge Network | Thành công |
| Tạo Named Volume | Thành công |
| Chạy PostgreSQL Container | Thành công |
| Chạy Backend Container | Thành công |
| Phân giải hostname db-server | Thành công |
| Ping giữa hai Container | 0% packet loss |
| Thêm dữ liệu PostgreSQL | Thành công |
| Xóa và tạo lại DB Container | Thành công |
| Kiểm tra Data Persistence | Dữ liệu không bị mất |

### 11. Kết luận

Bài thực hành đã thiết lập thành công Custom Bridge Network và Named Volume bằng Docker CLI.

Docker Network cho phép Backend và PostgreSQL giao tiếp qua hostname nội bộ mà không cần cấu hình IP cố định.

Docker Named Volume giúp dữ liệu được lưu trữ bền vững, ngay cả khi Database Container bị xóa và tạo lại.

Đây là những thành phần quan trọng trong quá trình triển khai hệ thống nhiều Container và kiến trúc Microservices.