class Category < ApplicationRecord
  serialize :related_words, Hash

  def train(stat_block)
    stat_block_breakdown = TextWordCounterService.execute(stat_block_actions(stat_block))
    document_frequency(stat_block_breakdown)
  end

  def increment_document_count
    self.document_count += 1
    self.save
  end

  def calculate_tf_idf
    test_hash = {}
    words = self.related_words
    total_words = words.values.map { |v| v[:term_frequency] }.sum

    words.each do |key, value|
      next if key.length < 3
      if self.related_words.to_h.key?(key) == true
        tf = value[:term_frequency].to_f / total_words.to_f
        idf = Math.log(self.document_count.to_f / (self.related_words[key][:document_frequency].to_f + 1))
        test_hash.store(key, tf*idf)
      end
    end
    test_hash.to_h
  end

  #compares the two tf_idf scores closer to 1 means more similar 0 is less similar
  def calculate_similarity(stat_block)
    array1 = stat_block.calculate_tf_idf
    array2 = self.calculate_tf_idf
    dot_product = 0
    magnitude1 = 0
    magnitude2 = 0

    array1.each do |pair1|
      term1, value1 = pair1
      pair2 = array2.find { |pair| pair[0] == term1 }

      if pair2
        term2, value2 = pair2

        dot_product += (value1 * value2)
        magnitude1 += (value1**2)
        magnitude2 += (value2**2)
      end
    end

    cosine_similarity = dot_product / (Math.sqrt(magnitude1) * Math.sqrt(magnitude2))
  end

  private

  def document_frequency(breakdown)
    related_words_hash = self.related_words
    increment_document_count
    breakdown.each {|key, value|
      if related_words_hash.key?(key) == false
        related_words_hash.store(key, value)
        related_words_hash[key][:document_frequency] = 1
      else
        related_words_hash[key][:document_frequency] += 1
      end
    }
    self.related_words = related_words_hash
    self.save
  end

  def stat_block_actions(stat_block)
    actions = [
      stat_block.actions,
      stat_block&.abilities,
      stat_block&.legendary_actions,
      stat_block&.skills,
      stat_block&.saving_throws,
      stat_block&.senses,
      stat_block&.condition_immunities,
      stat_block&.damage_immunities,
      stat_block&.vulnerability,
      stat_block&.spells].map(&:to_s).join(' ').squeeze(' ')
    return (actions)
  end
end
