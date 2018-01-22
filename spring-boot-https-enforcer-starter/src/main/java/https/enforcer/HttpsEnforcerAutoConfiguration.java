package https.enforcer;

import lombok.extern.slf4j.Slf4j;
import org.apache.catalina.connector.Connector;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.autoconfigure.websocket.TomcatWebSocketContainerCustomizer;
import org.springframework.boot.context.embedded.tomcat.TomcatEmbeddedServletContainerFactory;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@EnableConfigurationProperties(HttpsEnforcerConfiguration.class)
public class HttpsEnforcerAutoConfiguration {

    @ConditionalOnProperty(value = HttpsEnforcerConfiguration.PREFIX_HTTPS_ENFORCER + ".enabled", matchIfMissing = true)
    @Slf4j
    @Configuration
    protected static class HttpsTomcatWebSocketContainerCustomizer extends TomcatWebSocketContainerCustomizer {

        @Value("${server.port:8443}")
        private int serverPort;

        @Override
        public void doCustomize(TomcatEmbeddedServletContainerFactory tomcatContainer) {
            tomcatContainer.addAdditionalTomcatConnectors(getHttpConnector());
            super.doCustomize(tomcatContainer);
        }

        private Connector getHttpConnector() {
            log.info("Enabled http connector in port [{}] redirect to [{}]", 8080, serverPort);
            Connector connector = new Connector("org.apache.coyote.http11.Http11NioProtocol");
            connector.setScheme("http");
            connector.setPort(8080);
            connector.setSecure(false);
            connector.setRedirectPort(serverPort);
            return connector;
        }

    }
}
