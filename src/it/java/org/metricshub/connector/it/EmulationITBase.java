package org.metricshub.connector.it;

import org.metricshub.agent.context.AgentContext;
import org.metricshub.agent.context.MetricDefinitions;
import org.metricshub.agent.opentelemetry.MetricsExporter;
import org.metricshub.agent.service.task.MonitoringTask;
import org.metricshub.agent.service.task.MonitoringTaskInfo;
import org.metricshub.configuration.YamlConfigurationProvider;
import org.metricshub.engine.extension.ExtensionManager;
import org.metricshub.engine.extension.IProtocolExtension;
import org.metricshub.extension.http.HttpExtension;
import org.metricshub.extension.ipmi.IpmiExtension;
import org.metricshub.extension.jdbc.JdbcExtension;
import org.metricshub.extension.jmx.JmxExtension;
import org.metricshub.extension.oscommand.OsCommandExtension;
import org.metricshub.extension.ping.PingExtension;
import org.metricshub.extension.snmp.SnmpExtension;
import org.metricshub.extension.snmpv3.SnmpV3Extension;
import org.metricshub.extension.wbem.WbemExtension;
import org.metricshub.extension.winrm.WinRmExtension;
import org.metricshub.extension.wmi.WmiExtension;
import org.metricshub.it.job.AbstractITJob;
import org.metricshub.it.job.ITJob;

import java.io.IOException;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.NoSuchElementException;

/**
 * Base class for Emulation Integration Tests
 */
public class EmulationITBase extends AbstractITJob {

	private static final ExtensionManager EXTENSION_MANAGER = createExtensionManger();

	private final String connectorId;
	private MonitoringTaskInfo monitoringTaskInfo;

	/**
	 * Constructor for the Emulation IT Base
	 *
	 * @param connectorId        The unique identifier of the connector
	 * @param monitoringTaskInfo The monitoring task information
	 */
	public EmulationITBase(final String connectorId, final MonitoringTaskInfo monitoringTaskInfo) {
		super(monitoringTaskInfo.getTelemetryManager());
		this.connectorId = connectorId;
		this.monitoringTaskInfo = monitoringTaskInfo;
	}

	/**
	 * Constructor for the Emulation IT Base
	 *
	 * @param connectorId The unique identifier of the connector
	 * @throws IOException In case of IO errors during initialization
	 */
	public EmulationITBase(final String connectorId) throws IOException {
		this(connectorId, newMonitoringTaskInfo(connectorId));
	}

	/**
	 * Prepare the Monitoring Task Info for the given connector name
	 *
	 * @param connectorId The identifier of the connector
	 * @return MonitoringTaskInfo The prepared monitoring task info
	 * @throws IOException In case of IO errors during initialization
	 */
	private static MonitoringTaskInfo newMonitoringTaskInfo(final String connectorId) throws IOException {
		// Set the connector emulation files, expected result and config directory
		final String configFileDirectory = Paths.get("src", "it", "resources", connectorName, "config").toString();

		// Initialize the application context
		final var agentContext = new AgentContext(configFileDirectory, EXTENSION_MANAGER);

		// Get the first resource group entry
		final var firstGroupEntry = agentContext
			.getTelemetryManagers()
			.entrySet()
			.stream()// skip the first
			.findFirst()
			.orElseThrow(() -> new NoSuchElementException("No second group found"));

		final var resourceGroupKey = firstGroupEntry.getKey();
		final var groupManagers = firstGroupEntry.getValue();

		// Get the first resource entry from that group
		final var firstResourceEntry =
			groupManagers.entrySet().iterator().next();

		final var resourceKey = firstResourceEntry.getKey();
		final var telemetryManager = firstResourceEntry.getValue();

		// Get the matching ResourceConfig for that resource
		final var resourceConfig = agentContext
			.getAgentConfig()
			.getResources()
			.get(resourceKey);

		return MonitoringTaskInfo.builder()
			.telemetryManager(telemetryManager)
			.resourceConfig(resourceConfig)
			.resourceKey(resourceKey)
			.resourceGroupKey(resourceGroupKey)
			.extensionManager(EXTENSION_MANAGER)
			.metricsExporter(MetricsExporter.builder().build())
			.hostMetricDefinitions(new MetricDefinitions(new HashMap<>()))
			.build();
	}

	/**
	 * Create the Extension Manager with all required extensions for the IT tests
	 *
	 * @return ExtensionManager The created extension manager
	 */
	private static ExtensionManager createExtensionManger() {
		final List<IProtocolExtension> extensions = new ArrayList<>();
		extensions.add(new HttpExtension());
		extensions.add(new IpmiExtension());
		extensions.add(new JdbcExtension());
		extensions.add(new JmxExtension());
		extensions.add(new OsCommandExtension());
		extensions.add(new PingExtension());
		extensions.add(new SnmpExtension());
		extensions.add(new SnmpV3Extension());
		extensions.add(new WbemExtension());
		extensions.add(new WinRmExtension());
		extensions.add(new WmiExtension());

		return ExtensionManager.builder()
			.withProtocolExtensions(extensions)
			.withConfigurationProviderExtensions(
				Collections.singletonList(new YamlConfigurationProvider())
			)
			.build();

	}

	@Override
	public EmulationITBase withServerRecordData(String... strings) throws Exception {

		telemetryManager.setEmulationInputDirectory(
			Paths.get("src", "it", "resources", connectorId, "emulation").toString()
		);

		return this;
	}

	@Override
	public void stopServer() {
		// No server to stop in emulation mode
	}

	@Override
	public boolean isServerStarted() {
		return false;
	}

	/**
	 * Executes a new monitoring task with the monitoring task info
	 *
	 * @return ITJob An integration test job instance
	 */
	protected ITJob executeStrategies() {
		new MonitoringTask(monitoringTaskInfo).run();
		return this;
	}

}

