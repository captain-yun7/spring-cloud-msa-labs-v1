package com.captainyun7.initializer.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import javax.sql.DataSource;
import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class DataInitializerService {
    private final ObjectMapper objectMapper;
    private final Map<String, DataSource> dataSourceMap;
    
    /**
     * 모든 서비스 데이터 초기화
     */
    public void initializeAllServices() {
        initializeUsers();
        initializeProducts();
        initializeOrders();
        initializePayments();
        initializeNotifications();
        
        log.info("모든 서비스 데이터 초기화 완료");
    }
    
    /**
     * 모든 데이터 리셋 후 재초기화
     */
    public void resetAllData() {
        resetServiceData("user-service");
        resetServiceData("product-service");
        resetServiceData("order-service");
        resetServiceData("payment-service");
        resetServiceData("notification-service");
        
        initializeAllServices();
        log.info("모든 서비스 데이터 리셋 및 재초기화 완료");
    }
    
    /**
     * 특정 서비스 초기화
     */
    public void initializeService(String serviceName) {
        switch (serviceName) {
            case "user-service":
                initializeUsers();
                break;
            case "product-service":
                initializeProducts();
                break;
            case "order-service":
                initializeOrders();
                break;
            case "payment-service":
                initializePayments();
                break;
            case "notification-service":
                initializeNotifications();
                break;
            default:
                log.error("알 수 없는 서비스: {}", serviceName);
        }
    }
    
    // 사용자 데이터 초기화
    private void initializeUsers() {
        try {
            DataSource userDataSource = dataSourceMap.get("user-service");
            JdbcTemplate jdbcTemplate = new JdbcTemplate(userDataSource);
            
            // 테이블이 존재하는지 확인하고 없으면 생성
            try {
                jdbcTemplate.execute("CREATE TABLE IF NOT EXISTS users (" +
                        "id IDENTITY PRIMARY KEY, " +
                        "email VARCHAR(255) NOT NULL UNIQUE, " +
                        "password VARCHAR(255) NOT NULL, " +
                        "name VARCHAR(255) NOT NULL, " +
                        "role VARCHAR(50) NOT NULL)");
                log.info("users 테이블 생성 확인 완료");
            } catch (Exception e) {
                log.error("users 테이블 생성 실패", e);
                return;
            }
            
            try {
                if (isTableEmpty(userDataSource, "users")) {
                    ClassPathResource resource = new ClassPathResource("data/users.json");
                    List<Map<String, Object>> users = readJsonData(resource);
                    
                    try (Connection conn = userDataSource.getConnection()) {
                        try (PreparedStatement ps = conn.prepareStatement(
                                "INSERT INTO users (email, password, name, role) VALUES (?, ?, ?, ?)")) {
                            for (Map<String, Object> user : users) {
                                ps.setString(1, (String) user.get("email"));
                                ps.setString(2, (String) user.get("password"));
                                ps.setString(3, (String) user.get("name"));
                                ps.setString(4, (String) user.get("role"));
                                ps.addBatch();
                            }
                            ps.executeBatch();
                        }
                    }
                    log.info("사용자 데이터 초기화 완료");
                } else {
                    log.info("사용자 데이터가 이미 존재합니다");
                }
            } catch (Exception e) {
                log.error("사용자 데이터 초기화 실패", e);
            }
        } catch (Exception e) {
            log.error("사용자 데이터 초기화 실패", e);
        }
    }
    
    // 제품 데이터 초기화
    private void initializeProducts() {
        try {
            DataSource productDataSource = dataSourceMap.get("product-service");
            JdbcTemplate jdbcTemplate = new JdbcTemplate(productDataSource);
            
            // 테이블이 존재하는지 확인하고 없으면 생성
            try {
                jdbcTemplate.execute("CREATE TABLE IF NOT EXISTS products (" +
                        "id IDENTITY PRIMARY KEY, " +
                        "name VARCHAR(255) NOT NULL, " +
                        "description VARCHAR(1000) NOT NULL, " +
                        "price INT NOT NULL, " +
                        "stock INT NOT NULL)");
                log.info("products 테이블 생성 확인 완료");
            } catch (Exception e) {
                log.error("products 테이블 생성 실패", e);
                return;
            }
            
            try {
                if (isTableEmpty(productDataSource, "products")) {
                    ClassPathResource resource = new ClassPathResource("data/products.json");
                    List<Map<String, Object>> products = readJsonData(resource);
                    
                    try (Connection conn = productDataSource.getConnection()) {
                        try (PreparedStatement ps = conn.prepareStatement(
                                "INSERT INTO products (name, description, price, stock) VALUES (?, ?, ?, ?)")) {
                            for (Map<String, Object> product : products) {
                                ps.setString(1, (String) product.get("name"));
                                ps.setString(2, (String) product.get("description"));
                                ps.setInt(3, ((Number) product.get("price")).intValue());
                                ps.setInt(4, ((Number) product.get("stock")).intValue());
                                ps.addBatch();
                            }
                            ps.executeBatch();
                        }
                    }
                    log.info("제품 데이터 초기화 완료");
                } else {
                    log.info("제품 데이터가 이미 존재합니다");
                }
            } catch (Exception e) {
                log.error("제품 데이터 초기화 실패", e);
            }
        } catch (Exception e) {
            log.error("제품 데이터 초기화 실패", e);
        }
    }
    
    // 주문 데이터 초기화
    private void initializeOrders() {
        try {
            DataSource orderDataSource = dataSourceMap.get("order-service");
            JdbcTemplate jdbcTemplate = new JdbcTemplate(orderDataSource);
            
            // 테이블이 존재하는지 확인하고 없으면 생성
            try {
                jdbcTemplate.execute("CREATE TABLE IF NOT EXISTS orders (" +
                        "id IDENTITY PRIMARY KEY, " +
                        "user_id BIGINT NOT NULL, " +
                        "product_id BIGINT NOT NULL, " +
                        "quantity INT NOT NULL, " +
                        "status VARCHAR(50) NOT NULL)");
                log.info("orders 테이블 생성 확인 완료");
            } catch (Exception e) {
                log.error("orders 테이블 생성 실패", e);
                return;
            }
            
            try {
                if (isTableEmpty(orderDataSource, "orders")) {
                    ClassPathResource resource = new ClassPathResource("data/orders.json");
                    List<Map<String, Object>> orders = readJsonData(resource);
                    
                    try (Connection conn = orderDataSource.getConnection()) {
                        try (PreparedStatement ps = conn.prepareStatement(
                                "INSERT INTO orders (user_id, product_id, quantity, status) VALUES (?, ?, ?, ?)")) {
                            for (Map<String, Object> order : orders) {
                                ps.setLong(1, ((Number) order.get("userId")).longValue());
                                ps.setLong(2, ((Number) order.get("productId")).longValue());
                                ps.setInt(3, ((Number) order.get("quantity")).intValue());
                                ps.setString(4, (String) order.get("status"));
                                ps.addBatch();
                            }
                            ps.executeBatch();
                        }
                    }
                    log.info("주문 데이터 초기화 완료");
                } else {
                    log.info("주문 데이터가 이미 존재합니다");
                }
            } catch (Exception e) {
                log.error("주문 데이터 초기화 실패", e);
            }
        } catch (Exception e) {
            log.error("주문 데이터 초기화 실패", e);
        }
    }
    
    // 결제 데이터 초기화
    private void initializePayments() {
        try {
            DataSource paymentDataSource = dataSourceMap.get("payment-service");
            JdbcTemplate jdbcTemplate = new JdbcTemplate(paymentDataSource);
            
            // 테이블이 존재하는지 확인하고 없으면 생성
            try {
                jdbcTemplate.execute("CREATE TABLE IF NOT EXISTS payments (" +
                        "id IDENTITY PRIMARY KEY, " +
                        "order_id BIGINT NOT NULL, " +
                        "amount INT NOT NULL, " +
                        "status VARCHAR(50) NOT NULL, " +
                        "payment_method VARCHAR(50) NOT NULL)");
                log.info("payments 테이블 생성 확인 완료");
            } catch (Exception e) {
                log.error("payments 테이블 생성 실패", e);
                return;
            }
            
            try {
                if (isTableEmpty(paymentDataSource, "payments")) {
                    ClassPathResource resource = new ClassPathResource("data/payments.json");
                    List<Map<String, Object>> payments = readJsonData(resource);
                    
                    try (Connection conn = paymentDataSource.getConnection()) {
                        try (PreparedStatement ps = conn.prepareStatement(
                                "INSERT INTO payments (order_id, amount, status, payment_method) VALUES (?, ?, ?, ?)")) {
                            for (Map<String, Object> payment : payments) {
                                ps.setLong(1, ((Number) payment.get("orderId")).longValue());
                                ps.setInt(2, ((Number) payment.get("amount")).intValue());
                                ps.setString(3, (String) payment.get("status"));
                                ps.setString(4, (String) payment.get("paymentMethod"));
                                ps.addBatch();
                            }
                            ps.executeBatch();
                        }
                    }
                    log.info("결제 데이터 초기화 완료");
                } else {
                    log.info("결제 데이터가 이미 존재합니다");
                }
            } catch (Exception e) {
                log.error("결제 데이터 초기화 실패", e);
            }
        } catch (Exception e) {
            log.error("결제 데이터 초기화 실패", e);
        }
    }
    
    // 알림 데이터 초기화
    private void initializeNotifications() {
        try {
            DataSource notificationDataSource = dataSourceMap.get("notification-service");
            JdbcTemplate jdbcTemplate = new JdbcTemplate(notificationDataSource);
            
            // 테이블이 존재하는지 확인하고 없으면 생성
            try {
                jdbcTemplate.execute("CREATE TABLE IF NOT EXISTS notifications (" +
                        "id IDENTITY PRIMARY KEY, " +
                        "user_id BIGINT NOT NULL, " +
                        "message VARCHAR(1000) NOT NULL, " +
                        "type VARCHAR(50) NOT NULL, " +
                        "is_read BOOLEAN NOT NULL)");
                log.info("notifications 테이블 생성 확인 완료");
            } catch (Exception e) {
                log.error("notifications 테이블 생성 실패", e);
                return;
            }
            
            try {
                if (isTableEmpty(notificationDataSource, "notifications")) {
                    ClassPathResource resource = new ClassPathResource("data/notifications.json");
                    List<Map<String, Object>> notifications = readJsonData(resource);
                    
                    try (Connection conn = notificationDataSource.getConnection()) {
                        try (PreparedStatement ps = conn.prepareStatement(
                                "INSERT INTO notifications (user_id, message, type, is_read) VALUES (?, ?, ?, ?)")) {
                            for (Map<String, Object> notification : notifications) {
                                ps.setLong(1, ((Number) notification.get("userId")).longValue());
                                ps.setString(2, (String) notification.get("message"));
                                ps.setString(3, (String) notification.get("type"));
                                ps.setBoolean(4, (Boolean) notification.get("isRead"));
                                ps.addBatch();
                            }
                            ps.executeBatch();
                        }
                    }
                    log.info("알림 데이터 초기화 완료");
                } else {
                    log.info("알림 데이터가 이미 존재합니다");
                }
            } catch (Exception e) {
                log.error("알림 데이터 초기화 실패", e);
            }
        } catch (Exception e) {
            log.error("알림 데이터 초기화 실패", e);
        }
    }
    
    // 특정 서비스의 모든 데이터 삭제
    private void resetServiceData(String serviceName) {
        try {
            DataSource dataSource = dataSourceMap.get(serviceName);
            JdbcTemplate jdbcTemplate = new JdbcTemplate(dataSource);
            
            String tableName;
            switch (serviceName) {
                case "user-service":
                    tableName = "users";
                    break;
                case "product-service":
                    tableName = "products";
                    break;
                case "order-service":
                    tableName = "orders";
                    break;
                case "payment-service":
                    tableName = "payments";
                    break;
                case "notification-service":
                    tableName = "notifications";
                    break;
                default:
                    log.error("알 수 없는 서비스: {}", serviceName);
                    return;
            }
            
            jdbcTemplate.execute("DELETE FROM " + tableName);
            log.info("{} 서비스 데이터 리셋 완료", serviceName);
        } catch (Exception e) {
            log.error("{} 서비스 데이터 리셋 실패", serviceName, e);
        }
    }
    
    // 테이블이 비어있는지 확인
    private boolean isTableEmpty(DataSource dataSource, String tableName) {
        JdbcTemplate jdbcTemplate = new JdbcTemplate(dataSource);
        try {
            Integer count = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM " + tableName, Integer.class);
            return count == null || count == 0;
        } catch (Exception e) {
            // 테이블이 없는 경우 예외가 발생하므로 테이블이 비어있다고 간주
            return true;
        }
    }
    
    // JSON 파일 읽기
    private <T> List<T> readJsonData(ClassPathResource resource) throws IOException {
        try (InputStream inputStream = resource.getInputStream()) {
            return objectMapper.readValue(inputStream, new TypeReference<List<T>>() {});
        }
    }
} 