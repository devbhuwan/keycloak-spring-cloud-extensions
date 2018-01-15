package uaa.client.registry;

public interface HealthCheckHandler {
    InstanceStatus getStatus(InstanceStatus status);
}
