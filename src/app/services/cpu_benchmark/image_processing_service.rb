# frozen_string_literal: true

module CpuBenchmark
  # ImageProcessingService provides CPU-intensive matrix/image processing calculations
  # for benchmarking purposes. All operations work on 2D arrays representing images.
  class ImageProcessingService
    # Apply blur filter to a matrix (simulates Gaussian blur)
    # Each cell is replaced with the average of its neighbors within radius
    #
    # @param matrix [Array<Array<Numeric>>] 2D array representing an image
    # @param radius [Integer] blur radius (default: 1)
    # @return [Array<Array<Float>>] blurred matrix
    def self.blur_matrix(matrix, radius: 1)
      raise ArgumentError, 'Matrix cannot be empty' if matrix.empty? || matrix.first.empty?
      raise ArgumentError, 'Radius must be positive' if radius < 1

      rows = matrix.size
      cols = matrix.first.size
      result = Array.new(rows) { Array.new(cols, 0.0) }

      (0...rows).each do |i|
        (0...cols).each do |j|
          sum = 0.0
          count = 0

          (-radius..radius).each do |di|
            (-radius..radius).each do |dj|
              ni = i + di
              nj = j + dj

              if ni >= 0 && ni < rows && nj >= 0 && nj < cols
                sum += matrix[ni][nj]
                count += 1
              end
            end
          end

          result[i][j] = sum / count
        end
      end

      result
    end

    # Apply a custom filter (kernel) to a matrix using convolution
    # This is a general-purpose convolution operation
    #
    # @param matrix [Array<Array<Numeric>>] 2D array representing an image
    # @param kernel [Array<Array<Numeric>>] 2D array representing the filter kernel
    # @return [Array<Array<Float>>] filtered matrix
    def self.apply_filter(matrix, kernel)
      raise ArgumentError, 'Matrix cannot be empty' if matrix.empty? || matrix.first.empty?
      raise ArgumentError, 'Kernel cannot be empty' if kernel.empty? || kernel.first.empty?
      raise ArgumentError, 'Kernel dimensions must be odd' if kernel.size.even? || kernel.first.size.even?

      matrix_convolution(matrix, kernel)
    end

    # Perform matrix convolution operation
    # This is the core operation for applying filters
    #
    # @param matrix [Array<Array<Numeric>>] input matrix
    # @param kernel [Array<Array<Numeric>>] convolution kernel
    # @return [Array<Array<Float>>] convolved matrix
    def self.matrix_convolution(matrix, kernel)
      rows = matrix.size
      cols = matrix.first.size
      k_rows = kernel.size
      k_cols = kernel.first.size
      k_center_row = k_rows / 2
      k_center_col = k_cols / 2

      result = Array.new(rows) { Array.new(cols, 0.0) }

      (0...rows).each do |i|
        (0...cols).each do |j|
          sum = 0.0

          (0...k_rows).each do |ki|
            (0...k_cols).each do |kj|
              ni = i + ki - k_center_row
              nj = j + kj - k_center_col

              if ni >= 0 && ni < rows && nj >= 0 && nj < cols
                sum += matrix[ni][nj] * kernel[ki][kj]
              end
            end
          end

          result[i][j] = sum
        end
      end

      result
    end

    # Predefined filters for common image processing operations
    module Filters
      # Edge detection filter (Sobel-like)
      EDGE_DETECTION = [
        [-1, -1, -1],
        [-1,  8, -1],
        [-1, -1, -1]
      ].freeze

      # Sharpen filter
      SHARPEN = [
        [ 0, -1,  0],
        [-1,  5, -1],
        [ 0, -1,  0]
      ].freeze

      # Box blur filter
      BOX_BLUR = [
        [1.0 / 9, 1.0 / 9, 1.0 / 9],
        [1.0 / 9, 1.0 / 9, 1.0 / 9],
        [1.0 / 9, 1.0 / 9, 1.0 / 9]
      ].freeze

      # Identity filter (no change)
      IDENTITY = [
        [0, 0, 0],
        [0, 1, 0],
        [0, 0, 0]
      ].freeze
    end
  end
end
