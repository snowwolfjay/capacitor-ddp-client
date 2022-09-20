import { registerPlugin } from '@capacitor/core';

import type { DDPClientPlugin } from './definitions';

const DDPClient = registerPlugin<DDPClientPlugin>('DDPClient', {
  web: () => import('./web').then(m => new m.DDPClientWeb()),
});

export * from './definitions';
export { DDPClient };
