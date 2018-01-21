package https.enforcer;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(HttpsEnforcerConfiguration.PREFIX_HTTPS_ENFORCER)
@Getter
@Setter
public class HttpsEnforcerConfiguration {

    public static final String PREFIX_HTTPS_ENFORCER = "https.enforcer";
    private boolean enabled = true;


}
