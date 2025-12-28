/// # 파일 로거 서비스
///
/// AI API 호출 결과를 텍스트 파일로 저장합니다.
/// 조건부 export로 웹/비웹 플랫폼 지원.

export 'file_logger_stub.dart' if (dart.library.html) 'file_logger_web.dart';
