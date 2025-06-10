package com.example.spreadsheet;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import com.example.spreadsheet.entity.User;
import com.example.spreadsheet.repository.UserRepository;

@SpringBootApplication
public class SpreadsheetApplication {
    
    public static void main(String[] args) {
        SpringApplication.run(SpreadsheetApplication.class, args);
    }
    
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
    
    @Bean
    CommandLineRunner init(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        return args -> {
            // Create default admin user if not exists
            if (!userRepository.existsByUsername("admin")) {
                User admin = new User();
                admin.setUsername("admin");
                admin.setEmail("admin@example.com");
                admin.setPassword(passwordEncoder.encode("admin123"));
                userRepository.save(admin);
                System.out.println("Default admin user created - username: admin, password: admin123");
            }
            
            // Create test user if not exists
            if (!userRepository.existsByUsername("testuser")) {
                User testUser = new User();
                testUser.setUsername("testuser");
                testUser.setEmail("test@example.com");
                testUser.setPassword(passwordEncoder.encode("test123"));
                userRepository.save(testUser);
                System.out.println("Test user created - username: testuser, password: test123");
            }
        };
    }
}