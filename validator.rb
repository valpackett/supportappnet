require_relative 'models.rb'

class ValidationException < Exception
end

class Validator
  def self.valid_page?(name)
    raise ValidationException, "Name can't be empty" if name.nil? || name == ''
    raise ValidationException, "Name can't be 'new'" if name == 'new'
    raise ValidationException, "Page #{name} already exists!" unless PageRepository.find_first_by_name(name).nil?
    true
  end

  def self.valid_post?(text)
    raise ValidationException, "Post can't be empty" if text.nil? || text == ''
    true
  end
end
