package uaa.client.keycloak.testing;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class GetEndpoints {

    @GetMapping("/")
    public String getWithoutUrl() {
        return "postWithoutUrl";
    }

    @GetMapping("/getWithUrl")
    public String getWithUrl() {
        return "postWithUrl";
    }

    @GetMapping("/getWithUrl/{id}/hello/{name}")
    public String getWithUrlAndPathParam(@PathVariable("id") String id,
                                         @PathVariable("name") String name) {
        return "postWithUrlAndPathParam";
    }

}
