export interface DDPClientPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}
