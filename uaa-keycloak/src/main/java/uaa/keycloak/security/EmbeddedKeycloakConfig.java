package uaa.keycloak.security;

import org.apache.commons.lang.StringUtils;
import org.jboss.resteasy.plugins.server.servlet.HttpServlet30Dispatcher;
import org.jboss.resteasy.plugins.server.servlet.ResteasyContextParameters;
import org.keycloak.services.filters.KeycloakSessionServletFilter;
import org.keycloak.services.listeners.KeycloakSessionDestroyListener;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.boot.web.servlet.ServletListenerRegistrationBean;
import org.springframework.boot.web.servlet.ServletRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import javax.naming.*;
import javax.naming.spi.NamingManager;
import javax.sql.DataSource;
import java.util.Optional;

@Configuration
class EmbeddedKeycloakConfig {

    @Bean
    ServletRegistrationBean keycloakJaxRsApplication(KeycloakServerProperties keycloakServerProperties, @SuppressWarnings("SpringJavaInjectionPointsAutowiringInspection") DataSource dataSource) throws Exception {

        mockJndiEnvironment(dataSource);
        //FIXME: hack to propagate Spring Boot Properties to Keycloak Application
        EmbeddedKeycloakApplication.keycloakServerProperties = keycloakServerProperties;
        enableImportRealms(keycloakServerProperties);
        enableJpaVendorIfAvaliable(keycloakServerProperties);
        ServletRegistrationBean servlet = new ServletRegistrationBean(new HttpServlet30Dispatcher());
        servlet.addInitParameter("javax.ws.rs.Application", EmbeddedKeycloakApplication.class.getName());
        servlet.addInitParameter(ResteasyContextParameters.RESTEASY_SERVLET_MAPPING_PREFIX, keycloakServerProperties.getContextPath());
        servlet.addInitParameter(ResteasyContextParameters.RESTEASY_USE_CONTAINER_FORM_PARAMS, "true");
        servlet.addUrlMappings(keycloakServerProperties.getContextPath() + "/*");
        servlet.setLoadOnStartup(1);
        servlet.setAsyncSupported(true);

        return servlet;
    }

    private void enableJpaVendorIfAvaliable(KeycloakServerProperties keycloakServerProperties) {
        if (StringUtils.isNotBlank(keycloakServerProperties.getConnectionsJpaDriver()) && StringUtils.isNotBlank(keycloakServerProperties.getConnectionsJpaDriverDialect())) {
            System.setProperty("keycloak.connectionsJpa.driver", keycloakServerProperties.getConnectionsJpaDriver());
            System.setProperty("keycloak.connectionsJpa.driverDialect", keycloakServerProperties.getConnectionsJpaDriverDialect());
        }
    }

    private void enableImportRealms(KeycloakServerProperties keycloakServerProperties) {
        if (StringUtils.isNotBlank(keycloakServerProperties.getImportRealms())) {
            StringBuilder importPaths = new StringBuilder();
            final String[] paths = keycloakServerProperties.getImportRealms().split(",");
            for (int i = 0; i < paths.length; i++) {
                importPaths
                        .append(Optional.ofNullable(
                                EmbeddedKeycloakApplication.class.getClassLoader().getResource(paths[i]))
                                .orElseThrow(IllegalArgumentException::new)
                                .getPath());
                if (i < paths.length - 1) {
                    importPaths.append(",");
                }
            }
            System.setProperty("keycloak.import", importPaths.toString());
        }
    }

    @Bean
    ServletListenerRegistrationBean<KeycloakSessionDestroyListener> keycloakSessionDestroyListener() {
        return new ServletListenerRegistrationBean<>(new KeycloakSessionDestroyListener());
    }

    @Bean
    FilterRegistrationBean keycloakSessionManagement(KeycloakServerProperties keycloakServerProperties) {

        FilterRegistrationBean filter = new FilterRegistrationBean();
        filter.setName("Keycloak Session Management");
        filter.setFilter(new KeycloakSessionServletFilter());
        filter.addUrlPatterns(keycloakServerProperties.getContextPath() + "/*");

        return filter;
    }


    private void mockJndiEnvironment(DataSource dataSource) throws NamingException {
        NamingManager.setInitialContextFactoryBuilder((env) -> (environment) -> new InitialContext() {

            @Override
            public Object lookup(Name name) {
                return lookup(name.toString());
            }

            @Override
            public Object lookup(String name) {

                if ("spring/datasource".equals(name)) {
                    return dataSource;
                }

                return null;
            }

            @Override
            public NameParser getNameParser(String name) {
                return CompositeName::new;
            }

            @Override
            public void close() {
                //NOOP
            }
        });
    }
}