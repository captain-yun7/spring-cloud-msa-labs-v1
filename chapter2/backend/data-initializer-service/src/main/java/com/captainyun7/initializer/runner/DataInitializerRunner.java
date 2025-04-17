package com.captainyun7.initializer.runner;

import com.captainyun7.initializer.service.DataInitializerService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.DefaultApplicationArguments;
import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class DataInitializerRunner implements CommandLineRunner {

    private final DataInitializerService dataInitializerService;
    private final ApplicationContext applicationContext;

    @Override
    public void run(String... args) throws Exception {
        // 명령행 인수가 없으면 웹 모드로 실행
        if (args.length == 0) {
            log.info("웹 모드로 실행됩니다. http://localhost:8090 으로 접속하세요.");
            return;
        }

        String command = args[0];
        switch (command) {
            case "initialize":
                log.info("모든 서비스 데이터 초기화 시작");
                dataInitializerService.initializeAllServices();
                exitApplication();
                break;
            case "reset":
                log.info("모든 서비스 데이터 리셋 및 재초기화 시작");
                dataInitializerService.resetAllData();
                exitApplication();
                break;
            case "initialize-service":
                if (args.length < 2) {
                    log.error("서비스 이름이 필요합니다");
                    printUsage();
                    exitApplication();
                    return;
                }
                String serviceName = args[1];
                log.info("{} 서비스 데이터 초기화 시작", serviceName);
                dataInitializerService.initializeService(serviceName);
                exitApplication();
                break;
            default:
                log.error("알 수 없는 명령어: {}", command);
                printUsage();
                exitApplication();
        }
    }

    private void printUsage() {
        log.info("사용법:");
        log.info("  initialize           : 모든 서비스 데이터 초기화");
        log.info("  reset                : 모든 서비스 데이터 리셋 및 재초기화");
        log.info("  initialize-service [serviceName] : 특정 서비스 데이터 초기화");
        log.info("    지원되는 서비스 목록: user-service, product-service, order-service, payment-service, notification-service");
        log.info("");
        log.info("  또는 인수 없이 실행하여 웹 모드로 사용 (http://localhost:8090)");
    }
    
    private void exitApplication() {
        // 명령행 모드에서는 작업 완료 후 애플리케이션 종료
        System.exit(0);
    }
} 