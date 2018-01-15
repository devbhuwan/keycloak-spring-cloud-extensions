package uaa.keycloak.security;


import org.jboss.resteasy.core.Dispatcher;
import org.keycloak.models.KeycloakSession;
import org.keycloak.services.managers.ApplianceBootstrap;
import org.keycloak.services.resources.KeycloakApplication;

import javax.servlet.ServletContext;
import javax.ws.rs.core.Context;
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Proxy;
import java.util.Arrays;

public class EmbeddedKeycloakApplication extends KeycloakApplication {

    static KeycloakServerProperties keycloakServerProperties;

    public EmbeddedKeycloakApplication(@Context ServletContext context, @Context Dispatcher dispatcher) {

        super(augmentToRedirectContextPath(context), dispatcher);

        tryCreateMasterRealmAdminUser();
    }

    private static ServletContext augmentToRedirectContextPath(ServletContext servletContext) {

        ClassLoader classLoader = servletContext.getClassLoader();
        Class[] interfaces = {ServletContext.class};

        InvocationHandler invocationHandler = (proxy, method, args) -> {

            if ("getContextPath".equals(method.getName())) {
                return keycloakServerProperties.getContextPath();
            }

            if ("getInitParameter".equals(method.getName()) && args.length == 1 && "keycloak.embedded".equals(args[0])) {
                return "true";
            }

            System.out.printf("%s %s%n", method.getName(), Arrays.toString(args));

            return method.invoke(servletContext, args);
        };

        return ServletContext.class.cast(Proxy.newProxyInstance(classLoader, interfaces, invocationHandler));
    }

    private void tryCreateMasterRealmAdminUser() {

        KeycloakSession session = getSessionFactory().create();

        ApplianceBootstrap applianceBootstrap = new ApplianceBootstrap(session);

        KeycloakServerProperties.AdminUser admin = keycloakServerProperties.getAdminUser();

        try {
            session.getTransactionManager().begin();
            applianceBootstrap.createMasterRealmUser(admin.getUsername(), admin.getPassword());
            session.getTransactionManager().commit();
        } catch (Exception ex) {
            System.out.println("Couldn't create keycloak master admin user: " + ex.getMessage());
            session.getTransactionManager().rollback();
        }

        session.close();
    }
}
