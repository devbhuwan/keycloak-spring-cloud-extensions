package uaa.client.keycloak;

import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.AutoConfigureAfter;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.autoconfigure.web.WebMvcAutoConfiguration;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.task.AsyncTaskExecutor;
import org.springframework.retry.annotation.EnableRetry;
import org.springframework.retry.backoff.FixedBackOffPolicy;
import org.springframework.retry.policy.SimpleRetryPolicy;
import org.springframework.retry.support.RetryTemplate;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;
import uaa.client.keycloak.config.UaaClientKeycloakConfiguration;
import uaa.client.keycloak.registry.*;

import java.util.HashMap;
import java.util.concurrent.TimeUnit;

@Configuration
@EnableConfigurationProperties({UaaClientKeycloakConfiguration.class, AutoResourceRegistrationProperties.class})
@AutoConfigureAfter(WebMvcAutoConfiguration.class)
public class UaaClientKeycloakAutoConfiguration {

    @Bean
    public KeycloakResourceRegistry keycloakResourceRegistry() {
        return new KeycloakResourceRegistry();
    }

    @ConditionalOnProperty(value = AutoResourceRegistrationProperties.PREFIX_AUTO_RESOURCE_REGISTRATION + ".enabled", matchIfMissing = true)
    protected static class KeycloakAutoResourceRegistrationConfiguration {

        private static final String CRYPTO_SECRET = "secret";
        @Value("${spring.application.name:DEFAULT}")
        private String applicationName;

        @Bean
        public KeycloakAutoResourceRegistration keycloakAutoResourceRegistration(ApplicationContext context,
                                                                                 KeycloakResourceRegistry registry,
                                                                                 KeycloakResourceRegistration registration) {
            return new KeycloakAutoResourceRegistration(context, registry, registration);
        }

        @Bean
        public EndpointResourceFinder endpointResourceFinder() {
            return new EndpointResourceFinder();
        }

        @Bean
        protected KeycloakResourceRegistration keycloakResourceRegistration(ObjectProvider<EndpointResourceFinder> endpointResourceFinder,
                                                                            UaaClientKeycloakConfiguration uaaClientKeycloakConfiguration,
                                                                            RetryTemplate retryTemplate,
                                                                            AsyncTaskExecutor asyncTaskExecutor) {
            org.keycloak.authorization.client.Configuration keycloakConfig
                    = new org.keycloak.authorization.client.Configuration(uaaClientKeycloakConfiguration.getAuthServerUrl(),
                    uaaClientKeycloakConfiguration.getRealm(), uaaClientKeycloakConfiguration.getClient(),
                    new HashMap<String, Object>() {{
                        put(CRYPTO_SECRET, uaaClientKeycloakConfiguration.getClientSecret());
                    }}, null);
            return KeycloakResourceRegistration.builder()
                    .with(keycloakConfig)
                    .with(endpointResourceFinder)
                    .with(retryTemplate)
                    .with(asyncTaskExecutor)
                    .with(applicationName)
                    .build();
        }

        @Bean
        public RetryTemplate retryTemplate() {
            RetryTemplate retryTemplate = new RetryTemplate();
            FixedBackOffPolicy fixedBackOffPolicy = new FixedBackOffPolicy();
            fixedBackOffPolicy.setBackOffPeriod(TimeUnit.MINUTES.toMillis(1));
            retryTemplate.setBackOffPolicy(fixedBackOffPolicy);
            SimpleRetryPolicy retryPolicy = new SimpleRetryPolicy();
            retryPolicy.setMaxAttempts(10);
            retryTemplate.setRetryPolicy(retryPolicy);
            return retryTemplate;
        }

        @Bean
        public AsyncTaskExecutor asyncExecutor() {
            ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
            executor.setCorePoolSize(5);
            executor.setMaxPoolSize(10);
            executor.setQueueCapacity(25);
            return executor;
        }


        @EnableRetry
        protected static class KeycloakAutoResourceRegistrationRetry {
        }

    }

}
