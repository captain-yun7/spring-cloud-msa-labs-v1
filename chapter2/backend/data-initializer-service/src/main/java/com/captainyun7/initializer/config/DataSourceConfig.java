package com.captainyun7.initializer.config;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.jdbc.DataSourceBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import javax.sql.DataSource;
import java.util.HashMap;
import java.util.Map;

@Configuration
public class DataSourceConfig {

    @Bean
    @Qualifier("userServiceDataSource")
    public DataSource userServiceDataSource() {
        return DataSourceBuilder.create()
                .driverClassName("org.h2.Driver")
                .url("jdbc:h2:file:../user-service/data/userdb")
                .username("sa")
                .password("")
                .build();
    }

    @Bean
    @Qualifier("productServiceDataSource")
    public DataSource productServiceDataSource() {
        return DataSourceBuilder.create()
                .driverClassName("org.h2.Driver")
                .url("jdbc:h2:file:../product-service/data/productdb")
                .username("sa")
                .password("")
                .build();
    }

    @Bean
    @Qualifier("orderServiceDataSource")
    public DataSource orderServiceDataSource() {
        return DataSourceBuilder.create()
                .driverClassName("org.h2.Driver")
                .url("jdbc:h2:file:../order-service/data/orderdb")
                .username("sa")
                .password("")
                .build();
    }

    @Bean
    @Qualifier("paymentServiceDataSource")
    public DataSource paymentServiceDataSource() {
        return DataSourceBuilder.create()
                .driverClassName("org.h2.Driver")
                .url("jdbc:h2:file:../payment-service/data/paymentdb")
                .username("sa")
                .password("")
                .build();
    }

    @Bean
    @Qualifier("notificationServiceDataSource")
    public DataSource notificationServiceDataSource() {
        return DataSourceBuilder.create()
                .driverClassName("org.h2.Driver")
                .url("jdbc:h2:file:../notification-service/data/notificationdb")
                .username("sa")
                .password("")
                .build();
    }

    @Bean
    public Map<String, DataSource> dataSourceMap(
            @Qualifier("userServiceDataSource") DataSource userServiceDataSource,
            @Qualifier("productServiceDataSource") DataSource productServiceDataSource,
            @Qualifier("orderServiceDataSource") DataSource orderServiceDataSource,
            @Qualifier("paymentServiceDataSource") DataSource paymentServiceDataSource,
            @Qualifier("notificationServiceDataSource") DataSource notificationServiceDataSource) {
        
        Map<String, DataSource> dataSourceMap = new HashMap<>();
        dataSourceMap.put("user-service", userServiceDataSource);
        dataSourceMap.put("product-service", productServiceDataSource);
        dataSourceMap.put("order-service", orderServiceDataSource);
        dataSourceMap.put("payment-service", paymentServiceDataSource);
        dataSourceMap.put("notification-service", notificationServiceDataSource);
        return dataSourceMap;
    }
} 