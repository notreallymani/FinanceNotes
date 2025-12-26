/**
 * Base Repository Pattern
 * 
 * Follows SOLID Principles:
 * - Single Responsibility: Handles only data access
 * - Open/Closed: Extendable without modification
 * - Liskov Substitution: All repositories can be substituted
 * - Dependency Inversion: Depends on abstractions (Model)
 */

class BaseRepository {
  constructor(Model) {
    this.Model = Model;
  }

  /**
   * Find by ID
   */
  async findById(id) {
    try {
      return await this.Model.findById(id);
    } catch (error) {
      throw new Error(`Failed to find ${this.Model.modelName} by ID: ${error.message}`);
    }
  }

  /**
   * Find one by query
   */
  async findOne(query) {
    try {
      return await this.Model.findOne(query);
    } catch (error) {
      throw new Error(`Failed to find ${this.Model.modelName}: ${error.message}`);
    }
  }

  /**
   * Find many by query
   */
  async findMany(query = {}, options = {}) {
    try {
      const { limit, skip, sort } = options;
      let queryBuilder = this.Model.find(query);

      if (skip) queryBuilder = queryBuilder.skip(skip);
      if (limit) queryBuilder = queryBuilder.limit(limit);
      if (sort) queryBuilder = queryBuilder.sort(sort);

      return await queryBuilder.exec();
    } catch (error) {
      throw new Error(`Failed to find ${this.Model.modelName} list: ${error.message}`);
    }
  }

  /**
   * Create new document
   */
  async create(data) {
    try {
      const document = new this.Model(data);
      return await document.save();
    } catch (error) {
      throw new Error(`Failed to create ${this.Model.modelName}: ${error.message}`);
    }
  }

  /**
   * Update by ID
   */
  async updateById(id, data, options = { new: true }) {
    try {
      return await this.Model.findByIdAndUpdate(id, data, options);
    } catch (error) {
      throw new Error(`Failed to update ${this.Model.modelName}: ${error.message}`);
    }
  }

  /**
   * Update one by query
   */
  async updateOne(query, data, options = { new: true }) {
    try {
      return await this.Model.findOneAndUpdate(query, data, options);
    } catch (error) {
      throw new Error(`Failed to update ${this.Model.modelName}: ${error.message}`);
    }
  }

  /**
   * Delete by ID
   */
  async deleteById(id) {
    try {
      return await this.Model.findByIdAndDelete(id);
    } catch (error) {
      throw new Error(`Failed to delete ${this.Model.modelName}: ${error.message}`);
    }
  }

  /**
   * Count documents
   */
  async count(query = {}) {
    try {
      return await this.Model.countDocuments(query);
    } catch (error) {
      throw new Error(`Failed to count ${this.Model.modelName}: ${error.message}`);
    }
  }

  /**
   * Check if document exists
   */
  async exists(query) {
    try {
      return await this.Model.exists(query);
    } catch (error) {
      throw new Error(`Failed to check ${this.Model.modelName} existence: ${error.message}`);
    }
  }
}

module.exports = BaseRepository;

