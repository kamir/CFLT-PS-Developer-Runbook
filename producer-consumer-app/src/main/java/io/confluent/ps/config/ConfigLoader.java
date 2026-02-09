package io.confluent.ps.config;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Properties;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Loads Kafka configuration from properties files with environment-based overrides.
 *
 * Resolution order:
 *   1. Base config from classpath  (application.properties)
 *   2. Environment overlay          (application-{env}.properties)
 *   3. External file override       (-Dconfig.file=/path/to/file)
 *   4. Individual system properties (-Dbootstrap.servers=...)
 *   5. Environment variables        (KAFKA_BOOTSTRAP_SERVERS)
 */
public class ConfigLoader {

    private static final Logger log = LoggerFactory.getLogger(ConfigLoader.class);

    private ConfigLoader() {}

    public static Properties load() {
        String env = System.getProperty("app.env",
                System.getenv().getOrDefault("APP_ENV", "dev"));
        return load(env);
    }

    public static Properties load(String environment) {
        Properties props = new Properties();

        // 1. Base config from classpath
        loadFromClasspath(props, "application.properties");

        // 2. Environment-specific overlay
        loadFromClasspath(props, "application-" + environment + ".properties");

        // 3. External file override
        String externalFile = System.getProperty("config.file");
        if (externalFile != null) {
            loadFromFile(props, Path.of(externalFile));
        }

        // 4. System property overrides (dotted keys)
        System.getProperties().forEach((k, v) -> {
            String key = k.toString();
            if (key.startsWith("kafka.")) {
                props.setProperty(key.substring(6), v.toString());
            }
        });

        // 5. Environment variable overrides
        applyEnvOverrides(props);

        log.info("Loaded configuration for environment='{}', bootstrap.servers='{}'",
                environment, props.getProperty("bootstrap.servers", "<not set>"));

        return props;
    }

    private static void loadFromClasspath(Properties props, String resource) {
        try (InputStream is = ConfigLoader.class.getClassLoader().getResourceAsStream(resource)) {
            if (is != null) {
                props.load(is);
                log.debug("Loaded classpath resource: {}", resource);
            } else {
                log.debug("Classpath resource not found (skipped): {}", resource);
            }
        } catch (IOException e) {
            log.warn("Failed to load classpath resource: {}", resource, e);
        }
    }

    private static void loadFromFile(Properties props, Path path) {
        try (InputStream is = Files.newInputStream(path)) {
            props.load(is);
            log.info("Loaded external config file: {}", path);
        } catch (IOException e) {
            log.warn("Failed to load external config file: {}", path, e);
        }
    }

    private static void applyEnvOverrides(Properties props) {
        mapEnv("KAFKA_BOOTSTRAP_SERVERS",        "bootstrap.servers",        props);
        mapEnv("KAFKA_SECURITY_PROTOCOL",        "security.protocol",        props);
        mapEnv("KAFKA_SASL_MECHANISM",           "sasl.mechanism",           props);
        mapEnv("KAFKA_SASL_JAAS_CONFIG",         "sasl.jaas.config",         props);
        mapEnv("SCHEMA_REGISTRY_URL",            "schema.registry.url",      props);
        mapEnv("SCHEMA_REGISTRY_BASIC_AUTH",     "basic.auth.credentials.source", props);
        mapEnv("SCHEMA_REGISTRY_USER_INFO",      "schema.registry.basic.auth.user.info", props);
        mapEnv("KAFKA_CLIENT_ID",                "client.id",                props);
        mapEnv("KAFKA_GROUP_ID",                 "group.id",                 props);
    }

    private static void mapEnv(String envVar, String propKey, Properties props) {
        String value = System.getenv(envVar);
        if (value != null && !value.isBlank()) {
            props.setProperty(propKey, value);
        }
    }
}
