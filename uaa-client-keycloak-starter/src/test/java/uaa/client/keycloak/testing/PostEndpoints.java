package uaa.client.keycloak.testing;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class PostEndpoints {

    @PostMapping("/")
    public String postWithoutUrl() {
        return "postWithoutUrl";
    }

    @GetMapping("/postWithUrl")
    public String postWithUrl() {
        return "postWithUrl";
    }

    @GetMapping("/postWithUrl/{id}/hello/{name}")
    public String postWithUrlAndPathParam(@PathVariable("id") String id,
                                          @PathVariable("name") String name) {
        return "postWithUrlAndPathParam";
    }

}
