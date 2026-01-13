package org.metricshub.connector.it;

import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/**
 * Integration tests for various connectors using recorded data replay.
 */
class ConnectorReplayIT {

	/**
	 * Replays recorded data for the specified connector and verifies the expected results.
	 *
	 * @param connectorId The identifier of the connector to test
	 * @throws Exception In case of any errors during the test execution
	 */
	@ParameterizedTest
	@ValueSource(strings = {
		"WinStorageSpaces",
		"MIB2",
		"Lmsensors",
		"Linux",
		//"LinuxIpmiTool",
		"MySql",
		"WbemGenDiskNT",
		"SmartMonLinux",
		"MIB2Switch",
		"WindowsFile",
		"LinuxFile",
		"AMDRadeon",
		"IpmiTool"
	})
	void testConnectorReplay(String connectorId) throws Exception {
		new EmulationITBase(connectorId)
			.withServerRecordData()
			.executeStrategies()
			.verifyExpected(connectorId + "/expected/expected.json");
	}
}
