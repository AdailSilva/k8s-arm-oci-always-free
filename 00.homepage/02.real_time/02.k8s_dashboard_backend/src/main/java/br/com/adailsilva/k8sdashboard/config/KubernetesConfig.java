package br.com.adailsilva.k8sdashboard.config;

import com.google.gson.Gson;
import com.google.gson.TypeAdapter;
import com.google.gson.TypeAdapterFactory;
import com.google.gson.reflect.TypeToken;
import com.google.gson.stream.JsonReader;
import com.google.gson.stream.JsonWriter;
import io.kubernetes.client.openapi.ApiClient;
import io.kubernetes.client.openapi.JSON;
import io.kubernetes.client.openapi.apis.AppsV1Api;
import io.kubernetes.client.openapi.apis.CoreV1Api;
import io.kubernetes.client.openapi.apis.NetworkingV1Api;
import io.kubernetes.client.util.Config;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.io.IOException;

@Slf4j
@Configuration
public class KubernetesConfig {

    @Value("${kubernetes.in-cluster:true}")
    private boolean inCluster;

    @Value("${kubernetes.kubeconfig-path:}")
    private String kubeconfigPath;

    /**
     * Configures the Kubernetes API client.
     *
     * When running INSIDE the cluster (inCluster=true), uses the ServiceAccount
     * token automatically mounted at /var/run/secrets/kubernetes.io/serviceaccount.
     *
     * When running OUTSIDE the cluster (inCluster=false), loads the kubeconfig
     * from the path specified in kubernetes.kubeconfig-path (or ~/.kube/config).
     *
     * WORKAROUND: client-java up to 21.0.2 calls validateJsonObject() inside
     * CustomTypeAdapterFactory which throws IllegalArgumentException for any
     * field not explicitly modelled — regardless of Gson leniency settings.
     * Kubernetes 1.31+ returns new fields (userNamespaces, recursiveReadOnlyMounts,
     * appArmorProfile) not yet in the model. We prepend a TypeAdapterFactory
     * that wraps every adapter's read() in a try-catch to suppress those exceptions.
     */
    @Bean
    public ApiClient apiClient() throws IOException {
        ApiClient client;

        if (inCluster) {
            log.info("Kubernetes client: using in-cluster ServiceAccount configuration");
            client = Config.fromCluster();
        } else {
            if (kubeconfigPath != null && !kubeconfigPath.isBlank()) {
                log.info("Kubernetes client: loading kubeconfig from {}", kubeconfigPath);
                client = Config.fromConfig(kubeconfigPath);
            } else {
                log.info("Kubernetes client: loading default kubeconfig (~/.kube/config)");
                client = Config.defaultClient();
            }
        }

        client.setConnectTimeout(10_000);
        client.setReadTimeout(30_000);
        client.setWriteTimeout(30_000);

        // ── Workaround: suppress validateJsonObject() for unknown K8s 1.31+ fields ──
        // The CustomTypeAdapterFactory in each model class calls validateJsonObject()
        // which throws IllegalArgumentException for unknown fields — this is Java code,
        // not Gson behavior, so setLenient() does not help.
        // We prepend a TypeAdapterFactory that wraps every adapter's read() in a
        // try-catch, intercepting the exception before it reaches Spring MVC.
        JSON json = new JSON();
        Gson original = json.getGson();

        TypeAdapterFactory suppressingFactory = new TypeAdapterFactory() {
            @Override
            public <T> TypeAdapter<T> create(Gson gson, TypeToken<T> type) {
                TypeAdapter<T> delegate = gson.getDelegateAdapter(this, type);
                return new TypeAdapter<T>() {
                    @Override
                    public void write(JsonWriter out, T value) throws IOException {
                        delegate.write(out, value);
                    }

                    @Override
                    public T read(JsonReader in) throws IOException {
                        try {
                            return delegate.read(in);
                        } catch (IllegalArgumentException e) {
                            log.debug("Ignored unknown Kubernetes API field: {}",
                                    e.getMessage());
                            return null;
                        }
                    }
                };
            }
        };

        Gson patchedGson = original.newBuilder()
                .registerTypeAdapterFactory(suppressingFactory)
                .create();

        json.setGson(patchedGson);
        client.setJSON(json);
        // ─────────────────────────────────────────────────────────────────────────

        io.kubernetes.client.openapi.Configuration.setDefaultApiClient(client);
        return client;
    }

    @Bean
    public CoreV1Api coreV1Api(ApiClient apiClient) {
        return new CoreV1Api(apiClient);
    }

    @Bean
    public AppsV1Api appsV1Api(ApiClient apiClient) {
        return new AppsV1Api(apiClient);
    }

    @Bean
    public NetworkingV1Api networkingV1Api(ApiClient apiClient) {
        return new NetworkingV1Api(apiClient);
    }
}
