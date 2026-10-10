package org.metricshub.connector.it;

/**
 * Replays the NvidiaSmi connector against an NVIDIA A40 with NVIDIA-SMI 610.43.02 (issue #406),
 * whose frame buffer is almost full (inference engine) and whose (passive) fan reports 0%.
 */
class NvidiaSmiA40IT extends AbstractConnectorReplayIT {

	NvidiaSmiA40IT() {
		super("NvidiaSmiA40");
	}
}
