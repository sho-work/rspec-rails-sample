# frozen_string_literal: true

module CpuBenchmark
  # PrimeNumberService provides CPU-intensive prime number calculations
  # for benchmarking purposes.
  class PrimeNumberService
    # Check if a number is prime using trial division
    #
    # @param n [Integer] the number to check
    # @return [Boolean] true if n is prime, false otherwise
    def self.prime?(n)
      return false if n < 2
      return true if n == 2
      return false if n.even?

      limit = Math.sqrt(n).to_i
      (3..limit).step(2).each do |i|
        return false if (n % i).zero?
      end

      true
    end

    # Generate all prime numbers up to n using Sieve of Eratosthenes
    #
    # @param n [Integer] the upper limit
    # @return [Array<Integer>] array of prime numbers up to n
    def self.primes_up_to(n)
      return [] if n < 2

      sieve = Array.new(n + 1, true)
      sieve[0] = sieve[1] = false

      (2..Math.sqrt(n).to_i).each do |i|
        next unless sieve[i]

        (i * i..n).step(i).each do |j|
          sieve[j] = false
        end
      end

      sieve.each_with_index.select { |is_prime, _| is_prime }.map { |_, index| index }
    end

    # Find the nth prime number (1-indexed)
    #
    # @param n [Integer] the position of the prime to find (1 for first prime)
    # @return [Integer] the nth prime number
    # @raise [ArgumentError] if n is less than 1
    def self.nth_prime(n)
      raise ArgumentError, "n must be at least 1" if n < 1

      return 2 if n == 1

      count = 1
      candidate = 3

      while count < n
        count += 1 if prime?(candidate)
        candidate += 2
      end

      candidate - 2
    end
  end
end
