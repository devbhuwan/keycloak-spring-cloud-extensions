package api.gateway.keycloak;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.netflix.zuul.EnableZuulProxy;
import org.springframework.context.annotation.ComponentScan;

@ComponentScan(basePackageClasses = RootPackage.class)
@EnableZuulProxy
@SpringBootApplication
public class ApiGatewayKeycloakServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(ApiGatewayKeycloakServiceApplication.class, args);
    }

}
