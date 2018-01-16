package foo.service;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@ComponentScan(basePackageClasses = RootPackage.class)
@SpringBootApplication
public class FooServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(FooServiceApplication.class, args);
    }

    @RestController
    static class Endpoint {

        @GetMapping("/api/foo")
        public String foo() {
            return "foo is alive";
        }
    }

}
