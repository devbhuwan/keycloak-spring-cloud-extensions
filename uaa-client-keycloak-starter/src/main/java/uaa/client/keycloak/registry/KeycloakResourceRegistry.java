package uaa.client.keycloak.registry;

import lombok.extern.slf4j.Slf4j;
import org.keycloak.authorization.client.resource.ProtectionResource;
import org.springframework.retry.RetryCallback;
import uaa.client.registry.ResourceRegistry;

import java.io.Closeable;

@Slf4j
public class KeycloakResourceRegistry implements ResourceRegistry<KeycloakResourceRegistration>, Closeable {

    @Override
    public void register(KeycloakResourceRegistration reg) {
        maybeInitializeClient(reg);
        if (log.isInfoEnabled()) {
            log.info("Registering application " + reg.getAppName()
                    + " with keycloak");
        }
        registerResources(reg.getResourceFinder().getIfAvailable(), reg);
    }

    private void maybeInitializeClient(KeycloakResourceRegistration reg) {
        if (reg.getAuthzClient() == null)
            reg.retryToBuildKeycloakClient();
    }

    private void registerResources(final EndpointResourceFinder endpointResourceFinder, final KeycloakResourceRegistration reg) {
        reg.getAsyncTaskExecutor().execute(() -> {
            reg.getRetryTemplate().execute((RetryCallback<Void, ResourceRegistrationException>) context -> {
                log.info("[Retry] To register resources of application " + reg.getAppName() + " with keycloak retry callback");
                try {

                    ProtectionResource protectionResource = reg.getAuthzClient().protection();
                    endpointResourceFinder.findAll().forEach(s -> {

                    });
                    log.info("Successfully registered resources of application " + reg.getAppName() + " with keycloak");
                    return null;
                } catch (Exception ex) {
                    throw new ResourceRegistrationException("Unable to register resources of application "
                            + reg.getAppName() + " with keycloak", ex);
                }
            }, context -> {
                log.info("[Retry] To connect with keycloak for authzClient");
                maybeInitializeClient(reg);
                return null;
            });
        });
    }

    @Override
    public void deregister(KeycloakResourceRegistration registration) {

    }

    @Override
    public void close() {

    }

}
