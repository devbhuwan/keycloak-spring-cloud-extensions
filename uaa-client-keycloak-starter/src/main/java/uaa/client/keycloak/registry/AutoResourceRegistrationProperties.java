package uaa.client.keycloak.registry;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

import static uaa.client.keycloak.config.UaaClientKeycloakConfiguration.PREFIX_UAA_KEYCLOAK_CLIENT;

@ConfigurationProperties(prefix = AutoResourceRegistrationProperties.PREFIX_AUTO_RESOURCE_REGISTRATION)
@Setter
@Getter
@Validated
public class AutoResourceRegistrationProperties {
    public static final String PREFIX_AUTO_RESOURCE_REGISTRATION = PREFIX_UAA_KEYCLOAK_CLIENT + ".resource.auto-registry";
    private boolean enabled = true;
}
