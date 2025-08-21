"""
로깅 설정 모듈
"""
import logging
import sys
from typing import Any, Dict
import structlog
from shared.common.config import settings

def setup_logging() -> None:
    """로깅 설정"""
    
    # 기본 로깅 설정
    logging.basicConfig(
        level=getattr(logging, settings.LOG_LEVEL.upper()),
        format=settings.LOG_FORMAT,
        handlers=[
            logging.StreamHandler(sys.stdout),
            logging.FileHandler("logs/app.log") if not settings.DEBUG else logging.NullHandler()
        ]
    )
    
    # Structlog 설정
    structlog.configure(
        processors=[
            structlog.stdlib.filter_by_level,
            structlog.stdlib.add_logger_name,
            structlog.stdlib.add_log_level,
            structlog.stdlib.PositionalArgumentsFormatter(),
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.UnicodeDecoder(),
            structlog.processors.JSONRenderer()
        ],
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )
    
    # 로그 레벨 설정
    logging.getLogger("uvicorn").setLevel(logging.INFO)
    logging.getLogger("uvicorn.access").setLevel(logging.INFO)
    logging.getLogger("sqlalchemy.engine").setLevel(logging.WARNING)
    logging.getLogger("sqlalchemy.pool").setLevel(logging.WARNING)
    
    # 개발 환경에서는 더 자세한 로그
    if settings.DEBUG:
        logging.getLogger("uvicorn").setLevel(logging.DEBUG)
        logging.getLogger("sqlalchemy.engine").setLevel(logging.INFO)

def get_logger(name: str) -> structlog.BoundLogger:
    """구조화된 로거 반환"""
    return structlog.get_logger(name)

def log_request(request_data: Dict[str, Any], logger: structlog.BoundLogger) -> None:
    """요청 로깅"""
    logger.info(
        "API Request",
        method=request_data.get("method"),
        path=request_data.get("path"),
        user_agent=request_data.get("user_agent"),
        ip_address=request_data.get("ip_address"),
        user_id=request_data.get("user_id")
    )

def log_response(response_data: Dict[str, Any], logger: structlog.BoundLogger) -> None:
    """응답 로깅"""
    logger.info(
        "API Response",
        status_code=response_data.get("status_code"),
        response_time=response_data.get("response_time"),
        path=response_data.get("path"),
        user_id=response_data.get("user_id")
    )

def log_error(error_data: Dict[str, Any], logger: structlog.BoundLogger) -> None:
    """에러 로깅"""
    logger.error(
        "API Error",
        error_type=error_data.get("error_type"),
        error_message=error_data.get("error_message"),
        path=error_data.get("path"),
        user_id=error_data.get("user_id"),
        stack_trace=error_data.get("stack_trace")
    )
