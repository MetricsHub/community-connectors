package org.metricshub.connector.it;

import org.metricshub.agent.context.AgentContext;
import org.metricshub.agent.config.ResourceConfig;
import org.metricshub.agent.context.MetricDefinitions;
import org.metricshub.agent.opentelemetry.MetricsExporter;
import org.metricshub.agent.service.task.MonitoringTask;
import org.metricshub.agent.service.task.MonitoringTaskInfo;
import org.metricshub.configuration.YamlConfigurationProvider;
import org.metricshub.engine.alert.AlertRule;
import org.metricshub.engine.common.helpers.JsonHelper;
import org.metricshub.engine.extension.ExtensionManager;
import org.metricshub.engine.extension.IProtocolExtension;
import org.metricshub.engine.telemetry.Monitor;
import org.metricshub.engine.telemetry.MonitorsVo;
import org.metricshub.engine.telemetry.TelemetryManager;
import org.metricshub.engine.telemetry.metric.AbstractMetric;
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

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;


public class EmulationITBase {

	private static ExtensionManager extensionManager;
	protected String connectorName;
	protected TelemetryManager telemetryManager;
	protected String configurationFilePath;

	public EmulationITBase(final String connectorName, final String configurationFilePath) {
		this.connectorName = connectorName;
		this.configurationFilePath = configurationFilePath;
	}

	public EmulationITBase(final String connectorName) {
		this(connectorName, "src/it/resources/" + connectorName + "/metricshub.yaml");
	}

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

	void emulateViaConfig() throws Exception {

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

			final String resourceGroupKey = firstGroupEntry.getKey();
			final Map<String, TelemetryManager> groupManagers = firstGroupEntry.getValue();

			// Get the first resource entry from that group
			final Map.Entry<String, TelemetryManager> firstResourceEntry =
					groupManagers.entrySet().iterator().next();

			final String resourceKey = firstResourceEntry.getKey();
			telemetryManager = firstResourceEntry.getValue();

			// Get the matching ResourceConfig for that resource
			final ResourceConfig resourceConfig =
					agentContext.getAgentConfig()
							.getResources()
							.get(resourceKey);

			telemetryManager.setEmulationInputDirectory(Paths.get("src", "it", "resources", connectorName, "emulation").toString());
			final MonitoringTaskInfo monitoringTaskInfo = MonitoringTaskInfo.builder()
					.telemetryManager(telemetryManager)
					.resourceConfig(resourceConfig)
					.resourceKey(resourceKey)
					.resourceGroupKey(resourceGroupKey)
					.extensionManager(extensionManager)
					.metricsExporter(MetricsExporter.builder().build())
					.hostMetricDefinitions(new MetricDefinitions(new HashMap<>()))
					.build();
			new MonitoringTask(monitoringTaskInfo).run();
	}

	/**
	 * Assert that expected and actual are equal.
	 *
	 * @param expected
	 * @param actual
	 */
	private static void assertMonitor(final Monitor expected, final Monitor actual) {
		assertMetrics(expected, actual);
		assertMonitorAttributes(expected, actual);
		assertConditionalCollection(expected, actual);
		assertLegacyTextParameters(expected, actual);
		assertAlertRules(expected, actual);
		assertNotNull(actual.getDiscoveryTime());

		final String expectedMonitorId = expected.getId();
		assertEquals(
				expected.getType(),
				actual.getType(),
				() -> String.format("Type doesn't match actual on monitor identifier: %s.", expectedMonitorId)
		);
		assertEquals(
				expected.getId(),
				actual.getId(),
				() -> String.format("ID doesn't match actual on monitor identifier: %s.", expectedMonitorId)
		);
		assertEquals(
				expected.isEndpoint(),
				actual.isEndpoint(),
				() -> String.format("isEndpoint doesn't match actual on monitor identifier: %s.", expectedMonitorId)
		);
		assertEquals(
				expected.isEndpointHost(),
				actual.isEndpointHost(),
				() -> String.format("isEndpointHost doesn't match actual on monitor identifier: %s.", expectedMonitorId)
		);
	}

	/**
	 * Assert that expected and actual alert rules are equal. <br>
	 * We only test testable/important data. For example the {@link AlertRule} conditionsChecker cannot be checked as it is a function
	 *
	 * @param expectedMonitor Expected monitor defined in the expected JSON file
	 * @param actualMonitor   Actual collected monitor from the {@link TelemetryManager}
	 */
	private static void assertAlertRules(final Monitor expectedMonitor, final Monitor actualMonitor) {
		// Alert rules are not available yet
		assertTrue(
				actualMonitor.getAlertRules().isEmpty(),
				() -> String.format("Alert rules are not empty on monitor identifier: %s.", actualMonitor.getId())
		);
	}

	/**
	 * Assert that expected and actual metrics are equal. <br>
	 *
	 * @param expectedMonitor Expected monitor defined in the expected JSON file
	 * @param actualMonitor   Actual collected monitor from the {@link TelemetryManager}
	 */
	private static void assertMetrics(final Monitor expectedMonitor, final Monitor actualMonitor) {
		for (final Map.Entry<String, AbstractMetric> expectedEntry : expectedMonitor.getMetrics().entrySet()) {
			final AbstractMetric expectedMetric = expectedEntry.getValue();
			final String expectedKey = expectedEntry.getKey();
			final String expectedMonitorId = expectedMonitor.getId();

			assertNotNull(
					expectedMetric,
					() -> String.format("Expected metric cannot be null for monitor identifier: %s.", expectedMonitorId)
			);

			final String expectedMetricName = expectedMetric.getName();

			final AbstractMetric actualMetric = actualMonitor.getMetric(expectedMetricName, expectedMetric.getClass());

			assertNotNull(
					actualMetric,
					() ->
							String.format(
									"Cannot find actual metric on monitor identifier: %s. Metric name: %s.",
									expectedMonitorId,
									expectedKey
							)
			);

			assertEquals(
					expectedMetricName,
					actualMetric.getName(),
					() ->
							String.format(
									"Name doesn’t match actual on monitor identifier: %s. Metric name: %s.",
									expectedMonitorId,
									expectedMetricName
							)
			);

			assertNotNull(
					actualMetric.getCollectTime(),
					() ->
							String.format(
									"CollectTime doesn’t match actual on monitor identifier: %s. Metric name: %s.",
									expectedMonitorId,
									expectedMetricName
							)
			);

			assertMetricAttributes(expectedMetric, actualMetric, expectedMonitorId);

			assertEquals(
					expectedMetric.isResetMetricTime(),
					actualMetric.isResetMetricTime(),
					() ->
							String.format(
									"IsResetMetricTime doesn't match actual on monitor identifier: %s.  Metric name: %s.",
									expectedMonitorId,
									expectedMetricName
							)
			);

			final Object expectedValue = expectedMetric.getValue();
			final Object actualValue = actualMetric.getValue();
			assertEquals(
					expectedValue,
					actualValue,
					() ->
							String.format(
									"Value doesn't match actual on monitor identifier: %s. Metric name: %s.",
									expectedMonitorId,
									expectedMetricName
							)
			);
		}
	}

	/**
	 * Assert that expected and actual monitor attributes are equal
	 *
	 * @param expectedMonitor Expected monitor defined in the expected JSON file
	 * @param actualMonitor   Actual collected monitor from the {@link TelemetryManager}
	 */
	private static void assertMonitorAttributes(final Monitor expectedMonitor, final Monitor actualMonitor) {
		for (final Map.Entry<String, String> expectedEntry : expectedMonitor.getAttributes().entrySet()) {
			final String expected = expectedEntry.getValue();
			final String expectedKey = expectedEntry.getKey();

			final String actual = actualMonitor.getAttribute(expectedKey);

			assertEquals(
					expected,
					actual,
					() ->
							String.format(
									"Actual monitor's attribute did not match expected: %s on monitor identifier: %s.",
									expectedKey,
									expectedMonitor.getId()
							)
			);
		}
	}

	/**
	 * Assert that expected and actual metric attributes are equal
	 *
	 * @param expectedMetric    Expected metric defined in the expected JSON file
	 * @param actualMetric      Actual collected metric from the {@link TelemetryManager}
	 * @param expectedMonitorId Used to add more context in case the test has failed
	 */
	private static void assertMetricAttributes(
			final AbstractMetric expectedMetric,
			final AbstractMetric actualMetric,
			final String expectedMonitorId
	) {
		for (final Map.Entry<String, String> expectedEntry : expectedMetric.getAttributes().entrySet()) {
			final String expected = expectedEntry.getValue();

			final String expectedKey = expectedEntry.getKey();

			final String actual = actualMetric.getAttributes().get(expectedKey);

			assertEquals(
					expected,
					actual,
					() ->
							String.format(
									"actual attribute did not match expected: %s on monitor identifier: %s.",
									expectedKey,
									expectedMonitorId
							)
			);
		}
	}

	/**
	 * Assert that expected and actual conditional collection are equal
	 *
	 * @param expectedMonitor Expected monitor defined in the expected JSON file
	 * @param actualMonitor   Actual collected monitor from the {@link TelemetryManager}
	 */
	private static void assertConditionalCollection(final Monitor expectedMonitor, final Monitor actualMonitor) {
		for (final Map.Entry<String, String> expectedEntry : expectedMonitor.getConditionalCollection().entrySet()) {
			final String expected = expectedEntry.getValue();
			final String expectedKey = expectedEntry.getKey();

			final String actual = expectedMonitor.getConditionalCollection().get(expectedKey);

			assertEquals(
					expected,
					actual,
					() ->
							String.format(
									"Actual conditional collection did not match expected: %s on monitor identifier: %s." + expectedKey,
									expectedMonitor.getId()
							)
			);
		}
	}

	/**
	 * Assert that expected and actual legacy text parameters are equal
	 *
	 * @param expectedMonitor Expected monitor defined in the expected JSON file
	 * @param actualMonitor   Actual collected monitor from the {@link TelemetryManager}
	 */
	private static void assertLegacyTextParameters(final Monitor expectedMonitor, final Monitor actualMonitor) {
		for (final Map.Entry<String, String> expectedEntry : expectedMonitor.getLegacyTextParameters().entrySet()) {
			final String expected = expectedEntry.getValue();
			final String expectedKey = expectedEntry.getKey();

			final String actual = expectedMonitor.getLegacyTextParameters().get(expectedKey);

			assertEquals(
					expected,
					actual,
					() ->
							String.format(
									"Actual LegacyTextParameter did not match expected: %s on monitor identifier: %s.",
									expectedKey,
									expectedMonitor.getId()
							)
			);
		}
	}

	/**
	 * Initialize the InputStream on the actual IT resource file path
	 * @param itResourcePath relative path inside the resources folder
	 * @return {@link InputStream} of the IT resource file
	 * @throws IOException
	 */
	public static InputStream getItResourceAsInputStream(String itResourcePath) throws IOException {
		return new FileInputStream(new File(getItResourcePath(itResourcePath)));
	}

	/**
	 * Get the IT resource file path
	 * @param itResourcePath relative path inside the resources folder
	 * @return the full path
	 */
	public static String getItResourcePath(final String itResourcePath) {
		return "src/it/resources/" + itResourcePath;
	}

	/**
	 * Verify that the collected monitors match the expected monitors defined in the expected JSON file
	 * @param expectedPath relative path inside the resources folder
	 * @throws Exception in case of any error
	 */
	public void verifyExpected(final String expectedPath) throws Exception {
		final InputStream is = getItResourceAsInputStream(expectedPath);
		final MonitorsVo expectedMonitors = JsonHelper.deserialize(is, MonitorsVo.class);

		final MonitorsVo actual = telemetryManager.getVo();

		assertEquals(expectedMonitors.getTotal(), actual.getTotal());

		expectedMonitors
				.getMonitors()
				.forEach(expectedMonitor -> {
					final String expectedType = expectedMonitor.getType();
					assertNotNull(
							expectedType,
							() ->
									String.format("Expected monitor 'type' cannot be null for monitor identifier: %s.", expectedMonitor.getId())
					);
					final Monitor actualMonitor = telemetryManager.findMonitorByTypeAndId(expectedType, expectedMonitor.getId());
					assertMonitor(expectedMonitor, actualMonitor);
				});
	}
}
