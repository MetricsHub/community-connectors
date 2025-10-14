import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

public class ConnectorReplayIT {

	@ParameterizedTest
	@ValueSource(strings = {
			"WinStorageSpaces",
			"MIB2",
			"Lmsensors",
			"Linux",
			"MySql",
			"WbemGenDiskNT",
			"SmartMonLinux"
	})
	void testEmulation(String connectorName) throws Exception {
		final EmulationITBase emulation = new EmulationITBase(connectorName);
		emulation.emulateViaConfig();
		emulation.verifyExpected(connectorName + "/expected/expected.json");
	}
}
