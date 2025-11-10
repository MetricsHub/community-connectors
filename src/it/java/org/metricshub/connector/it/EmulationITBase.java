package org.metricshub.connector.it;

import org.metricshub.agent.context.AgentContext;
import org.metricshub.agent.config.ResourceConfig;
import org.metricshub.agent.context.MetricDefinitions;
import org.metricshub.agent.opentelemetry.MetricsExporter;
import org.metricshub.agent.service.task.MonitoringTask;
import org.metricshub.agent.service.task.MonitoringTaskInfo;
import org.metricshub.configuration.YamlConfigurationProvider;
import org.metricshub.engine.extension.ExtensionManager;
import org.metricshub.engine.extension.IProtocolExtension;
import org.metricshub.engine.telemetry.TelemetryManager;
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

import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;

public class EmulationITBase extends AbstractITJob {

	private static ExtensionManager extensionManager;
	private final String connectorName;
	private TelemetryManager emulatedTelemetryManager;
	private String resourceGroupKey;
	private String resourceKey;
	private ResourceConfig resourceConfig;

	/**
	 * Constructor for the Emulation IT Base
	 * @param telemetryManager		The telemetry manager
	 * @param connectorName         The name of the connector (Identifier)
	 */
	public EmulationITBase(final String connectorName, final TelemetryManager telemetryManager) {
		super(telemetryManager);
		this.connectorName = connectorName;
	}

	/**
	 * Constructor for the Emulation IT Base
	 * 
	 * @param connectorName The name of the connector (Identifier)
	 */
	public EmulationITBase(final String connectorName) {
		this(connectorName, new TelemetryManager());
	}

	/**
	 * Create the Extension Manager with all required extensions for the IT tests
	 */
	static void createExtensionManger() {
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

		extensionManager = ExtensionManager.builder()
			.withProtocolExtensions(extensions)
			.withConfigurationProviderExtensions(Collections.singletonList(new YamlConfigurationProvider()))
			.build();

	}

	/**
	 * Copies telemetry manager from emulated telemetry manager
	 * @param emulatedTelemetryManager The emulated telemetry manager
	 */
	private void copyTelemetryManagerFromEmulation(final TelemetryManager emulatedTelemetryManager) {
		this.telemetryManager.setStrategyTime(emulatedTelemetryManager.getStrategyTime());
		this.telemetryManager.setEmulationInputDirectory(emulatedTelemetryManager.getEmulationInputDirectory());
		this.telemetryManager.setMonitors(emulatedTelemetryManager.getMonitors());
		this.telemetryManager.setHostConfiguration(emulatedTelemetryManager.getHostConfiguration());
		this.telemetryManager.setHostProperties(emulatedTelemetryManager.getHostProperties());
		this.telemetryManager.setRecordOutputDirectory(emulatedTelemetryManager.getRecordOutputDirectory());
		this.telemetryManager.setConnectorStore(emulatedTelemetryManager.getConnectorStore());
	}

	@Override
	public EmulationITBase withServerRecordData(String... strings) throws Exception {
		// Create the extension manager
		createExtensionManger();

		// Set the connector emulation files, expected result and config directory
		final String configFileDirectory = Paths.get("src", "it", "resources", connectorName, "config").toString();

		// Initialize the application context
		final AgentContext agentContext = new AgentContext(
			configFileDirectory, extensionManager);

		// Get the first resource group entry
		final Map.Entry<String, Map<String, TelemetryManager>> firstGroupEntry =
			agentContext.getTelemetryManagers()
				.entrySet()
				.stream()// skip the first
				.findFirst()
				.orElseThrow(() -> new NoSuchElementException("No second group found"));

		resourceGroupKey = firstGroupEntry.getKey();
		final Map<String, TelemetryManager> groupManagers = firstGroupEntry.getValue();

		// Get the first resource entry from that group
		final Map.Entry<String, TelemetryManager> firstResourceEntry =
			groupManagers.entrySet().iterator().next();

		resourceKey = firstResourceEntry.getKey();
		emulatedTelemetryManager = firstResourceEntry.getValue();

		// Get the matching ResourceConfig for that resource
		resourceConfig =
			agentContext.getAgentConfig()
				.getResources()
				.get(resourceKey);

		emulatedTelemetryManager.setEmulationInputDirectory(Paths.get("src", "it", "resources", connectorName, "emulation").toString());
		// Since telemetryManager is final in the super class,
		// we need to fill it with the emulated telemetryManager data
		copyTelemetryManagerFromEmulation(emulatedTelemetryManager);
		return this;
	}

	@Override
	public void stopServer() {
	}

	@Override
	public boolean isServerStarted() {
		return false;
	}

	/**
	 * Executes the monitoring task using the given information and
	 * @return ITJob An integration test job instance
	 */
	protected ITJob executeStrategies() {
		final MonitoringTaskInfo monitoringTaskInfo = MonitoringTaskInfo.builder()
			.telemetryManager(emulatedTelemetryManager)
			.resourceConfig(resourceConfig)
			.resourceKey(resourceKey)
			.resourceGroupKey(resourceGroupKey)
			.extensionManager(extensionManager)
			.metricsExporter(MetricsExporter.builder().build())
			.hostMetricDefinitions(new MetricDefinitions(new HashMap<>()))
			.build();
		new MonitoringTask(monitoringTaskInfo).run();
		return this;
	}
}
