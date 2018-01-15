package uaa.client.keycloak.registry;

public class ResourceRegistrationException extends RuntimeException {

    public ResourceRegistrationException(String message) {
        super(message);
    }

    public ResourceRegistrationException(String message, Throwable cause) {
        super(message, cause);
    }
}
