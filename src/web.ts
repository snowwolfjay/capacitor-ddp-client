import { WebPlugin } from '@capacitor/core';

import type { DDPClientPlugin } from './definitions';

export class DDPClientWeb extends WebPlugin implements DDPClientPlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}
