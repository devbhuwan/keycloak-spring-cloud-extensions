package uaa.client.keycloak;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.context.embedded.LocalServerPort;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;
import uaa.client.keycloak.registry.KeycloakResourceRegistration;

@RunWith(SpringRunner.class)
@SpringBootTest(classes = RootApplication.class, webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
public class AbstractUaaKeycloakIntegrationTests {

    @LocalServerPort
    protected int port;

    @Autowired
    private KeycloakResourceRegistration keycloakResourceRegistration;

    @Test
    public void contextLoads() {
    }


}
