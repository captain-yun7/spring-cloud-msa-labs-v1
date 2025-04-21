package com.captainyun7.initializer.controller;

import com.captainyun7.initializer.service.DataInitializerService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/data")
@RequiredArgsConstructor
public class DataInitializerController {

    private final DataInitializerService dataInitializerService;

    /**
     * 모든 서비스 데이터 초기화
     */
    @PostMapping("/initialize")
    public ResponseEntity<Map<String, String>> initializeAllServices() {
        log.info("모든 서비스 데이터 초기화 API 호출");
        dataInitializerService.initializeAllServices();
        
        Map<String, String> response = new HashMap<>();
        response.put("status", "success");
        response.put("message", "모든 서비스 데이터 초기화 완료");
        return ResponseEntity.ok(response);
    }

    /**
     * 모든 데이터 리셋 후 재초기화
     */
    @PostMapping("/reset")
    public ResponseEntity<Map<String, String>> resetAllData() {
        log.info("모든 서비스 데이터 리셋 및 재초기화 API 호출");
        dataInitializerService.resetAllData();
        
        Map<String, String> response = new HashMap<>();
        response.put("status", "success");
        response.put("message", "모든 서비스 데이터 리셋 및 재초기화 완료");
        return ResponseEntity.ok(response);
    }

    /**
     * 특정 서비스 초기화
     */
    @PostMapping("/initialize/{serviceName}")
    public ResponseEntity<Map<String, String>> initializeService(@PathVariable String serviceName) {
        log.info("{} 서비스 데이터 초기화 API 호출", serviceName);
        
        Map<String, String> response = new HashMap<>();
        
        try {
            dataInitializerService.initializeService(serviceName);
            response.put("status", "success");
            response.put("message", serviceName + " 서비스 데이터 초기화 완료");
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            response.put("status", "error");
            response.put("message", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }

    /**
     * 서비스 상태 확인
     */
    @GetMapping("/status")
    public ResponseEntity<Map<String, String>> getStatus() {
        Map<String, String> status = new HashMap<>();
        status.put("status", "running");
        status.put("service", "data-initializer");
        return ResponseEntity.ok(status);
    }
} 