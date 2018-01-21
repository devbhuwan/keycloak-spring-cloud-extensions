package foo.service;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.web.bind.annotation.*;

@ComponentScan(basePackageClasses = RootPackage.class)
@SpringBootApplication
public class FooServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(FooServiceApplication.class, args);
    }

    @RestController
    @RequestMapping("foo")
    static class Endpoint {

        @GetMapping
        public String foo() {
            return "foo is alive";
        }

        @GetMapping("bar")
        public String bar() {
            return "bar is alive";
        }

        @PostMapping("submit")
        public Dto submit(@RequestBody Dto dto) {
            return dto;
        }
    }

    @Getter
    @Setter
    class Dto {
        private String name;
    }
}
