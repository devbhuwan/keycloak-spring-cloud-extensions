package uaa.client.keycloak.registry;

import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationContext;
import org.springframework.context.SmartLifecycle;

import java.util.concurrent.atomic.AtomicBoolean;

@Slf4j
public class KeycloakAutoResourceRegistration implements SmartLifecycle {

    private AtomicBoolean running = new AtomicBoolean(false);
    private ApplicationContext context;

    private KeycloakResourceRegistry resourceRegistry;

    private KeycloakResourceRegistration registration;

    public KeycloakAutoResourceRegistration(ApplicationContext context, KeycloakResourceRegistry registry, KeycloakResourceRegistration registration) {
        this.context = context;
        this.resourceRegistry = registry;
        this.registration = registration;
    }

    @Override
    public boolean isAutoStartup() {
        return true;
    }

    @Override
    public void stop(Runnable callback) {
        stop();
        callback.run();
    }

    @Override
    public void start() {
        if (!this.running.get()) {
            this.resourceRegistry.register(this.registration);
            this.running.set(true);
        }
    }

    @Override
    public void stop() {
        this.running.set(false);
    }

    @Override
    public boolean isRunning() {
        return false;
    }

    @Override
    public int getPhase() {
        return 0;
    }
}
