import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.metricshub.engine.client.ClientsExecutor;
import org.metricshub.engine.configuration.HostConfiguration;
import org.metricshub.engine.configuration.IConfiguration;
import org.metricshub.engine.connector.model.ConnectorStore;
import org.metricshub.engine.connector.model.common.DeviceKind;
import org.metricshub.engine.extension.ExtensionManager;
import org.metricshub.engine.strategy.collect.CollectStrategy;
import org.metricshub.engine.strategy.collect.PrepareCollectStrategy;
import org.metricshub.engine.strategy.collect.ProtocolHealthCheckStrategy;
import org.metricshub.engine.strategy.detection.DetectionStrategy;
import org.metricshub.engine.strategy.discovery.DiscoveryStrategy;
import org.metricshub.engine.telemetry.HostProperties;
import org.metricshub.engine.telemetry.TelemetryManager;
import org.metricshub.extension.oscommand.OsCommandExtension;
import org.metricshub.extension.oscommand.SshConfiguration;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Collections;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

public class LmSensorsIT {
	static {
		Locale.setDefault(Locale.US);
	}

	private static final Path CONNECTOR_DIRECTORY = Paths.get(
			"src",
			"main",
			"connector",
			"hardware",
			"lmsensors"
	);

	private static final Path EMULATION_DIRECTORY = Paths.get(
			"src",
			"it",
			"resources",
			"ssh",
			"lmsensors",
			"emulation"
	);

	private static final String HOST = "anyHost";

	private static TelemetryManager telemetryManager;
	private static ClientsExecutor clientsExecutor;
	private static ExtensionManager extensionManager;

	@BeforeAll
	static void setUp() throws Exception {

		final SshConfiguration sshConfiguration = SshConfiguration.sshConfigurationBuilder()
				.hostname("any").username("any").password("any".toCharArray()).timeout(120L).build();

		final Map<Class<? extends IConfiguration>, IConfiguration> configurations = new HashMap<>();
		configurations.put(SshConfiguration.class, sshConfiguration);
		final HostConfiguration hostConfiguration = HostConfiguration
				.builder()
				.hostId(HOST)
				.hostname(HOST)
				.hostType(DeviceKind.LINUX)
				.configurations(configurations)
				.build();

		final ConnectorStore connectorStore = new ConnectorStore(CONNECTOR_DIRECTORY);

		telemetryManager =
				TelemetryManager.builder().connectorStore(connectorStore).hostConfiguration(hostConfiguration).hostProperties(HostProperties.builder().isLocalhost(false).build()).build();

		clientsExecutor = new ClientsExecutor(telemetryManager);

		extensionManager = ExtensionManager.builder().withProtocolExtensions(Collections.singletonList(new OsCommandExtension())).build();	}

	@Test
	void test() throws Exception {
		long discoveryTime = System.currentTimeMillis();
		long collectTime = discoveryTime + 60 * 2 * 1000;
		telemetryManager.setEmulationInputDirectory(EMULATION_DIRECTORY.toString());
		new EmulatedIntegrationTest(telemetryManager)
				.executeStrategies(
						new DetectionStrategy(telemetryManager, discoveryTime, clientsExecutor, extensionManager),
						new DiscoveryStrategy(telemetryManager, discoveryTime, clientsExecutor, extensionManager)
				)
				.executeStrategies(
						new PrepareCollectStrategy(telemetryManager, collectTime, clientsExecutor, extensionManager),
						new ProtocolHealthCheckStrategy(telemetryManager, collectTime, clientsExecutor, extensionManager),
						new CollectStrategy(telemetryManager, collectTime, clientsExecutor, extensionManager))
				.verifyExpected("ssh/lmsensors/expected.json");
	}
}