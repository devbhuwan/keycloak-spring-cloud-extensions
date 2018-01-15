package uaa.client.registry;

public interface ResourceRegistry<R extends Registration> {

    void register(R registration);

    void deregister(R registration);

    void close();

}
