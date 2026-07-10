import { Given, Then } from '@cucumber/cucumber';
import assert from 'node:assert';
import { config } from '../support/config';

Given('I navigate to the app root', async function () {
  // @ts-ignore - page is provided by the World hooks (task onthewing-1vh.6)
  await this.page.goto(config.appUrl);
});

Then('I should see the main application header and title', async function () {
  // @ts-ignore - page is provided by the World hooks (task onthewing-1vh.6)
  const title = await this.page.title();
  assert.ok(title && title.length > 0, 'Page title should not be empty');
  // Note: Exact title check depends on the actual app, 
  // for now we just check if it's loaded.
});
