import Bonjour from 'bonjour-service';
import { config } from '../config';

let bonjourInstance: InstanceType<typeof Bonjour> | null = null;

export function startAdvertising(): void {
  bonjourInstance = new Bonjour();
  bonjourInstance.publish({
    name: `WristCode-${config.hostname}`,
    type: 'wristcode',
    port: config.port,
    txt: {
      version: config.version,
      hostname: config.hostname,
    },
  });
  console.log(`[Bonjour] Advertising _wristcode._tcp on port ${config.port}`);
}

export function stopAdvertising(): void {
  if (bonjourInstance) {
    bonjourInstance.unpublishAll();
    bonjourInstance.destroy();
    bonjourInstance = null;
    console.log('[Bonjour] Stopped advertising');
  }
}
