require_relative 'models.rb'

class ValidationException < Exception
end

class Validator
  def self.valid_page?(name, fullname)
    raise ValidationException, "URL can't be empty" if name.nil? || name == ''
    raise ValidationException, "URL can't be 'new'" if name == 'new'
    raise ValidationException, "URL can't be 'docs'" if name == 'docs'
    raise ValidationException, "Name can't be empty" if fullname.nil? || fullname == ''
    raise ValidationException, "Page #{name} already exists!" unless PageRepository.find_first_by_name(name).nil?
    true
  end

  def self.valid_post?(text, bare_text)
    raise ValidationException, "Post can't be empty" if bare_text.nil? || bare_text == ''
    raise ValidationException, "Post can't be over 256 characters" if text.length > 256
    true
  end
end
