import lombok.NonNull;
import org.metricshub.engine.telemetry.TelemetryManager;
import org.metricshub.it.job.AbstractITJob;
import org.metricshub.it.job.ITJob;


public class EmulatedIntegrationTest extends AbstractITJob {

	public EmulatedIntegrationTest(
			@NonNull TelemetryManager telemetryManager) {
		super(telemetryManager);
	}

	@Override
	public ITJob withServerRecordData(String... dataPaths) throws Exception {
		return this;
	}

	@Override
	public void stopServer() {
		return;
	}

	@Override
	public boolean isServerStarted() {
		return true;
	}
}
