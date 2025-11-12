# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CpuBenchmark::ImageProcessingService, type: :service do
  describe '.blur_matrix' do
    context 'with edge cases' do
      it 'raises ArgumentError for empty matrix' do
        expect { described_class.blur_matrix([]) }.to raise_error(ArgumentError, 'Matrix cannot be empty')
        expect { described_class.blur_matrix([[]]) }.to raise_error(ArgumentError, 'Matrix cannot be empty')
      end

      it 'raises ArgumentError for invalid radius' do
        matrix = [[1, 2], [3, 4]]
        expect { described_class.blur_matrix(matrix, radius: 0) }.to raise_error(ArgumentError, 'Radius must be positive')
        expect { described_class.blur_matrix(matrix, radius: -1) }.to raise_error(ArgumentError, 'Radius must be positive')
      end
    end

    context 'with small matrices (correctness tests)' do
      it 'blurs a simple 3x3 matrix with radius 1' do
        matrix = [
          [1, 2, 3],
          [4, 5, 6],
          [7, 8, 9]
        ]
        result = described_class.blur_matrix(matrix, radius: 1)

        # Center pixel should be average of all 9 pixels
        expect(result[1][1]).to eq(5.0)

        # Corner pixels should be average of 4 neighbors
        expect(result[0][0]).to eq((1 + 2 + 4 + 5) / 4.0)
      end

      it 'handles uniform matrix' do
        matrix = [
          [5, 5, 5],
          [5, 5, 5],
          [5, 5, 5]
        ]
        result = described_class.blur_matrix(matrix, radius: 1)

        # All pixels should remain 5
        result.each do |row|
          row.each do |pixel|
            expect(pixel).to eq(5.0)
          end
        end
      end
    end

    context 'with large matrices (performance tests)' do
      it 'blurs a 300x300 matrix' do
        matrix = Array.new(300) { Array.new(300) { rand(0..255) } }
        result = described_class.blur_matrix(matrix, radius: 2)

        expect(result.size).to eq(300)
        expect(result.first.size).to eq(300)
      end

      it 'blurs a 500x500 matrix' do
        matrix = Array.new(500) { Array.new(500) { rand(0..255) } }
        result = described_class.blur_matrix(matrix, radius: 1)

        expect(result.size).to eq(500)
        expect(result.first.size).to eq(500)
      end
    end
  end

  describe '.apply_filter' do
    context 'with edge cases' do
      it 'raises ArgumentError for empty matrix or kernel' do
        matrix = [[1, 2], [3, 4]]
        kernel = [[1, 0], [0, 1]]

        expect { described_class.apply_filter([], kernel) }.to raise_error(ArgumentError, 'Matrix cannot be empty')
        expect { described_class.apply_filter(matrix, []) }.to raise_error(ArgumentError, 'Kernel cannot be empty')
      end

      it 'raises ArgumentError for even-sized kernel' do
        matrix = [[1, 2], [3, 4]]
        even_kernel = [[1, 0], [0, 1]]

        expect { described_class.apply_filter(matrix, even_kernel) }.to raise_error(ArgumentError, 'Kernel dimensions must be odd')
      end
    end

    context 'with small matrices (correctness tests)' do
      let(:matrix) do
        [
          [1, 2, 3, 4],
          [5, 6, 7, 8],
          [9, 10, 11, 12],
          [13, 14, 15, 16]
        ]
      end

      it 'applies identity filter (no change)' do
        result = described_class.apply_filter(matrix, described_class::Filters::IDENTITY)
        expect(result[1][1]).to eq(6.0)
        expect(result[2][2]).to eq(11.0)
      end

      it 'applies edge detection filter' do
        result = described_class.apply_filter(matrix, described_class::Filters::EDGE_DETECTION)
        expect(result.size).to eq(4)
        expect(result.first.size).to eq(4)
      end

      it 'applies sharpen filter' do
        result = described_class.apply_filter(matrix, described_class::Filters::SHARPEN)
        expect(result.size).to eq(4)
        expect(result.first.size).to eq(4)
      end
    end

    context 'with large matrices (performance tests)' do
      it 'applies filter to 400x400 matrix' do
        matrix = Array.new(400) { Array.new(400) { rand(0..255) } }
        result = described_class.apply_filter(matrix, described_class::Filters::EDGE_DETECTION)

        expect(result.size).to eq(400)
        expect(result.first.size).to eq(400)
      end

      it 'applies filter to 600x600 matrix' do
        matrix = Array.new(600) { Array.new(600) { rand(0..255) } }
        result = described_class.apply_filter(matrix, described_class::Filters::BOX_BLUR)

        expect(result.size).to eq(600)
        expect(result.first.size).to eq(600)
      end
    end
  end

  describe '.matrix_convolution' do
    context 'with small matrices (correctness tests)' do
      let(:matrix) do
        [
          [1, 2, 3],
          [4, 5, 6],
          [7, 8, 9]
        ]
      end

      let(:simple_kernel) do
        [
          [0, 0, 0],
          [0, 1, 0],
          [0, 0, 0]
        ]
      end

      it 'performs convolution correctly with identity kernel' do
        result = described_class.matrix_convolution(matrix, simple_kernel)

        # Identity kernel should preserve values
        expect(result[1][1]).to eq(5.0)
      end

      it 'performs convolution with averaging kernel' do
        avg_kernel = [
          [1.0 / 9, 1.0 / 9, 1.0 / 9],
          [1.0 / 9, 1.0 / 9, 1.0 / 9],
          [1.0 / 9, 1.0 / 9, 1.0 / 9]
        ]
        result = described_class.matrix_convolution(matrix, avg_kernel)

        # Center should be average of all 9 values
        expect(result[1][1]).to be_within(0.01).of(5.0)
      end
    end

    context 'with large matrices (performance tests)' do
      let(:large_matrix) { Array.new(700) { Array.new(700) { rand(0..255) } } }
      let(:kernel) { described_class::Filters::SHARPEN }

      it 'performs convolution on 700x700 matrix' do
        result = described_class.matrix_convolution(large_matrix, kernel)

        expect(result.size).to eq(700)
        expect(result.first.size).to eq(700)
      end
    end
  end

  describe 'Filters module' do
    it 'provides EDGE_DETECTION filter' do
      expect(described_class::Filters::EDGE_DETECTION).to be_a(Array)
      expect(described_class::Filters::EDGE_DETECTION.size).to eq(3)
    end

    it 'provides SHARPEN filter' do
      expect(described_class::Filters::SHARPEN).to be_a(Array)
      expect(described_class::Filters::SHARPEN.size).to eq(3)
    end

    it 'provides BOX_BLUR filter' do
      expect(described_class::Filters::BOX_BLUR).to be_a(Array)
      expect(described_class::Filters::BOX_BLUR.size).to eq(3)
    end

    it 'provides IDENTITY filter' do
      expect(described_class::Filters::IDENTITY).to be_a(Array)
      expect(described_class::Filters::IDENTITY.size).to eq(3)
    end
  end
end
