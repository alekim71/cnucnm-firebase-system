#!/usr/bin/env python3
"""
CNUCNM 사용자 관리 서비스 - 완전히 독립적인 웹서버
프로젝트 루트에서 직접 실행 가능
"""
import http.server
import socketserver
import json
import sqlite3
from pathlib import Path
import urllib.parse
from datetime import datetime
import os

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
        <html lang="ko">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>CNUCNM User Management Service</title>
            <style>
                * { box-sizing: border-box; }
                body { 
                    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
                    margin: 0; padding: 20px; 
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    min-height: 100vh;
                }
                .container { 
                    max-width: 1000px; 
                    margin: 0 auto; 
                    background: white; 
                    border-radius: 10px; 
                    box-shadow: 0 10px 30px rgba(0,0,0,0.2);
                    overflow: hidden;
                }
                .header { 
                    background: linear-gradient(45deg, #2c3e50, #34495e); 
                    color: white; 
                    padding: 30px; 
                    text-align: center;
                }
                .header h1 { margin: 0; font-size: 2.5em; }
                .header p { margin: 10px 0 0 0; opacity: 0.9; }
                .section { 
                    margin: 0; 
                    padding: 30px; 
                    border-bottom: 1px solid #eee; 
                }
                .section:last-child { border-bottom: none; }
                .section h2 { color: #2c3e50; margin-top: 0; }
                .button { 
                    background: linear-gradient(45deg, #3498db, #2980b9); 
                    color: white; 
                    padding: 12px 24px; 
                    text-decoration: none; 
                    border-radius: 6px; 
                    display: inline-block; 
                    margin: 8px 8px 8px 0; 
                    border: none;
                    cursor: pointer;
                    font-size: 14px;
                    transition: transform 0.2s, box-shadow 0.2s;
                }
                .button:hover { 
                    transform: translateY(-2px); 
                    box-shadow: 0 4px 12px rgba(52, 152, 219, 0.4);
                }
                .form-group { margin: 20px 0; }
                .form-group label { 
                    display: block; 
                    margin-bottom: 8px; 
                    font-weight: 600;
                    color: #2c3e50;
                }
                .form-group input { 
                    width: 100%; 
                    padding: 12px; 
                    border: 2px solid #ddd; 
                    border-radius: 6px; 
                    font-size: 14px;
                    transition: border-color 0.3s;
                }
                .form-group input:focus {
                    outline: none;
                    border-color: #3498db;
                }
                .success { 
                    padding: 15px; 
                    margin: 15px 0; 
                    background: #d4edda; 
                    border: 1px solid #c3e6cb; 
                    border-radius: 6px; 
                    color: #155724;
                }
                .error { 
                    padding: 15px; 
                    margin: 15px 0; 
                    background: #f8d7da; 
                    border: 1px solid #f5c6cb; 
                    border-radius: 6px; 
                    color: #721c24;
                }
                .api-list { list-style: none; padding: 0; }
                .api-list li { 
                    padding: 10px; 
                    margin: 5px 0; 
                    background: #f8f9fa; 
                    border-radius: 4px; 
                    border-left: 4px solid #3498db;
                }
                .api-list strong { color: #2c3e50; }
                .status-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                    gap: 15px;
                    margin-top: 20px;
                }
                .status-card {
                    background: #f8f9fa;
                    padding: 20px;
                    border-radius: 8px;
                    text-align: center;
                    border: 2px solid #e9ecef;
                }
                .status-card h3 { margin: 0 0 10px 0; color: #2c3e50; }
                .status-card p { margin: 0; font-size: 1.2em; font-weight: bold; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🐄 CNUCNM User Management Service</h1>
                    <p>사용자 관리 마이크로서비스 - 독립 실행형 웹서버</p>
                </div>
                
                <div class="section">
                    <h2>📊 서비스 상태</h2>
                    <div class="status-grid">
                        <div class="status-card">
                            <h3>🔧 설정</h3>
                            <a href="/setup" class="button">DB 설정</a>
                        </div>
                        <div class="status-card">
                            <h3>❤️ 상태</h3>
                            <a href="/health" class="button">헬스 체크</a>
                        </div>
                        <div class="status-card">
                            <h3>👥 사용자</h3>
                            <a href="/api/v1/users" class="button">사용자 목록</a>
                        </div>
                    </div>
                </div>
                
                <div class="section">
                    <h2>👤 사용자 등록</h2>
                    <form id="registerForm">
                        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
                            <div class="form-group">
                                <label for="email">이메일 *</label>
                                <input type="email" id="email" name="email" required placeholder="user@example.com">
                            </div>
                            <div class="form-group">
                                <label for="username">사용자명 *</label>
                                <input type="text" id="username" name="username" required placeholder="username">
                            </div>
                            <div class="form-group">
                                <label for="password">비밀번호 *</label>
                                <input type="password" id="password" name="password" required placeholder="password">
                            </div>
                            <div class="form-group">
                                <label for="first_name">이름</label>
                                <input type="text" id="first_name" name="first_name" placeholder="홍길동">
                            </div>
                        </div>
                        <div class="form-group">
                            <label for="last_name">성</label>
                            <input type="text" id="last_name" name="last_name" placeholder="김">
                        </div>
                        <button type="submit" class="button" style="font-size: 16px; padding: 15px 30px;">✅ 사용자 등록</button>
                    </form>
                    <div id="result"></div>
                </div>
                
                <div class="section">
                    <h2>🔗 API 엔드포인트</h2>
                    <ul class="api-list">
                        <li><strong>GET /</strong> - 홈페이지 (현재 페이지)</li>
                        <li><strong>GET /health</strong> - 서비스 상태 확인</li>
                        <li><strong>GET /setup</strong> - 데이터베이스 초기 설정</li>
                        <li><strong>GET /api/v1/users</strong> - 사용자 목록 조회 (JSON)</li>
                        <li><strong>POST /api/v1/auth/register</strong> - 사용자 등록 (JSON)</li>
                    </ul>
                </div>
                
                <div class="section">
                    <h2>💡 사용 방법</h2>
                    <ol>
                        <li><strong>데이터베이스 설정:</strong> 먼저 "DB 설정" 버튼을 클릭하여 데이터베이스를 초기화하세요.</li>
                        <li><strong>사용자 등록:</strong> 위의 폼을 사용하여 새 사용자를 등록하세요.</li>
                        <li><strong>사용자 목록:</strong> "사용자 목록" 버튼을 클릭하여 등록된 사용자를 확인하세요.</li>
                        <li><strong>API 테스트:</strong> 각 API 엔드포인트를 직접 호출하여 테스트할 수 있습니다.</li>
                    </ol>
                </div>
            </div>
            
            <script>
                document.getElementById('registerForm').addEventListener('submit', async function(e) {
                    e.preventDefault();
                    
                    const formData = new FormData(this);
                    const data = Object.fromEntries(formData);
                    const resultDiv = document.getElementById('result');
                    
                    try {
                        const response = await fetch('/api/v1/auth/register', {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json',
                            },
                            body: JSON.stringify(data)
                        });
                        
                        const result = await response.json();
                        
                        if (response.ok) {
                            resultDiv.innerHTML = 
                                '<div class="success">' +
                                '<strong>✅ 등록 성공!</strong><br>' +
                                '사용자 ID: ' + result.user_id + '<br>' +
                                '이메일: ' + result.email + '<br>' +
                                '사용자명: ' + result.username +
                                '</div>';
                            this.reset();
                        } else {
                            throw new Error(result.detail || 'Registration failed');
                        }
                    } catch (error) {
                        resultDiv.innerHTML = 
                            '<div class="error">' +
                            '<strong>❌ 오류 발생!</strong><br>' + 
                            error.message +
                            '</div>';
                    }
                });
                
                // 페이지 로드 시 상태 확인
                window.addEventListener('load', function() {
                    fetch('/health')
                        .then(response => response.json())
                        .then(data => {
                            console.log('서비스 상태:', data);
                        })
                        .catch(error => {
                            console.log('상태 확인 실패:', error);
                        });
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
            db_path = Path("cnucnm_data/cnucnm.db")
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
                    "database_path": str(db_path.absolute()),
                    "user_count": user_count,
                    "timestamp": datetime.now().isoformat()
                }
            else:
                response = {
                    "status": "warning",
                    "service": "CNUCNM User Management",
                    "version": "1.0.0",
                    "database": "not_found",
                    "message": "Database file not found. Visit /setup to initialize.",
                    "expected_path": str(db_path.absolute()),
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
            db_path = Path("cnucnm_data/cnucnm.db")
            if not db_path.exists():
                self.send_error(500, "Database not found. Visit /setup to initialize database.")
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
                "database_path": str(db_path.absolute()),
                "timestamp": datetime.now().isoformat()
            }
            
            self.send_json_response(response)
            
        except Exception as e:
            self.send_error(500, f"Failed to fetch users: {str(e)}")
    
    def setup_database(self):
        """데이터베이스 초기 설정"""
        try:
            # 데이터베이스 디렉토리 생성
            db_dir = Path("cnucnm_data")
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
            admin_exists = cursor.fetchone()
            
            if not admin_exists:
                cursor.execute("""
                    INSERT INTO users (email, username, hashed_password, first_name, last_name, role, status)
                    VALUES ('admin@cnucnm.com', 'admin', 'hashed_Admin123!', 'System', 'Administrator', 'admin', 'active')
                """)
                admin_created = True
            else:
                admin_created = False
            
            # 샘플 사용자 생성
            cursor.execute("SELECT COUNT(*) FROM users WHERE role = 'farmer'")
            farmer_count = cursor.fetchone()[0]
            
            if farmer_count == 0:
                sample_users = [
                    ('farmer1@cnucnm.com', 'farmer1', 'hashed_password123', '농부', '김', 'farmer'),
                    ('farmer2@cnucnm.com', 'farmer2', 'hashed_password123', '목장주', '이', 'farmer'),
                    ('vet@cnucnm.com', 'veterinarian', 'hashed_password123', '수의사', '박', 'veterinarian')
                ]
                
                for user in sample_users:
                    cursor.execute("""
                        INSERT INTO users (email, username, hashed_password, first_name, last_name, role, status)
                        VALUES (?, ?, ?, ?, ?, ?, 'active')
                    """, user)
                
                sample_created = True
            else:
                sample_created = False
            
            conn.commit()
            conn.close()
            
            response = {
                "message": "Database setup completed successfully",
                "database_path": str(db_path.absolute()),
                "admin_account": {
                    "email": "admin@cnucnm.com",
                    "username": "admin",
                    "password": "Admin123!",
                    "created": admin_created
                },
                "sample_users_created": sample_created,
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
            
            db_path = Path("cnucnm_data/cnucnm.db")
            if not db_path.exists():
                self.send_error(500, "Database not initialized. Please visit /setup first.")
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
                "role": "farmer",
                "status": "active",
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
    
    print("🚀 CNUCNM User Management Service - 독립 실행형 웹서버")
    print("=" * 70)
    print(f"📡 서버 주소: http://localhost:{PORT}")
    print(f"🏠 홈페이지: http://localhost:{PORT}/")
    print(f"❤️ 헬스 체크: http://localhost:{PORT}/health")
    print(f"🔧 DB 설정: http://localhost:{PORT}/setup")
    print(f"👥 사용자 목록: http://localhost:{PORT}/api/v1/users")
    print(f"📁 작업 디렉토리: {os.getcwd()}")
    print("=" * 70)
    print("💡 사용법:")
    print("  1. 브라우저에서 http://localhost:8000 접속")
    print("  2. 'DB 설정' 버튼 클릭하여 데이터베이스 초기화")
    print("  3. 사용자 등록 폼으로 새 사용자 생성")
    print("  4. API 엔드포인트로 직접 테스트 가능")
    print("=" * 70)
    print("🛑 서버 중지: Ctrl+C")
    print()
    
    try:
        with socketserver.TCPServer(("", PORT), CNUCNMHandler) as httpd:
            print(f"✅ 서버가 포트 {PORT}에서 실행 중입니다...")
            print("🌐 브라우저에서 http://localhost:8000 을 열어보세요!")
            print()
            httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 서버가 중지되었습니다.")
    except Exception as e:
        print(f"❌ 서버 시작 실패: {e}")

if __name__ == "__main__":
    main()


