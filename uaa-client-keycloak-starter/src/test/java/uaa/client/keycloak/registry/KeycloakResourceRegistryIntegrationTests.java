package uaa.client.keycloak.registry;

import org.junit.Test;
import org.springframework.boot.test.mock.mockito.MockBean;
import uaa.client.keycloak.AbstractUaaKeycloakIntegrationTests;

import java.util.Arrays;
import java.util.concurrent.TimeUnit;

import static org.mockito.Mockito.when;

public class KeycloakResourceRegistryIntegrationTests extends AbstractUaaKeycloakIntegrationTests {

    @MockBean
    private EndpointResourceFinder endpointResourceFinder;

    @Test
    public void givenEndpoints_whenRegister_thenRetryTillKeycloakAuthServerNotAvailable() throws InterruptedException {
        when(endpointResourceFinder.findAll()).thenReturn(Arrays.asList("foo", "bar"));
    }
}