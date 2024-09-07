# frozen_string_literal: true

# Validate the word counts in a string-like field
module WordCountValidatable
  extend ActiveSupport::Concern

  included do
    def self.validates_word_count_of(attribute, min_words: 10, max_words: 50)
      validate do
        word_count = send(attribute).to_s.split.size
        if word_count < min_words || word_count > max_words
          errors.add(attribute,
                     "must be between #{min_words} and #{max_words} words")
        end
      end
    end
  end
end
