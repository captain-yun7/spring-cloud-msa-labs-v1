-- MariaDB 혹은 MySQL 데이터베이스 초기화 스크립트
-- 마이크로서비스 아키텍처를 위한 각 서비스별 데이터베이스 생성

-- 기존 데이터베이스가 있으면 삭제하고 새로 생성 (개발/교육 환경용)
DROP DATABASE IF EXISTS `user-db`;
DROP DATABASE IF EXISTS `product-db`;
DROP DATABASE IF EXISTS `order-db`;
DROP DATABASE IF EXISTS `payment-db`;
DROP DATABASE IF EXISTS `notification-db`;

-- 각 서비스별 데이터베이스 생성
CREATE DATABASE `user-db` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE `product-db` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE `order-db` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE `payment-db` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE `notification-db` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 데이터베이스 사용 권한 부여
-- 교육용으로 root 계정 외에 별도의 사용자 계정을 만들어 사용할 수도 있음
GRANT ALL PRIVILEGES ON `user-db`.* TO 'root'@'%';
GRANT ALL PRIVILEGES ON `product-db`.* TO 'root'@'%';
GRANT ALL PRIVILEGES ON `order-db`.* TO 'root'@'%';
GRANT ALL PRIVILEGES ON `payment-db`.* TO 'root'@'%';
GRANT ALL PRIVILEGES ON `notification-db`.* TO 'root'@'%';

-- 권한 변경사항 적용
FLUSH PRIVILEGES; 