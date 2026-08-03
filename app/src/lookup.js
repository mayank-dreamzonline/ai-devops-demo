/**
 * Given an array of { text, category } items, returns a random item.
 * If `category` is provided, restricts the pool to matching items and
 * throws if none match.
 */
function lookup(data, category) {
  if (!Array.isArray(data) || data.length === 0) {
    throw new Error('lookup: data must be a non-empty array');
  }

  let pool = data;

  if (category !== undefined && category !== null && category !== '') {
    pool = data.filter((item) => item.category === category);

    if (pool.length === 0) {
      const error = new Error(`lookup: no items found for category "${category}"`);
      error.status = 400;
      throw error;
    }
  }

  return pool[Math.floor(Math.random() * pool.length)];
}

module.exports = { lookup };
