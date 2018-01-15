package uaa.client.keycloak.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

@ConfigurationProperties(prefix = UaaClientKeycloakConfiguration.PREFIX_UAA_KEYCLOAK_CLIENT)
@Validated
@Getter
@Setter
public class UaaClientKeycloakConfiguration {

    public static final String PREFIX_UAA_KEYCLOAK_CLIENT = "xcs.uaa.client.keycloak";
    private String authServerUrl;
    private String realm;
    private String client;
    private String clientSecret;
}
