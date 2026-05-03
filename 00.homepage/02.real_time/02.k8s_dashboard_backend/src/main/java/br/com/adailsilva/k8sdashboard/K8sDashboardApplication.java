package br.com.adailsilva.k8sdashboard;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class K8sDashboardApplication {

    public static void main(String[] args) {
        SpringApplication.run(K8sDashboardApplication.class, args);
    }
}
