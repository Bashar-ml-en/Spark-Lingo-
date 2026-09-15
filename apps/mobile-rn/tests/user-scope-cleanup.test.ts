import { describe, expect, it, vi } from 'vitest';

import { UserScopeCleanupRegistry } from '../src/application/user-scope-cleanup';

describe('UserScopeCleanupRegistry', () => {
  it('clears query data before notifying every registered user-state owner', () => {
    const events: string[] = [];
    const registry = new UserScopeCleanupRegistry(() => events.push('query-cache'));
    registry.register((reason) => events.push(`drafts:${reason}`));
    registry.register((reason) => events.push(`telemetry:${reason}`));

    registry.clear('identity-changed');

    expect(events).toEqual([
      'query-cache',
      'drafts:identity-changed',
      'telemetry:identity-changed',
    ]);
  });

  it('stops calling an owner after it unregisters', () => {
    const callback = vi.fn();
    const registry = new UserScopeCleanupRegistry(vi.fn());
    const unregister = registry.register(callback);
    unregister();

    registry.clear('signed-out');

    expect(callback).not.toHaveBeenCalled();
  });

  it('continues clearing other state owners when one owner is defective', () => {
    const followingOwner = vi.fn();
    const registry = new UserScopeCleanupRegistry(vi.fn());
    registry.register(() => {
      throw new Error('simulated cleanup failure');
    });
    registry.register(followingOwner);

    registry.clear('account-deleted');

    expect(followingOwner).toHaveBeenCalledWith('account-deleted');
  });
});
