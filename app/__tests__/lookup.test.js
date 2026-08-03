const { lookup } = require('../src/lookup');

describe('lookup', () => {
  const data = [
    { text: 'use .gitignore wisely', category: 'git' },
    { text: 'squash before merging', category: 'git' },
    { text: 'multi-stage builds keep images slim', category: 'docker' },
  ];

  it('returns a random item from the full array when no category is given', () => {
    const result = lookup(data);
    expect(data).toContainEqual(result);
  });

  it('returns an item matching the given category', () => {
    const result = lookup(data, 'git');
    expect(result.category).toBe('git');
  });

  it('throws when the category matches nothing in the data', () => {
    expect(() => lookup(data, 'nope')).toThrow();
  });
});
