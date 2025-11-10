# frozen_string_literal: true

module CpuBenchmark
  # TextSimilarityService provides CPU-intensive text similarity calculations
  # for benchmarking purposes.
  class TextSimilarityService
    # Calculate Levenshtein distance between two strings
    # This measures the minimum number of single-character edits required
    # to change one string into another.
    #
    # @param str1 [String] the first string
    # @param str2 [String] the second string
    # @return [Integer] the Levenshtein distance
    def self.levenshtein_distance(str1, str2)
      return str2.length if str1.empty?
      return str1.length if str2.empty?

      matrix = Array.new(str1.length + 1) { Array.new(str2.length + 1) }

      (0..str1.length).each { |i| matrix[i][0] = i }
      (0..str2.length).each { |j| matrix[0][j] = j }

      (1..str1.length).each do |i|
        (1..str2.length).each do |j|
          cost = str1[i - 1] == str2[j - 1] ? 0 : 1
          matrix[i][j] = [
            matrix[i - 1][j] + 1,      # deletion
            matrix[i][j - 1] + 1,      # insertion
            matrix[i - 1][j - 1] + cost # substitution
          ].min
        end
      end

      matrix[str1.length][str2.length]
    end

    # Calculate cosine similarity between two texts
    # Returns a value between 0 (completely different) and 1 (identical)
    #
    # @param text1 [String] the first text
    # @param text2 [String] the second text
    # @return [Float] the cosine similarity (0.0 to 1.0)
    def self.cosine_similarity(text1, text2)
      return 0.0 if text1.empty? || text2.empty?

      words1 = text1.downcase.split
      words2 = text2.downcase.split

      return 0.0 if words1.empty? || words2.empty?

      # Build vocabulary
      vocabulary = (words1 + words2).uniq

      # Create frequency vectors
      vector1 = vocabulary.map { |word| words1.count(word) }
      vector2 = vocabulary.map { |word| words2.count(word) }

      # Calculate dot product
      dot_product = vector1.zip(vector2).sum { |a, b| a * b }

      # Calculate magnitudes
      magnitude1 = Math.sqrt(vector1.sum { |x| x * x })
      magnitude2 = Math.sqrt(vector2.sum { |x| x * x })

      return 0.0 if magnitude1.zero? || magnitude2.zero?

      dot_product / (magnitude1 * magnitude2)
    end

    # Find the most similar texts from candidates for a target text
    # Returns candidates sorted by similarity (highest first)
    #
    # @param target [String] the target text
    # @param candidates [Array<String>] array of candidate texts
    # @param limit [Integer] maximum number of results to return
    # @return [Array<Hash>] array of hashes with :text and :similarity keys
    def self.find_similar_texts(target, candidates, limit: 5)
      return [] if target.empty? || candidates.empty?

      similarities = candidates.map do |candidate|
        {
          text: candidate,
          similarity: cosine_similarity(target, candidate)
        }
      end

      similarities.sort_by { |item| -item[:similarity] }.take(limit)
    end
  end
end
