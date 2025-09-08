import org.junit.jupiter.api.Test;
import org.metricshub.engine.telemetry.TelemetryManager;

public class EmulationIT {
	@Test
	void testWinStorageSpaces() throws Exception {
		final String connectorName = "WinStorageSpaces";
		final EmulationITBase emulationITBase = new EmulationITBase(connectorName);
		emulationITBase.emulateViaConfig();
		emulationITBase.verifyExpected("expected/" + connectorName + "/expected.json");
	}
}

