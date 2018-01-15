package uaa.keycloak;

import org.assertj.core.api.Assertions;
import org.junit.Test;
import org.keycloak.authorization.client.AuthzClient;
import org.keycloak.authorization.client.Configuration;
import org.keycloak.authorization.client.representation.RegistrationResponse;
import org.keycloak.authorization.client.representation.ResourceRepresentation;
import org.keycloak.authorization.client.representation.ScopeRepresentation;
import org.keycloak.authorization.client.resource.ProtectedResource;

import java.util.HashMap;
import java.util.Set;

public class UaaKeycloakServiceApplicationAuthzClientTests extends UaaKeycloakServiceApplicationTests {

    @Test
    public void createResource() {
        AuthzClient authzClient = AuthzClient.create(
                new Configuration(this.authServer, "tobedeleted",
                        "fabric8-online-platform",
                        new HashMap<String, Object>() {{
                            put("secret", "addfc67d-8b85-49b1-969e-8f46c556fc67");
                        }}, null));
        // create a new resource representation with the information we want
        ResourceRepresentation newResource = new ResourceRepresentation();
        newResource.setName("New Resource");
        newResource.setType("urn:hello-world-authz:resources:example");
        newResource.addScope(new ScopeRepresentation("urn:hello-world-authz:scopes:view"));
        ProtectedResource resourceClient = authzClient.protection().resource();
        Set<String> existingResource = resourceClient.findByFilter("name=" + newResource.getName());
        if (!existingResource.isEmpty()) {
            resourceClient.delete(existingResource.iterator().next());
        }
        // create the resource on the server
        RegistrationResponse response = resourceClient.create(newResource);
        String resourceId = response.getId();
        // query the resource using its newly generated id
        ResourceRepresentation resource = resourceClient.findById(resourceId).getResourceDescription();
        Assertions.assertThat(resource).isNotNull();

    }

}
