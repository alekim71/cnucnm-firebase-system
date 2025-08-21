#!/usr/bin/env python3
"""
간단한 웹서버 - CNUCNM 사용자 관리 서비스 테스트용
"""
import http.server
import socketserver
import json
import sqlite3
from pathlib import Path
import urllib.parse
from datetime import datetime

class CNUCNMHandler(http.server.SimpleHTTPRequestHandler):
    """CNUCNM 사용자 관리 서비스 핸들러"""
    
    def do_GET(self):
        """GET 요청 처리"""
        parsed_path = urllib.parse.urlparse(self.path)
        path = parsed_path.path
        
        if path == "/":
            self.send_home_page()
        elif path == "/health":
            self.send_health_check()
        elif path == "/api/v1/users":
            self.send_users_list()
        elif path == "/setup":
            self.setup_database()
        else:
            self.send_error(404, "Not Found")
    
    def do_POST(self):
        """POST 요청 처리"""
        parsed_path = urllib.parse.urlparse(self.path)
        path = parsed_path.path
        
        if path == "/api/v1/auth/register":
            self.handle_user_registration()
        else:
            self.send_error(404, "Not Found")
    
    def send_home_page(self):
        """홈페이지 응답"""
        html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>CNUCNM User Management Service</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 40px; }
                .container { max-width: 800px; margin: 0 auto; }
                .header { background: #2c3e50; color: white; padding: 20px; border-radius: 5px; }
                .section { margin: 20px 0; padding: 20px; border: 1px solid #ddd; border-radius: 5px; }
                .button { background: #3498db; color: white; padding: 10px 20px; text-decoration: none; border-radius: 3px; display: inline-block; margin: 5px; }
                .form-group { margin: 10px 0; }
                .form-group label { display: block; margin-bottom: 5px; }
                .form-group input { width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 3px; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🐄 CNUCNM User Management Service</h1>
                    <p>사용자 관리 마이크로서비스 - 간단한 웹서버 버전</p>
                </div>
                
                <div class="section">
                    <h2>📊 서비스 상태</h2>
                    <a href="/health" class="button">헬스 체크</a>
                    <a href="/api/v1/users" class="button">사용자 목록</a>
                    <a href="/setup" class="button">데이터베이스 설정</a>
                </div>
                
                <div class="section">
                    <h2>👤 사용자 등록</h2>
                    <form id="registerForm">
                        <div class="form-group">
                            <label for="email">이메일:</label>
                            <input type="email" id="email" name="email" required>
                        </div>
                        <div class="form-group">
                            <label for="username">사용자명:</label>
                            <input type="text" id="username" name="username" required>
                        </div>
                        <div class="form-group">
                            <label for="password">비밀번호:</label>
                            <input type="password" id="password" name="password" required>
                        </div>
                        <div class="form-group">
                            <label for="first_name">이름:</label>
                            <input type="text" id="first_name" name="first_name">
                        </div>
                        <div class="form-group">
                            <label for="last_name">성:</label>
                            <input type="text" id="last_name" name="last_name">
                        </div>
                        <button type="submit" class="button">등록</button>
                    </form>
                    <div id="result"></div>
                </div>
                
                <div class="section">
                    <h2>🔗 API 엔드포인트</h2>
                    <ul>
                        <li><strong>GET /</strong> - 홈페이지</li>
                        <li><strong>GET /health</strong> - 서비스 상태 확인</li>
                        <li><strong>GET /setup</strong> - 데이터베이스 초기 설정</li>
                        <li><strong>GET /api/v1/users</strong> - 사용자 목록 조회</li>
                        <li><strong>POST /api/v1/auth/register</strong> - 사용자 등록</li>
                    </ul>
                </div>
            </div>
            
            <script>
                document.getElementById('registerForm').addEventListener('submit', async function(e) {
                    e.preventDefault();
                    
                    const formData = new FormData(this);
                    const data = Object.fromEntries(formData);
                    
                    try {
                        const response = await fetch('/api/v1/auth/register', {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json',
                            },
                            body: JSON.stringify(data)
                        });
                        
                        const result = await response.json();
                        document.getElementById('result').innerHTML = 
                            '<div style="padding: 10px; margin: 10px 0; background: #d4edda; border: 1px solid #c3e6cb; border-radius: 3px;">' +
                            '<strong>성공!</strong> ' + JSON.stringify(result, null, 2) +
                            '</div>';
                        
                        this.reset();
                    } catch (error) {
                        document.getElementById('result').innerHTML = 
                            '<div style="padding: 10px; margin: 10px 0; background: #f8d7da; border: 1px solid #f5c6cb; border-radius: 3px;">' +
                            '<strong>오류!</strong> ' + error.message +
                            '</div>';
                    }
                });
            </script>
        </body>
        </html>
        """
        
        self.send_response(200)
        self.send_header('Content-type', 'text/html; charset=utf-8')
        self.end_headers()
        self.wfile.write(html.encode('utf-8'))
    
    def send_health_check(self):
        """헬스 체크 응답"""
        try:
            db_path = Path("data/cnucnm.db")
            if db_path.exists():
                conn = sqlite3.connect(db_path)
                cursor = conn.cursor()
                cursor.execute("SELECT COUNT(*) FROM users")
                user_count = cursor.fetchone()[0]
                conn.close()
                
                response = {
                    "status": "healthy",
                    "service": "CNUCNM User Management",
                    "version": "1.0.0",
                    "database": "connected",
                    "user_count": user_count,
                    "timestamp": datetime.now().isoformat()
                }
            else:
                response = {
                    "status": "warning",
                    "service": "CNUCNM User Management",
                    "version": "1.0.0",
                    "database": "not_found",
                    "message": "Database file not found. Run /setup first.",
                    "timestamp": datetime.now().isoformat()
                }
        except Exception as e:
            response = {
                "status": "unhealthy",
                "service": "CNUCNM User Management",
                "version": "1.0.0",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
        
        self.send_json_response(response)
    
    def send_users_list(self):
        """사용자 목록 응답"""
        try:
            db_path = Path("data/cnucnm.db")
            if not db_path.exists():
                self.send_error(500, "Database not found. Run /setup first.")
                return
            
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            
            cursor.execute("""
                SELECT id, email, username, first_name, last_name, role, status, created_at
                FROM users
                ORDER BY created_at DESC
            """)
            
            users = []
            for row in cursor.fetchall():
                users.append({
                    "id": row[0],
                    "email": row[1],
                    "username": row[2],
                    "first_name": row[3],
                    "last_name": row[4],
                    "role": row[5],
                    "status": row[6],
                    "created_at": row[7]
                })
            
            conn.close()
            
            response = {
                "users": users,
                "total": len(users),
                "timestamp": datetime.now().isoformat()
            }
            
            self.send_json_response(response)
            
        except Exception as e:
            self.send_error(500, f"Failed to fetch users: {str(e)}")
    
    def setup_database(self):
        """데이터베이스 초기 설정"""
        try:
            # 데이터베이스 디렉토리 생성
            db_dir = Path("data")
            db_dir.mkdir(exist_ok=True)
            
            db_path = db_dir / "cnucnm.db"
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            
            # 사용자 테이블 생성
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS users (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    email TEXT UNIQUE NOT NULL,
                    username TEXT UNIQUE NOT NULL,
                    hashed_password TEXT NOT NULL,
                    first_name TEXT,
                    last_name TEXT,
                    phone TEXT,
                    role TEXT DEFAULT 'farmer',
                    status TEXT DEFAULT 'active',
                    farm_name TEXT,
                    farm_address TEXT,
                    farm_size INTEGER,
                    farm_type TEXT,
                    is_email_verified BOOLEAN DEFAULT 0,
                    is_phone_verified BOOLEAN DEFAULT 0,
                    is_active BOOLEAN DEFAULT 1,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    last_login_at TIMESTAMP,
                    profile_image_url TEXT,
                    language TEXT DEFAULT 'ko',
                    timezone TEXT DEFAULT 'Asia/Seoul',
                    notification_email BOOLEAN DEFAULT 1,
                    notification_sms BOOLEAN DEFAULT 0,
                    notification_push BOOLEAN DEFAULT 1
                )
            ''')
            
            # 관리자 계정 생성 (존재하지 않는 경우)
            cursor.execute("SELECT id FROM users WHERE email = 'admin@cnucnm.com'")
            if not cursor.fetchone():
                cursor.execute("""
                    INSERT INTO users (email, username, hashed_password, first_name, last_name, role, status)
                    VALUES ('admin@cnucnm.com', 'admin', 'hashed_Admin123!', 'System', 'Administrator', 'admin', 'active')
                """)
            
            conn.commit()
            conn.close()
            
            response = {
                "message": "Database setup completed successfully",
                "database_path": str(db_path),
                "admin_account": {
                    "email": "admin@cnucnm.com",
                    "username": "admin",
                    "password": "Admin123!"
                },
                "timestamp": datetime.now().isoformat()
            }
            
            self.send_json_response(response)
            
        except Exception as e:
            self.send_error(500, f"Database setup failed: {str(e)}")
    
    def handle_user_registration(self):
        """사용자 등록 처리"""
        try:
            # POST 데이터 읽기
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            user_data = json.loads(post_data.decode('utf-8'))
            
            # 필수 필드 검증
            required_fields = ['email', 'username', 'password']
            for field in required_fields:
                if field not in user_data or not user_data[field]:
                    self.send_error(400, f"Missing required field: {field}")
                    return
            
            db_path = Path("data/cnucnm.db")
            if not db_path.exists():
                self.send_error(500, "Database not initialized. Please run /setup first.")
                return
            
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            
            # 중복 확인
            cursor.execute("SELECT id FROM users WHERE email = ? OR username = ?", 
                         (user_data['email'], user_data['username']))
            if cursor.fetchone():
                conn.close()
                self.send_error(400, "Email or username already exists")
                return
            
            # 사용자 생성
            cursor.execute("""
                INSERT INTO users (email, username, hashed_password, first_name, last_name, role, status)
                VALUES (?, ?, ?, ?, ?, 'farmer', 'active')
            """, (user_data['email'], user_data['username'], f"hashed_{user_data['password']}", 
                  user_data.get('first_name'), user_data.get('last_name')))
            
            user_id = cursor.lastrowid
            conn.commit()
            conn.close()
            
            response = {
                "message": "User registered successfully",
                "user_id": user_id,
                "email": user_data['email'],
                "username": user_data['username'],
                "timestamp": datetime.now().isoformat()
            }
            
            self.send_json_response(response)
            
        except json.JSONDecodeError:
            self.send_error(400, "Invalid JSON data")
        except Exception as e:
            self.send_error(500, f"Registration failed: {str(e)}")
    
    def send_json_response(self, data):
        """JSON 응답 전송"""
        self.send_response(200)
        self.send_header('Content-type', 'application/json; charset=utf-8')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
        self.wfile.write(json.dumps(data, ensure_ascii=False, indent=2).encode('utf-8'))

def main():
    """메인 함수"""
    PORT = 8000
    
    print("🚀 CNUCNM User Management Service - Simple Web Server")
    print("=" * 60)
    print(f"📡 서버 시작: http://localhost:{PORT}")
    print("📚 API 문서: http://localhost:8000")
    print("❤️ 헬스 체크: http://localhost:8000/health")
    print("🗄️ DB 설정: http://localhost:8000/setup")
    print("👥 사용자 목록: http://localhost:8000/api/v1/users")
    print("=" * 60)
    print("🛑 서버 중지: Ctrl+C")
    
    try:
        with socketserver.TCPServer(("", PORT), CNUCNMHandler) as httpd:
            print(f"✅ 서버가 포트 {PORT}에서 실행 중입니다...")
            httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 서버가 중지되었습니다.")
    except Exception as e:
        print(f"❌ 서버 시작 실패: {e}")

if __name__ == "__main__":
    main()


