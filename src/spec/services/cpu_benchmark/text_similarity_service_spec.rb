# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CpuBenchmark::TextSimilarityService, type: :service do
  describe '.levenshtein_distance' do
    context 'with edge cases' do
      it 'returns length of non-empty string when one string is empty' do
        expect(described_class.levenshtein_distance('', 'hello')).to eq(5)
        expect(described_class.levenshtein_distance('hello', '')).to eq(5)
      end

      it 'returns 0 for identical strings' do
        expect(described_class.levenshtein_distance('hello', 'hello')).to eq(0)
      end
    end

    context 'with small strings (correctness tests)' do
      it 'calculates correct distance for simple cases' do
        expect(described_class.levenshtein_distance('kitten', 'sitting')).to eq(3)
        expect(described_class.levenshtein_distance('saturday', 'sunday')).to eq(3)
      end

      it 'calculates correct distance for single character differences' do
        expect(described_class.levenshtein_distance('cat', 'bat')).to eq(1)
        expect(described_class.levenshtein_distance('cat', 'cats')).to eq(1)
      end
    end

    context 'with long strings (performance tests)' do
      it 'calculates distance for long similar strings' do
        str1 = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. ' * 20
        str2 = 'Lorem ipsum dolor sit amet, consectetur adipisicing elit. ' * 20
        distance = described_class.levenshtein_distance(str1, str2)
        expect(distance).to be > 0
      end

      it 'calculates distance for very long strings' do
        str1 = 'a' * 1000 + 'b' * 1000
        str2 = 'a' * 1000 + 'c' * 1000
        distance = described_class.levenshtein_distance(str1, str2)
        expect(distance).to eq(1000)
      end
    end
  end

  describe '.cosine_similarity' do
    context 'with edge cases' do
      it 'returns 0.0 when one or both texts are empty' do
        expect(described_class.cosine_similarity('', 'hello')).to eq(0.0)
        expect(described_class.cosine_similarity('hello', '')).to eq(0.0)
        expect(described_class.cosine_similarity('', '')).to eq(0.0)
      end

      it 'returns 1.0 for identical texts' do
        text = 'the quick brown fox'
        expect(described_class.cosine_similarity(text, text)).to be_within(0.001).of(1.0)
      end
    end

    context 'with small texts (correctness tests)' do
      it 'returns high similarity for similar texts' do
        text1 = 'the quick brown fox jumps'
        text2 = 'the quick brown fox leaps'
        similarity = described_class.cosine_similarity(text1, text2)
        expect(similarity).to be > 0.7
      end

      it 'returns low similarity for different texts' do
        text1 = 'the quick brown fox'
        text2 = 'hello world goodbye'
        similarity = described_class.cosine_similarity(text1, text2)
        expect(similarity).to be < 0.3
      end

      it 'is case insensitive' do
        text1 = 'Hello World'
        text2 = 'hello world'
        expect(described_class.cosine_similarity(text1, text2)).to be_within(0.001).of(1.0)
      end
    end

    context 'with long texts (performance tests)' do
      let(:long_text1) do
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. #{
          'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
        }" * 100
      end

      let(:long_text2) do
        "Lorem ipsum dolor sit amet, consectetur adipisicing elit. #{
          'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
        }" * 100
      end

      let(:different_long_text) do
        "The quick brown fox jumps over the lazy dog. #{
          'Pack my box with five dozen liquor jugs. '
        }" * 100
      end

      it 'calculates similarity for long similar texts' do
        similarity = described_class.cosine_similarity(long_text1, long_text2)
        expect(similarity).to be > 0.9
      end

      it 'calculates similarity for long different texts' do
        similarity = described_class.cosine_similarity(long_text1, different_long_text)
        expect(similarity).to be < 0.5
      end
    end
  end

  describe '.find_similar_texts' do
    let(:target) { 'the quick brown fox' }
    let(:candidates) do
      [
        'the quick brown dog',
        'hello world',
        'the fast brown fox',
        'goodbye world',
        'quick brown fox'
      ]
    end

    context 'with edge cases' do
      it 'returns empty array when target is empty' do
        expect(described_class.find_similar_texts('', candidates)).to eq([])
      end

      it 'returns empty array when candidates is empty' do
        expect(described_class.find_similar_texts(target, [])).to eq([])
      end
    end

    context 'with small candidate sets (correctness tests)' do
      it 'returns candidates sorted by similarity' do
        results = described_class.find_similar_texts(target, candidates, limit: 3)
        expect(results.size).to eq(3)
        expect(results[0][:text]).to eq('quick brown fox')
        # First result should be most similar
        expect(results[0][:similarity]).to be >= results[1][:similarity]
        expect(results[1][:similarity]).to be >= results[2][:similarity]
      end

      it 'respects the limit parameter' do
        results = described_class.find_similar_texts(target, candidates, limit: 2)
        expect(results.size).to eq(2)
      end
    end

    context 'with large candidate sets (performance tests)' do
      let(:large_candidates) do
        Array.new(1000) do |i|
          "Lorem ipsum dolor sit amet #{i} consectetur adipiscing elit"
        end
      end

      it 'finds similar texts from large candidate set' do
        target_text = 'Lorem ipsum dolor sit amet 500 consectetur adipiscing elit'
        results = described_class.find_similar_texts(target_text, large_candidates, limit: 10)
        expect(results.size).to eq(10)
        expect(results.first[:text]).to include('500')
      end
    end
  end
end
